import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:panganku_mobile/core/network/dio_client.dart';
import 'package:panganku_mobile/core/repositories/kecamatan_repository.dart';
import 'package:panganku_mobile/core/repositories/master_data_repository.dart';
import 'package:panganku_mobile/core/theme/app_theme.dart';
import 'package:panganku_mobile/features/admin/data/admin_repository.dart';
import 'package:panganku_mobile/features/admin/pages/harga_admin_page.dart';
import 'package:panganku_mobile/features/admin/pages/kecamatan_admin_page.dart';
import 'package:panganku_mobile/features/admin/pages/komoditas_admin_page.dart';
import 'package:panganku_mobile/features/admin/pages/stok_admin_page.dart';
import 'package:panganku_mobile/features/admin/pages/users_admin_page.dart';
import 'package:panganku_mobile/features/analytics/bloc/analytics_bloc.dart';
import 'package:panganku_mobile/features/analytics/bloc/analytics_event.dart';
import 'package:panganku_mobile/features/analytics/data/analytics_repository.dart';
import 'package:panganku_mobile/features/analytics/pages/analytics_page.dart';
import 'package:panganku_mobile/features/auth/bloc/auth_bloc.dart';
import 'package:panganku_mobile/features/auth/bloc/auth_event.dart';
import 'package:panganku_mobile/features/auth/bloc/auth_state.dart';
import 'package:panganku_mobile/features/auth/data/auth_repository.dart';
import 'package:panganku_mobile/features/auth/pages/login_page.dart';
import 'package:panganku_mobile/features/auth/pages/register_page.dart';
import 'package:panganku_mobile/features/dashboard/pages/dashboard_page.dart';
import 'package:panganku_mobile/features/distribusi/bloc/distribusi_bloc.dart';
import 'package:panganku_mobile/features/distribusi/bloc/distribusi_event.dart';
import 'package:panganku_mobile/features/distribusi/data/distribusi_repository.dart';
import 'package:panganku_mobile/features/distribusi/pages/distribusi_page.dart';
import 'package:panganku_mobile/features/harga/bloc/harga_bloc.dart';
import 'package:panganku_mobile/features/harga/data/harga_repository.dart';
import 'package:panganku_mobile/features/harga/pages/forecast_page.dart';
import 'package:panganku_mobile/features/harga/pages/harga_page.dart';
import 'package:panganku_mobile/features/laporan/bloc/laporan_bloc.dart';
import 'package:panganku_mobile/features/laporan/data/laporan_repository.dart';
import 'package:panganku_mobile/features/laporan/pages/laporan_page.dart';
import 'package:panganku_mobile/features/notifikasi/bloc/notifikasi_bloc.dart';
import 'package:panganku_mobile/features/notifikasi/bloc/notifikasi_event.dart';
import 'package:panganku_mobile/features/notifikasi/data/notifikasi_repository.dart';
import 'package:panganku_mobile/features/notifikasi/pages/notifikasi_page.dart';
import 'package:panganku_mobile/features/peta/pages/peta_sebaran_page.dart';
import 'package:panganku_mobile/features/profile/bloc/profile_bloc.dart';
import 'package:panganku_mobile/features/profile/bloc/profile_event.dart';
import 'package:panganku_mobile/features/profile/data/profile_repository.dart';
import 'package:panganku_mobile/features/profile/pages/profile_page.dart';
import 'package:panganku_mobile/features/splash/pages/splash_page.dart';
import 'package:panganku_mobile/features/stok/bloc/stok_bloc.dart';
import 'package:panganku_mobile/features/stok/bloc/stok_event.dart';
import 'package:panganku_mobile/features/stok/data/stok_repository.dart';
import 'package:panganku_mobile/features/stok/pages/stok_pangan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DioClient>.value(value: dioClient),
        RepositoryProvider(create: (_) => AuthRepository(dioClient)),
        RepositoryProvider(create: (_) => AnalyticsRepository(dioClient)),
        RepositoryProvider(create: (_) => NotifikasiRepository(dioClient)),
        RepositoryProvider(create: (_) => HargaRepository(dioClient)),
        RepositoryProvider(create: (_) => StokRepository(dioClient)),
        RepositoryProvider(create: (_) => DistribusiRepository(dioClient)),
        RepositoryProvider(create: (_) => LaporanRepository(dioClient)),
        RepositoryProvider(create: (_) => ProfileRepository(dioClient)),
        RepositoryProvider(create: (_) => MasterDataRepository(dioClient)),
        RepositoryProvider(create: (_) => KecamatanRepository(dioClient)),
        RepositoryProvider(create: (_) => AdminRepository(dioClient)),
      ],
      child: BlocProvider(
        create: (context) =>
            AuthBloc(context.read<AuthRepository>())..add(AuthSessionChecked()),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              _router.go('/login');
            }
          },
          child: MaterialApp.router(
            title: 'PanganKu',
            theme: AppTheme.light,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/notifikasi',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            NotifikasiBloc(context.read<NotifikasiRepository>())
              ..add(LoadNotifikasiList()),
        child: const NotifikasiPage(),
      ),
    ),
    GoRoute(
      path: '/peta',
      builder: (context, state) => const PetaSebaranPage(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            AnalyticsBloc(context.read<AnalyticsRepository>())
              ..add(LoadDashboardStats()),
        child: const AnalyticsPage(),
      ),
    ),
    GoRoute(
      path: '/harga/forecast',
      builder: (context, state) => const ForecastPage(),
    ),
    GoRoute(
      path: '/harga',
      builder: (context, state) => BlocProvider(
        create: (context) => HargaBloc(context.read<HargaRepository>()),
        child: const HargaPage(),
      ),
    ),
    GoRoute(
      path: '/stok',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            StokBloc(context.read<StokRepository>())..add(LoadStokList()),
        child: const StokPanganPage(),
      ),
    ),
    GoRoute(
      path: '/distribusi',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            DistribusiBloc(context.read<DistribusiRepository>())
              ..add(LoadDistribusiList()),
        child: const DistribusiPage(),
      ),
    ),
    GoRoute(
      path: '/laporan',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => LaporanBloc(context.read<LaporanRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                AnalyticsBloc(context.read<AnalyticsRepository>())
                  ..add(LoadDashboardStats()),
          ),
        ],
        child: const LaporanPage(),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => BlocProvider(
        create: (context) =>
            ProfileBloc(context.read<ProfileRepository>())..add(LoadProfile()),
        child: const ProfilePage(),
      ),
    ),
    GoRoute(
      path: '/admin/komoditas',
      builder: (context, state) => const KomoditasAdminPage(),
    ),
    GoRoute(
      path: '/admin/kecamatan',
      builder: (context, state) => const KecamatanAdminPage(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const UsersAdminPage(),
    ),
    GoRoute(
      path: '/admin/stok',
      builder: (context, state) => const StokAdminPage(),
    ),
    GoRoute(
      path: '/admin/harga',
      builder: (context, state) => const HargaAdminPage(),
    ),
  ],
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;
    final isAdmin = authState is AuthAuthenticated && authState.role == 'admin';
    final isAdminRoute = state.matchedLocation.startsWith('/admin/');
    final isLoggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/splash';

    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    if (isLoggedIn && isLoggingIn) {
      return '/dashboard';
    }
    if (isAdminRoute && !isAdmin) {
      return '/dashboard';
    }
    return null;
  },
);
