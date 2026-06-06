// Doc:
// Tujuan: Menjadi shell halaman dashboard dan mengorkestrasi halaman tab beranda, harga, stok, distribusi, laporan, dan profil.
// Dipakai oleh: Router utama aplikasi untuk entry page setelah login.
// Dependensi utama: Bloc auth/harga/laporan/analytics/profile/stok/distribusi/notifikasi, AppConstants, repository fitur terkait, part dashboard widgets.
// Fungsi public/utama: DashboardPage, _DashboardPageState lifecycle/build, _buildBottomNav, _getCurrentPage.
// Side effect penting: Dispatch load notifikasi, membuat bloc provider halaman turunan, dan navigasi bottom tab/router.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../harga/bloc/harga_bloc.dart';
import '../../harga/data/harga_repository.dart';
import '../../harga/pages/harga_page.dart';
import '../../laporan/bloc/laporan_bloc.dart';
import '../../laporan/data/laporan_repository.dart';
import '../../laporan/pages/laporan_page.dart';
import '../../analytics/bloc/analytics_bloc.dart';
import '../../analytics/bloc/analytics_event.dart';
import '../../analytics/bloc/analytics_state.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_event.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/pages/profile_page.dart';
import '../../stok/bloc/stok_bloc.dart';
import '../../stok/bloc/stok_event.dart';
import '../../stok/data/stok_repository.dart';
import '../../stok/pages/stok_pangan_page.dart';
import '../../distribusi/bloc/distribusi_bloc.dart';
import '../../distribusi/bloc/distribusi_event.dart';
import '../../distribusi/data/distribusi_repository.dart';
import '../../distribusi/pages/distribusi_page.dart';
import '../../notifikasi/bloc/notifikasi_bloc.dart';
import '../../notifikasi/bloc/notifikasi_event.dart';
import '../../notifikasi/bloc/notifikasi_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/live_refresh.dart';
import '../../../core/widgets/last_updated_badge.dart';

part '../widgets/dashboard_home_section.dart';
part '../widgets/dashboard_chart_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  DateTime? _homeLastUpdatedAt;

  String _currentRole() {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.role : 'petani';
  }

  bool _isPrivilegedRole(String role) {
    return role == 'admin' || role == 'petugas';
  }

  @override
  void initState() {
    super.initState();
    context.read<NotifikasiBloc>().add(LoadNotifikasiList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _getCurrentPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isPrivileged = _isPrivilegedRole(_currentRole());
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Beranda',
        'index': 0,
      },
      {
        'icon': Icons.trending_up_outlined,
        'activeIcon': Icons.trending_up,
        'label': 'Harga',
        'index': 1,
      },
      if (isPrivileged) ...[
        {
          'icon': Icons.inventory_2_outlined,
          'activeIcon': Icons.inventory_2,
          'label': 'Stok',
          'index': 2,
        },
      ],
      {
        'icon': Icons.local_shipping_outlined,
        'activeIcon': Icons.local_shipping,
        'label': 'Distribusi',
        'index': 3,
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart,
        'label': 'Laporan',
        'index': 4,
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profil',
        'index': 5,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.map((item) {
              final targetIndex = item['index'] as int;
              final isActive = _currentIndex == targetIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = targetIndex),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive
                            ? item['activeIcon'] as IconData
                            : item['icon'] as IconData,
                        size: 22,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _getCurrentPage() {
    final isPrivileged = _isPrivilegedRole(_currentRole());
    switch (_currentIndex) {
      case 0:
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  AnalyticsBloc(context.read<AnalyticsRepository>())
                    ..add(LoadDashboardStats()),
            ),
          ],
          child: BlocListener<AnalyticsBloc, AnalyticsState>(
            listener: (context, state) {
              if (state is AnalyticsLoaded) {
                setState(() => _homeLastUpdatedAt = DateTime.now());
              }
            },
            child: Builder(
              builder: (context) => LiveRefresh(
                interval: const Duration(seconds: 30),
                onRefresh: () async {
                  final state = context.read<AnalyticsBloc>().state;
                  final periode =
                      state is AnalyticsLoaded ? state.stats.periode : '7d';
                  context.read<AnalyticsBloc>().add(
                        RefreshDashboardStats(periode: periode),
                      );
                  context.read<NotifikasiBloc>().add(RefreshNotifikasi());
                },
                child: _HomePage(
                  onTabChange: (i) => setState(() => _currentIndex = i),
                  lastUpdatedAt: _homeLastUpdatedAt,
                ),
              ),
            ),
          ),
        );
      case 1:
        return BlocProvider(
          create: (context) => HargaBloc(context.read<HargaRepository>()),
          child: const HargaPage(),
        );
      case 2:
        if (!isPrivileged) {
          return _HomePage(
            onTabChange: (i) => setState(() => _currentIndex = i),
          );
        }
        return BlocProvider(
          create: (context) =>
              StokBloc(context.read<StokRepository>())..add(LoadStokList()),
          child: const StokPanganPage(),
        );
      case 3:
        return BlocProvider(
          create: (context) =>
              DistribusiBloc(context.read<DistribusiRepository>())
                ..add(LoadDistribusiList()),
          child: const DistribusiPage(),
        );
      case 4:
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  LaporanBloc(context.read<LaporanRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  AnalyticsBloc(context.read<AnalyticsRepository>())
                    ..add(LoadDashboardStats()),
            ),
          ],
          child: const LaporanPage(),
        );
      case 5:
        return BlocProvider(
          create: (context) => ProfileBloc(context.read<ProfileRepository>())
            ..add(LoadProfile()),
          child: const ProfilePage(),
        );
      default:
        return _HomePage(onTabChange: (i) => setState(() => _currentIndex = i));
    }
  }
}
