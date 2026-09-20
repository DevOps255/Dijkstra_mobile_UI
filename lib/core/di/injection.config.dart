// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/auth_repository.dart' as _i726;
import '../../features/auth/data/mail_app_launcher.dart' as _i922;
import '../../features/auth/data/verification_deep_link_service.dart' as _i356;
import '../../features/home/data/notifications_repository.dart' as _i701;
import '../../features/home/data/trips_repository.dart' as _i322;
import '../../features/home/data/wallet_repository.dart' as _i8;
import '../../features/wallet/data/wallet_repository.dart' as _i308;
import '../audio/sound_service.dart' as _i369;
import '../mobile_money/mobile_money_permission_service.dart' as _i395;
import '../mobile_money/sim_selector_service.dart' as _i187;
import '../mobile_money/sms_interceptor_service.dart' as _i188;
import '../mobile_money/ussd_dialer_service.dart' as _i210;
import '../network/dio_client.dart' as _i667;
import '../storage/auth_session_store.dart' as _i861;
import '../storage/local_preferences_service.dart' as _i441;
import '../storage/secure_storage_service.dart' as _i666;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final preferencesModule = _$PreferencesModule();
    final dioModule = _$DioModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => preferencesModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i369.SoundService>(() => _i369.SoundService());
    gh.lazySingleton<_i395.MobileMoneyPermissionService>(
        () => _i395.MobileMoneyPermissionService());
    gh.lazySingleton<_i187.SimSelectorService>(
        () => _i187.SimSelectorService());
    gh.lazySingleton<_i188.SmsInterceptorService>(
        () => _i188.SmsInterceptorService());
    gh.lazySingleton<_i210.UssdDialerService>(() => _i210.UssdDialerService());
    gh.lazySingleton<_i666.SecureStorageService>(
        () => _i666.SecureStorageService());
    gh.lazySingleton<_i922.MailAppLauncher>(() => _i922.MailAppLauncher());
    gh.lazySingleton<_i356.VerificationDeepLinkService>(
        () => _i356.VerificationDeepLinkService());
    gh.lazySingleton<_i861.AuthSessionStore>(
        () => _i861.AuthSessionStore(gh<_i666.SecureStorageService>()));
    gh.lazySingleton<_i441.LocalPreferencesService>(
        () => _i441.LocalPreferencesService(gh<_i460.SharedPreferences>()));
    await gh.factoryAsync<_i361.Dio>(
      () => dioModule.dio(gh<_i861.AuthSessionStore>()),
      preResolve: true,
    );
    gh.lazySingleton<_i726.AuthRepository>(() => _i726.AuthRepository(
          gh<_i361.Dio>(),
          gh<_i861.AuthSessionStore>(),
        ));
    gh.lazySingleton<_i701.NotificationsRepository>(
        () => _i701.NotificationsRepository(gh<_i361.Dio>()));
    gh.lazySingleton<_i322.TripsRepository>(
        () => _i322.TripsRepository(gh<_i361.Dio>()));
    gh.lazySingleton<_i8.WalletRepository>(
        () => _i8.WalletRepository(gh<_i361.Dio>()));
    gh.lazySingleton<_i308.WalletRepository>(
        () => _i308.WalletRepository(gh<_i361.Dio>()));
    return this;
  }
}

class _$PreferencesModule extends _i441.PreferencesModule {}

class _$DioModule extends _i667.DioModule {}
