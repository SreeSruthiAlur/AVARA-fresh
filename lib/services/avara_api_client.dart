import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  // ---- internals -----------------------------------------------------------

  final _storage = const FlutterSecureStorage(
    // Use the most compatible options across Android / iOS / Web / Windows.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String get _baseUrl =>
      dotenv.get('AVARA_API_BASE_URL', fallback: 'http://127.0.0.1:8000/api/v1');

  // ---- token management ----------------------------------------------------

  /// Persists [token] in secure storage so it survives app restarts.
  Future<void> persistToken(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  /// Removes the stored JWT (call on logout).
  Future<void> clearToken() => _storage.delete(key: _kTokenKey);

  /// Returns the stored JWT, or `null` if the user is not signed in.
  Future<String?> readToken() => _storage.read(key: _kTokenKey);

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

  // ---- HTTP verbs ----------------------------------------------------------

  /// `GET /[path]`
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path')
        .replace(queryParameters: queryParams?.isNotEmpty == true ? queryParams : null);
    try {
      final response = await http.get(uri, headers: await _headers());
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [GET $path]: SocketException — ${e.message} (address: ${e.address}, port: ${e.port})');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [GET $path]: TimeoutException — $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [GET $path]: ClientException — $e');
      rethrow;
    }
  }

  /// `POST /[path]` with an optional JSON [body].
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [POST $path]: SocketException — ${e.message} (address: ${e.address}, port: ${e.port})');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [POST $path]: TimeoutException — $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [POST $path]: ClientException — $e');
      rethrow;
    }
  }

  /// `PUT /[path]` with an optional JSON [body].
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.put(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [PUT $path]: SocketException — ${e.message} (address: ${e.address}, port: ${e.port})');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [PUT $path]: TimeoutException — $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [PUT $path]: ClientException — $e');
      rethrow;
    }
  }

  /// `PATCH /[path]` with an optional JSON [body].
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.patch(
        uri,
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [PATCH $path]: SocketException — ${e.message} (address: ${e.address}, port: ${e.port})');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [PATCH $path]: TimeoutException — $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [PATCH $path]: ClientException — $e');
      rethrow;
    }
  }

  /// `DELETE /[path]`.
  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.delete(uri, headers: await _headers());
      return _handle(response);
    } on SocketException catch (e) {
      print('NETWORK ERROR [DELETE $path]: SocketException — ${e.message} (address: ${e.address}, port: ${e.port})');
      rethrow;
    } on TimeoutException catch (e) {
      print('NETWORK ERROR [DELETE $path]: TimeoutException — $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('NETWORK ERROR [DELETE $path]: ClientException — $e');
      rethrow;
    }
  }
}
