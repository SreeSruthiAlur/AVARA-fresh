import 'package:avara_astrology_trial/services/avara_api_client.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

/// Lightweight representation of the authenticated user returned after a
/// successful login or registration.
///
/// Extend this as more profile fields are required (e.g. `preferredLanguage`,
/// `birthDate`).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.token,
  });

  final int id;
  final String email;
  final String username;
  final String fullName;

  /// The raw JWT; stored securely by [AuthService] — callers rarely need this
  /// directly. Prefer [AvaraApiClient.instance.isAuthenticated] to check state.
  final String token;

  factory AuthUser.fromJson(Map<String, dynamic> json, String token) {
    // The backend TokenResponse is a FLAT object:
    // { access_token, token_type, expires_in_seconds,
    //   user_id, email, username, preferred_language }
    // There is no nested "user" key.
    // We also accept a legacy shape with an "id" key for forward-compatibility.
    return AuthUser(
      id: (json['user_id'] ?? json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      token: token,
    );
  }
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Handles user authentication against the AVARA FastAPI backend.
///
/// Uses [AvaraApiClient.instance] for all network calls so the JWT is
/// automatically persisted and attached to subsequent requests.
///
/// ### Typical flow
/// ```dart
/// // On app start, restore session
/// final user = await AuthService.instance.restoreSession();
///
/// // Sign in
/// final user = await AuthService.instance.login(email, password);
///
/// // Sign up
/// final user = await AuthService.instance.register(
///   name: 'Sruthi', email: 'sruthi@example.com', password: 'secret',
/// );
///
/// // Sign out
/// await AuthService.instance.logout();
/// ```
class AuthService {
  AuthService._();

  /// The single shared instance.
  static final AuthService instance = AuthService._();

  final AvaraApiClient _client = AvaraApiClient.instance;

  // ---- public API ----------------------------------------------------------

  /// Signs in with [email] (or username) and [password].
  ///
  /// On success, persists the JWT via [AvaraApiClient] and returns an
  /// [AuthUser]. Throws [AvaraApiException] on auth failure (e.g. 401).
  ///
  /// The backend expects `application/x-www-form-urlencoded` for the OAuth2
  /// token endpoint. If your backend uses a JSON body instead, swap the
  /// implementation to use `_client.post('/auth/login', body: {...})`.
  Future<AuthUser> login(String email, String password) async {
    // Vinya's backend auth endpoint (see README_TEAMMATE2.md §4)
    // POST /api/v1/auth/login  →  { access_token, token_type, user: {...} }
    final data = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final token = _extractToken(data);
    await _client.persistToken(token);
    // TokenResponse is flat — pass data directly (no nested 'user' key).
    return AuthUser.fromJson(data as Map<String, dynamic>, token);
  }

  /// Creates a new account with [name], [email], and [password].
  ///
  /// On success, persists the JWT and returns an [AuthUser].
  /// Throws [AvaraApiException] on validation failure (e.g. 400, 422).
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
    required String username,
  }) async {
    // POST /api/v1/auth/register  →  { access_token, token_type, user: {...} }
    final data = await _client.post('/auth/register', body: {
      'full_name': name,
      'email': email,
      'password': password,
      'username': username,
    });

    final token = _extractToken(data);
    await _client.persistToken(token);
    // TokenResponse is flat — pass data directly (no nested 'user' key).
    return AuthUser.fromJson(data as Map<String, dynamic>, token);
  }

  /// Signs the user out by clearing the stored JWT.
  ///
  /// Also fires `POST /auth/logout` to give the backend a chance to
  /// invalidate server-side state. The call is best-effort — a network
  /// failure does not prevent the local token from being cleared.
  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } on AvaraApiException {
      // Swallow — local token is cleared regardless.
    } catch (_) {
      // Swallow network errors too.
    }
    await _client.clearToken();
  }

  /// Attempts to restore a previously authenticated session.
  ///
  /// Returns the stored [AuthUser] profile fetched from `GET /profile/me`,
  /// or `null` if no token exists or the token has expired.
  Future<AuthUser?> restoreSession() async {
    if (!await _client.isAuthenticated) return null;
    try {
      final data = await _client.get('/profile/me') as Map<String, dynamic>;
      final token = (await _client.readToken())!;
      return AuthUser.fromJson(data, token);
    } on AvaraApiException catch (e) {
      // 401 means the stored token has expired — clear it silently.
      if (e.statusCode == 401) {
        await _client.clearToken();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns `true` when a valid JWT is currently stored in secure storage.
  Future<bool> get isLoggedIn => _client.isAuthenticated;

  // ---- helpers -------------------------------------------------------------

  /// Extracts the `access_token` string from a decoded response body.
  ///
  /// Vinya's backend returns `{ "access_token": "...", "token_type": "bearer",
  /// "user": { ... } }`. Throws [AvaraApiException] if the token field is
  /// absent so the caller gets a clear error rather than a null-reference.
  String _extractToken(dynamic data) {
    if (data is Map) {
      final token = data['access_token']?.toString();
      if (token != null && token.isNotEmpty) return token;
    }
    throw const AvaraApiException(
      statusCode: 200,
      message: 'Server response did not include an access_token.',
    );
  }
}
