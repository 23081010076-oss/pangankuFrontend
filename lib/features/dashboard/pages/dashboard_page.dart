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

part '../widgets/dashboard_home_section.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _getCurrentPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Beranda',
      },
      {
        'icon': Icons.trending_up_outlined,
        'activeIcon': Icons.trending_up,
        'label': 'Harga',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'activeIcon': Icons.inventory_2,
        'label': 'Stok',
      },
      {
        'icon': Icons.local_shipping_outlined,
        'activeIcon': Icons.local_shipping,
        'label': 'Distribusi',
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart,
        'label': 'Laporan',
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profil',
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
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentIndex = i),
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
    switch (_currentIndex) {
      case 0:
        return BlocProvider(
          create: (context) =>
              AnalyticsBloc(context.read<AnalyticsRepository>())
                ..add(LoadDashboardStats()),
          child:
              _HomePage(onTabChange: (i) => setState(() => _currentIndex = i)),
        );
      case 1:
        return BlocProvider(
          create: (context) => HargaBloc(context.read<HargaRepository>()),
          child: const HargaPage(),
        );
      case 2:
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
              create: (context) => LaporanBloc(context.read<LaporanRepository>()),
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
          create: (context) =>
              ProfileBloc(context.read<ProfileRepository>())..add(LoadProfile()),
          child: const ProfilePage(),
        );
      default:
        return _HomePage(onTabChange: (i) => setState(() => _currentIndex = i));
    }
  }
}
