import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/auth_session_store.dart';
import 'api_config.dart';

/// Clé d'option Dio utilisée pour marquer les requêtes qui ne
/// nécessitent PAS d'access token (check-email, register, login,
/// forgot-password, refresh lui-même) — évite d'attacher un header
/// `Authorization` vide ou périmé sur ces appels publics.
const String kRequiresAuthOptionKey = 'requiresAuth';

/// Fabrique et configure l'instance `Dio` unique de l'application.
///
/// Le `PersistCookieJar` reproduit fidèlement le comportement d'un
/// navigateur pour le cookie `refresh_token` posé par le backend
/// (L22B, `HttpOnly` + `Secure` + `SameSite=Strict` + `path=/auth/refresh`) :
/// stocké sur disque dans le stockage sandboxé de l'app (donc déjà
/// inaccessible aux autres apps, comme le garantit l'OS), envoyé
/// automatiquement par Dio uniquement vers `/auth/refresh` grâce au
/// respect de l'attribut `Path` du cookie — jamais manipulé par du
/// code Dart applicatif, exactement comme `HttpOnly` l'empêcherait
/// pour du JavaScript dans un navigateur.
@module
abstract class DioModule {
  @preResolve
  Future<Dio> dio(AuthSessionStore sessionStore) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    final appDir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(
      storage: FileStorage('${appDir.path}/.cookies/'),
    );

    dio.interceptors.add(CookieManager(cookieJar));
    dio.interceptors.add(_AuthInterceptor(dio, sessionStore));

    return dio;
  }
}

/// Attache le Bearer token sur les requêtes authentifiées et gère
/// le renouvellement automatique via `/auth/refresh` sur un 401.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio, this._sessionStore);

  final Dio _dio;
  final AuthSessionStore _sessionStore;

  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final bool requiresAuth =
        options.extra[kRequiresAuthOptionKey] as bool? ?? true;

    if (requiresAuth && _sessionStore.accessToken != null) {
      options.headers['Authorization'] =
          'Bearer ${_sessionStore.accessToken}';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final bool requiresAuth =
        err.requestOptions.extra[kRequiresAuthOptionKey] as bool? ?? true;

    final bool isUnauthorized = err.response?.statusCode == 401;
    final bool alreadyRetried =
        err.requestOptions.extra['retried'] as bool? ?? false;

    if (!isUnauthorized || !requiresAuth || alreadyRetried) {
      handler.next(err);
      return;
    }

    // Empêche plusieurs requêtes en échec simultané de déclencher
    // chacune leur propre tentative de refresh en parallèle.
    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(extra: {kRequiresAuthOptionKey: false}),
      );

      final newAccessToken =
          refreshResponse.data?['access_token'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _sessionStore.clear();
        handler.next(err);
        return;
      }

      await _sessionStore.setAccessToken(newAccessToken);

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra['retried'] = true;

      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      // Refresh lui-même a échoué (cookie absent ou expiré) —
      // session définitivement terminée, l'utilisateur doit se
      // reconnecter manuellement.
      await _sessionStore.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
