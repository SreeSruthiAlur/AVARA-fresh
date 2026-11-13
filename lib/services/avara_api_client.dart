import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avara_astrology_trial/main.dart' show rootScaffoldMessengerKey;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [AvaraApiClient] whenever the backend returns a non-2xx status.
///
/// [statusCode] is the raw HTTP status code.
/// [message]    is the `detail` field from the backend JSON, or the raw body
///              if the response could not be decoded.
class AvaraApiException implements Exception {
  const AvaraApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'AvaraApiException($statusCode): $message';
}

// ---------------------------------------------------------------------------
// Storage key
// ---------------------------------------------------------------------------

/// Secure-storage key under which the JWT is persisted.
const _kTokenKey = 'avara_jwt_token';

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

/// Singleton HTTP client for all calls to the AVARA FastAPI backend.
///
/// ### Usage
/// ```dart
/// // Read-only access — never call the private constructor directly.
/// final client = AvaraApiClient.instance;
///
/// // Authenticated GET
/// final data = await client.get('/profile/me');
///
/// // Store a token after login
/// await client.persistToken('eyJ...');
/// ```
///
/// ### Configuration
/// The base URL is read from the `.env` asset key `AVARA_API_BASE_URL`.
/// It defaults to `http://localhost:8000/api/v1` when the key is absent.
///
/// ### Auth
/// Every request that finds a stored JWT token automatically receives the
/// `Authorization: Bearer <token>` header. Requests without a token are sent
/// unauthenticated (which is correct for `/auth/login` and `/auth/register`).
class AvaraApiClient {
  AvaraApiClient._();

  /// The single shared instance.
  static final AvaraApiClient instance = AvaraApiClient._();

  /// Maximum duration to wait for cloud server responses (prevents cold-start hanging).
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Safe, user-friendly network failure message.
  static const String kNetworkErrorMessage =
      'Unable to connect to AVARA servers. Please check your internet connection and try again.';

  /// Optional listener invoked whenever a network connectivity failure occurs.
  static void Function(String message)? onNetworkError;

  /// Triggers a non-intrusive floating SnackBar on the root ScaffoldMessenger
  /// without requiring an active BuildContext.
  static void notifyNetworkError([String? customMessage]) {
    final msg = customMessage ?? kNetworkErrorMessage;
    onNetworkError?.call(msg);
    try {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {}
  }

  // ---- internals -----------------------------------------------------------

  final _storage = const FlutterSecureStorage(
    // Use the most compatible options across Android / iOS / Web / Windows.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Base URL resolved dynamically from environment configuration.
  /// Set `AVARA_API_BASE_URL` in `.env` to the secure production HTTPS endpoint
  /// (e.g. `https://api.avara.app/api/v1`) when distributing release APKs.
  String get _baseUrl {
    String url = 'http://127.0.0.1:8000/api/v1';
    try {
      if (dotenv.isInitialized) {
        url = dotenv.get('AVARA_API_BASE_URL', fallback: url);
      }
    } catch (_) {}
    return url;
  }

  // ---- token management ----------------------------------------------------

  /// Persists [token] in secure storage so it survives app restarts.
  Future<void> persistToken(String token) async {
    try {
      await _storage.write(key: _kTokenKey, value: token);
    } catch (_) {}
  }

  /// Removes the stored JWT (call on logout).
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _kTokenKey);
    } catch (_) {}
  }

  /// Returns the stored JWT, or `null` if the user is not signed in.
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _kTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` when a JWT token is currently stored.
  Future<bool> get isAuthenticated async =>
      (await readToken()) != null;

  // ---- header helpers ------------------------------------------------------

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---- response handling ---------------------------------------------------

  /// Decodes the response and throws [AvaraApiException] on non-2xx.
  ///
  /// Returns the decoded JSON body as `dynamic` (typically a `Map` or `List`).
  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Attempt to extract the FastAPI `detail` field; fall back to raw body.
    String message;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        final detail = body['detail'];
        // FastAPI can return detail as a string or a list of validation errors.
        message = detail is List
            ? detail.map((e) => e['msg'] ?? e.toString()).join('; ')
            : detail.toString();
      } else {
        message = response.body;
      }
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : 'Unknown error';
    }

    throw AvaraApiException(statusCode: response.statusCode, message: message);
  }

  // ---- Safe execution & Network Error handling -----------------------------

  /// Wraps HTTP requests in a 10s timeout and catches all network/server failures
  /// (SocketException, TimeoutException, ClientException, HandshakeException, etc.).
  /// Triggers a safe UI notification (SnackBar) and throws [AvaraApiException] with
  /// a graceful error message instead of crashing the UI with raw unhandled exceptions.
  Future<dynamic> _safeExecute(
    String method,
    String path,
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(requestTimeout);
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [$method $path]: SocketException (server unreachable / offline) — ${e.message}');
      notifyNetworkError();
      throw const AvaraApiException(
        statusCode: 0,
        message: kNetworkErrorMessage,
      );
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [$method $path]: TimeoutException (exceeded ${requestTimeout.inSeconds}s) — $e');
      notifyNetworkError();
      throw const AvaraApiException(
        statusCode: 408,
        message: kNetworkErrorMessage,
      );
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [$method $path]: ClientException — $e');
      notifyNetworkError();
      throw const AvaraApiException(
        statusCode: 0,
        message: kNetworkErrorMessage,
      );
    } on HandshakeException catch (e) {
      print('NETWORK ERROR [$method $path]: HandshakeException (TLS/SSL error) — $e');
      notifyNetworkError();
      throw const AvaraApiException(
        statusCode: 0,
        message: kNetworkErrorMessage,
      );
    } on AvaraApiException {
      rethrow;
    } catch (e) {
      print('UNEXPECTED NETWORK ERROR [$method $path]: $e');
      notifyNetworkError();
      throw const AvaraApiException(
        statusCode: 0,
        message: kNetworkErrorMessage,
      );
    }
  }

  // ---- HTTP verbs ----------------------------------------------------------

  /// `GET /[path]` with 10s timeout and bulletproof network error handling.
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParams?.isNotEmpty == true ? queryParams : null);
    final headers = await _headers();
    return _safeExecute('GET', path, () => http.get(uri, headers: headers));
  }

  /// `POST /[path]` with an optional JSON [body], 10s timeout, and bulletproof error handling.
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final encodedBody = body != null ? jsonEncode(body) : null;
    return _safeExecute(
      'POST',
      path,
      () => http.post(uri, headers: headers, body: encodedBody),
    );
  }

  /// `PUT /[path]` with an optional JSON [body], 10s timeout, and bulletproof error handling.
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final encodedBody = body != null ? jsonEncode(body) : null;
    return _safeExecute(
      'PUT',
      path,
      () => http.put(uri, headers: headers, body: encodedBody),
    );
  }

  /// `PATCH /[path]` with an optional JSON [body], 10s timeout, and bulletproof error handling.
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    final encodedBody = body != null ? jsonEncode(body) : null;
    return _safeExecute(
      'PATCH',
      path,
      () => http.patch(uri, headers: headers, body: encodedBody),
    );
  }

  /// `DELETE /[path]` with 10s timeout and bulletproof network error handling.
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    return _safeExecute('DELETE', path, () => http.delete(uri, headers: headers));
  }
}
