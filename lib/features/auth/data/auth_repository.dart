import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_session_store.dart';
import '../../../core/storage/current_user_profile.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_user.dart';

/// Résultat de `POST /auth/check-email` — voir la note de sécurité
/// dans `checkEmailExists` ci-dessous sur pourquoi `isVerified` est
/// indispensable, pas un simple bonus d'information.
class EmailCheckResult {
  const EmailCheckResult({required this.exists, required this.isVerified});

  final bool exists;
  final bool isVerified;
}

/// Point de contact unique avec les endpoints `/auth/*`.
///
/// Chaque méthode traduit une erreur Dio en [AuthException] avec un
/// message public sûr — jamais de détail d'implémentation backend
/// (stack trace SQL, message Python) ne remonte jusqu'à l'UI.
@lazySingleton
class AuthRepository {
  AuthRepository(this._dio, this._sessionStore);

  final Dio _dio;
  final AuthSessionStore _sessionStore;

  Options get _public =>
      Options(extra: const {kRequiresAuthOptionKey: false});

  /// Confirme si un compte existe pour cet email.
  ///
  /// Voir `backend_addendum/check_email_router.py` — endpoint ajouté
  /// spécifiquement pour ce flux, absent de L22/L22B d'origine.
  /// Retourne l'existence ET le statut de vérification du compte —
  /// distinction critique pour éviter le contournement de
  /// vérification email (voir `check_email_router.py` V2).
  Future<EmailCheckResult> checkEmailExists(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/check-email',
        data: {'email': email},
        options: _public,
      );
      return EmailCheckResult(
        exists: response.data?['exists'] as bool? ?? false,
        isVerified: response.data?['is_verified'] as bool? ?? false,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Redemande l'envoi de l'email de confirmation — bouton "Je n'ai
  /// pas reçu l'email". Réponse toujours générique côté backend,
  /// jamais d'exception spécifique à distinguer côté UI (même
  /// principe anti-énumération que le login).
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/resend-verification',
        data: {'email': email},
        options: _public,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Connexion — email + mot de passe déjà connus.
  ///
  /// Le `refresh_token` est posé par le backend en cookie `HttpOnly`
  /// (géré silencieusement par le `PersistCookieJar`, voir
  /// `dio_client.dart`) — cette méthode ne le voit jamais et ne le
  /// manipule jamais directement, exactement comme prévu par L22B.
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: _public,
      );

      final accessToken = response.data?['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw AuthException.generic();
      }
      await _sessionStore.setAccessToken(accessToken);

      final user = await _fetchCurrentUser();
      _sessionStore.setCurrentUser(
        CurrentUserProfile(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
        ),
      );
      return user;
    } on DioException catch (error) {
      throw _mapError(error, contextLogin: true);
    }
  }

  /// Inscription — crée le compte (`email_verified = false` côté
  /// backend). Ne connecte PAS automatiquement l'utilisateur : le
  /// flux attend la confirmation email avant tout accès (voir
  /// `AuthFlowController`).
  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'full_name': fullName,
          'password': password,
        },
        options: _public,
      );
    } on DioException catch (error) {
      throw _mapError(error, contextRegister: true);
    }
  }

  Future<AuthUser> _fetchCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Récupère et met en cache le profil de l'utilisateur connecté.
  ///
  /// Utilisé au redémarrage de l'app : la session (access token) est
  /// restaurée depuis le Keystore avant le premier frame, mais le
  /// profil (nom, email) doit encore être rechargé une fois — voir
  /// `HomeController`.
  Future<CurrentUserProfile?> getCurrentUser() async {
    if (_sessionStore.currentUser.value != null) {
      return _sessionStore.currentUser.value;
    }
    try {
      final user = await _fetchCurrentUser();
      final profile = CurrentUserProfile(
        id: user.id,
        email: user.email,
        fullName: user.fullName,
      );
      _sessionStore.setCurrentUser(profile);
      return profile;
    } on AuthException {
      return null;
    }
  }

  Future<void> logout() async {
    await _sessionStore.clear();
  }

  AuthException _mapError(
    DioException error, {
    bool contextLogin = false,
    bool contextRegister = false,
  }) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return AuthException.network();
    }

    final status = error.response?.statusCode;
    final detail = error.response?.data is Map
        ? (error.response?.data as Map)['detail'] as String?
        : null;

    if (status == 401 && contextLogin) {
      return const AuthException('Email ou mot de passe incorrect.');
    }
    if (status == 409 && contextRegister) {
      return const AuthException('Un compte existe déjà avec cet email.');
    }
    if (status == 429) {
      return const AuthException(
        'Trop de tentatives. Réessayez dans quelques minutes.',
      );
    }
    if (detail != null && detail.isNotEmpty) {
      return AuthException(detail, error.message);
    }

    return AuthException.generic();
  }
}
