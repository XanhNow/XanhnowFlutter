import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/config/app_config.dart';
import '../core/device/device_context_service.dart';
import '../core/network/api_client.dart';
import '../core/session/auth_session_cubit.dart';
import '../core/storage/auth_identity_store.dart';
import '../core/storage/secure_token_store.dart';
import '../features/admin/data/admin_recovery_api.dart';
import '../features/admin/domain/admin_recovery_repository.dart';
import '../features/auth/data/passkey_ceremony_service.dart';
import '../features/auth/data/security_auth_api.dart';
import '../features/auth/data/smart_otp_device_crypto_service.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/bloc/login_bloc.dart';
import '../features/auth/presentation/bloc/registration_bloc.dart';
import '../features/auth/presentation/pages/auth_shell_page.dart';
import '../features/profile/data/customer_profile_api.dart';
import '../features/profile/data/object_storage_api.dart';
import '../features/profile/domain/profile_repository.dart';
import 'home_page.dart';

class XanhNowFlutterApp extends StatelessWidget {
  const XanhNowFlutterApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: config),
        RepositoryProvider(create: (_) => const SecureTokenStore()),
        RepositoryProvider(create: (_) => const AuthIdentityStore()),
        RepositoryProvider(create: (_) => DeviceContextService()),
        RepositoryProvider(
          create: (context) => ApiClient(
            baseUrl: config.securityBaseUrl,
            tokenStore: context.read<SecureTokenStore>(),
          ),
        ),
        RepositoryProvider(create: (_) => PasskeyCeremonyService()),
        RepositoryProvider(create: (_) => SmartOtpDeviceCryptoService()),
        RepositoryProvider(
          create: (context) => SecurityAuthApi(context.read<ApiClient>()),
        ),
        RepositoryProvider(
          create: (context) => CustomerProfileApi(
            ApiClient(
              baseUrl: config.customerBaseUrl,
              tokenStore: context.read<SecureTokenStore>(),
            ),
          ),
        ),
        RepositoryProvider(
          create: (context) => ObjectStorageApi(
            ApiClient(
              baseUrl: config.objectStorageBaseUrl,
              tokenStore: context.read<SecureTokenStore>(),
            ),
          ),
        ),
        RepositoryProvider(
          create: (context) => AdminRecoveryApi(
            ApiClient(
              baseUrl: config.adminBaseUrl,
              tokenStore: context.read<SecureTokenStore>(),
            ),
          ),
        ),
        RepositoryProvider(
          create: (context) => ProfileRepository(
            api: context.read<CustomerProfileApi>(),
            objectStorageApi: context.read<ObjectStorageApi>(),
          ),
        ),
        RepositoryProvider(
          create: (context) =>
              AdminRecoveryRepository(api: context.read<AdminRecoveryApi>()),
        ),
        RepositoryProvider(
          create: (context) => AuthRepository(
            api: context.read<SecurityAuthApi>(),
            passkeys: context.read<PasskeyCeremonyService>(),
            smartOtpCrypto: context.read<SmartOtpDeviceCryptoService>(),
            deviceContext: context.read<DeviceContextService>(),
            tokenStore: context.read<SecureTokenStore>(),
            identityStore: context.read<AuthIdentityStore>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthSessionCubit(
              tokenStore: context.read<SecureTokenStore>(),
              identityStore: context.read<AuthIdentityStore>(),
            )..restore(),
          ),
          BlocProvider(
            create: (context) => RegistrationBloc(
              repository: context.read<AuthRepository>(),
              sessionCubit: context.read<AuthSessionCubit>(),
            ),
          ),
          BlocProvider(
            create: (context) => LoginBloc(
              repository: context.read<AuthRepository>(),
              sessionCubit: context.read<AuthSessionCubit>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'XanhNow Flutter',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home: BlocBuilder<AuthSessionCubit, AuthSessionState>(
            builder: (context, state) {
              return switch (state.status) {
                AuthSessionStatus.authenticated => const HomePage(),
                AuthSessionStatus.unknown => const _AppLoadingPage(),
                _ => AuthShellPage(initialIndex: state.preferLogin ? 1 : 0),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _AppLoadingPage extends StatelessWidget {
  const _AppLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
