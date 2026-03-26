import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../harga/bloc/harga_bloc.dart';
import '../../harga/pages/harga_page.dart';
import '../../laporan/bloc/laporan_bloc.dart';
import '../../laporan/pages/laporan_page.dart';
import '../../analytics/bloc/analytics_bloc.dart';
import '../../analytics/bloc/analytics_event.dart';
import '../../analytics/bloc/analytics_state.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_event.dart';
import '../../profile/pages/profile_page.dart';
import '../../stok/bloc/stok_bloc.dart';
import '../../stok/bloc/stok_event.dart';
import '../../stok/pages/stok_pangan_page.dart';
import '../../distribusi/bloc/distribusi_bloc.dart';
import '../../distribusi/bloc/distribusi_event.dart';
import '../../distribusi/pages/distribusi_page.dart';

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
            color: Colors.black.withOpacity(0.08),
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
          create: (_) => AnalyticsBloc(DioClient())..add(LoadDashboardStats()),
          child:
              _HomePage(onTabChange: (i) => setState(() => _currentIndex = i)),
        );
      case 1:
        return BlocProvider(
          create: (context) => HargaBloc(DioClient()),
          child: const HargaPage(),
        );
      case 2:
        return BlocProvider(
          create: (context) => StokBloc(DioClient())..add(LoadStokList()),
          child: const StokPanganPage(),
        );
      case 3:
        return BlocProvider(
          create: (context) =>
              DistribusiBloc(DioClient())..add(LoadDistribusiList()),
          child: const DistribusiPage(),
        );
      case 4:
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => LaporanBloc(DioClient()),
            ),
            BlocProvider(
              create: (_) =>
                  AnalyticsBloc(DioClient())..add(LoadDashboardStats()),
            ),
          ],
          child: const LaporanPage(),
        );
      case 5:
        return BlocProvider(
          create: (_) => ProfileBloc(DioClient())..add(LoadProfile()),
          child: const ProfilePage(),
        );
      default:
        return _HomePage(onTabChange: (i) => setState(() => _currentIndex = i));
    }
  }
}

class _HomePage extends StatelessWidget {
  final void Function(int) onTabChange;
  const _HomePage({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStatusCards(context),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: 20),
                const Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(context),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Peringatan Aktif',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF424242),
                      ),
                    ),
                    BlocBuilder<AnalyticsBloc, AnalyticsState>(
                      builder: (ctx, s) {
                        final n = s is AnalyticsLoaded ? s.stats.alertCount : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$n Aktif',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAlerts(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1),
          end: Alignment(0.4, 1),
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (ctx, state) {
                            final name = state is AuthAuthenticated
                                ? state.name
                                : 'Pengguna';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang,',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cari komoditas, kecamatan...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (ctx, state) {
        final aman = state is AnalyticsLoaded
            ? state.stats.kecamatanAman.toString()
            : '-';
        final waspada = state is AnalyticsLoaded
            ? state.stats.kecamatanWaspada.toString()
            : '-';
        final kritis = state is AnalyticsLoaded
            ? state.stats.kecamatanKritis.toString()
            : '-';
        final cards = [
          {
            'label': 'Aman',
            'value': aman,
            'color': const Color(0xFF2E7D32),
            'bg': const Color(0xFFE8F5E9),
            'icon': Icons.check_circle_outline,
          },
          {
            'label': 'Waspada',
            'value': waspada,
            'color': const Color(0xFFF57C00),
            'bg': const Color(0xFFFFF3E0),
            'icon': Icons.warning_amber_outlined,
          },
          {
            'label': 'Kritis',
            'value': kritis,
            'color': const Color(0xFFC62828),
            'bg': const Color(0xFFFFEBEE),
            'icon': Icons.error_outline,
          },
        ];
        return Row(
          children: cards.map((c) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: cards.indexOf(c) < 2 ? 10 : 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (c['bg'] as Color), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      c['icon'] as IconData,
                      size: 22,
                      color: c['color'] as Color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c['value'] as String,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: c['color'] as Color,
                      ),
                    ),
                    Text(
                      c['label'] as String,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChartCard() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (_, state) => _ChartCardWidget(state: state),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      {
        'icon': Icons.trending_up,
        'label': 'Harga\nKomoditas',
        'color': const Color(0xFF1976D2),
        'index': 1,
      },
      {
        'icon': Icons.inventory_2,
        'label': 'Stok\nPangan',
        'color': const Color(0xFFF57C00),
        'index': 2,
      },
      {
        'icon': Icons.local_shipping,
        'label': 'Distribusi\nPangan',
        'color': const Color(0xFF2E7D32),
        'index': 3,
      },
      {
        'icon': Icons.bar_chart,
        'label': 'Laporan &\nAnalisis',
        'color': const Color(0xFF7B1FA2),
        'index': 4,
      },
      {
        'icon': Icons.map_outlined,
        'label': 'Peta\nSebaran',
        'color': const Color(0xFF00838F),
        'index': -1,
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifikasi',
        'color': const Color(0xFFF57C00),
        'index': -2,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: menus.length,
      itemBuilder: (context, idx) {
        final menu = menus[idx];
        return GestureDetector(
          onTap: () {
            final navIdx = menu['index'] as int;
            if (navIdx >= 0) {
              onTabChange(navIdx);
            } else if (navIdx == -1) {
              context.push('/peta');
            } else if (navIdx == -2) {
              context.push('/notifikasi');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (menu['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    menu['icon'] as IconData,
                    size: 22,
                    color: menu['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  menu['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlerts() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsLoaded || state.stats.activeAlerts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Belum ada laporan darurat aktif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF616161),
              ),
            ),
          );
        }

        return Column(
          children: state.stats.activeAlerts.map((alert) {
            final bool prioritasKritis = alert.prioritas <= 1;
            final bool prioritasSedang = alert.prioritas == 2;
            final Color color = prioritasKritis
                ? const Color(0xFFC62828)
                : prioritasSedang
                ? const Color(0xFFF57C00)
                : const Color(0xFF1976D2);
            final Color bg = prioritasKritis
                ? const Color(0xFFFFEBEE)
                : prioritasSedang
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE3F2FD);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      alert.status == 'proses'
                          ? Icons.sync_outlined
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.jenisMasalah,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        Text(
                          'Kec. ${alert.kecamatanNama} • Prioritas ${alert.prioritas}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Selectable Line Chart Card ────────────────────────────────────────────────
class _ChartCardWidget extends StatefulWidget {
  final AnalyticsState state;
  const _ChartCardWidget({required this.state});

  @override
  State<_ChartCardWidget> createState() => _ChartCardWidgetState();
}

class _ChartCardWidgetState extends State<_ChartCardWidget> {
  int _selectedIdx = 0;
  String _selectedPeriod = '7d';

  static const Map<String, String> _periodeOptions = {
    '7d': '7 Hari',
    '30d': '30 Hari',
    '90d': '90 Hari',
  };

  static const _komoditas = [
    {'nama': 'Beras', 'emoji': '🌾', 'color': Color(0xFF2E7D32)},
    {'nama': 'Jagung', 'emoji': '🌽', 'color': Color(0xFFF9A825)},
    {'nama': 'Kedelai', 'emoji': '🫘', 'color': Color(0xFF795548)},
    {'nama': 'Cabai', 'emoji': '🌶️', 'color': Color(0xFFC62828)},
    {'nama': 'Gula', 'emoji': '🍚', 'color': Color(0xFF1976D2)},
    {'nama': 'Minyak', 'emoji': '🫙', 'color': Color(0xFFF57C00)},
  ];

  List<double> _getData(DashboardStats? s) {
    if (s == null) return List.filled(7, 0.0);
    switch (_selectedIdx) {
      case 0:
        return s.harga7HariBeras;
      case 1:
        return s.harga7HariJagung;
      case 2:
        return s.harga7HariKedelai;
      case 3:
        return s.harga7HariCabai;
      case 4:
        return s.harga7HariGula;
      case 5:
        return s.harga7HariMinyak;
      default:
        return List.filled(7, 0.0);
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      final rb = value / 1000;
      final isRound = (rb - rb.roundToDouble()).abs() < 0.05;
      return isRound ? '${rb.round()}rb' : '${rb.toStringAsFixed(1)}rb';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final s = state is AnalyticsLoaded ? state.stats : null;
    final color = _komoditas[_selectedIdx]['color'] as Color;
    final data = _getData(s);
    final labels = s?.tanggalLabels ?? const [];
    final axisLabels = labels.isEmpty
        ? List<String>.generate(data.length, (i) => 'H${i + 1}')
        : labels;
    final showEvery =
        axisLabels.length > 10 ? (axisLabels.length / 6).ceil() : 1;
    final spots = data
        .asMap()
        .entries
        .where((e) => e.value > 0)
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final values = spots.map((e) => e.y).toList();
    final minRaw = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxRaw = values.isEmpty ? 1.0 : values.reduce(math.max);
    final span = (maxRaw - minRaw).abs();
    final padding = span > 0 ? span * 0.18 : (maxRaw > 0 ? maxRaw * 0.08 : 1.0);
    final chartMinY = math.max(0.0, minRaw - padding).toDouble();
    final chartMaxY = (maxRaw + padding).toDouble();
    final yInterval =
      ((chartMaxY - chartMinY) / 4).clamp(1, double.infinity).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harga Komoditas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                    items: _periodeOptions.entries
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == _selectedPeriod) {
                        return;
                      }
                      setState(() => _selectedPeriod = value);
                      context
                          .read<AnalyticsBloc>()
                          .add(LoadDashboardStats(periode: value));
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Commodity chip selector
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _komoditas.length,
              itemBuilder: (_, i) {
                final isSelected = _selectedIdx == i;
                final c = _komoditas[i]['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? c : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_komoditas[i]['emoji']} ${_komoditas[i]['nama']}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Chart area
          if (state is AnalyticsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (spots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 40,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada data harga',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (axisLabels.length - 1).toDouble(),
                  minY: chartMinY,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1E293B).withOpacity(0.9),
                      tooltipRoundedRadius: 10,
                      fitInsideHorizontally: true,
                      tooltipBorder: const BorderSide(color: Colors.white24, width: 1),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final label = (idx >= 0 && idx < axisLabels.length)
                              ? axisLabels[idx]
                              : '';
                          return LineTooltipItem(
                            '$label\n',
                            const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Rp ${_formatCompact(spot.y)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                    getDrawingVerticalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: yInterval,
                        getTitlesWidget: (v, meta) {
                          if (v == meta.max || v == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _formatCompact(v),
                            style: const TextStyle(
                              fontSize: 9, 
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (v, meta) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= axisLabels.length) {
                            return const SizedBox();
                          }
                          if (idx % showEvery != 0 &&
                              idx != axisLabels.length - 1) {
                            return const SizedBox();
                          }
                          return Text(
                            axisLabels[idx],
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.withOpacity(0.25)),
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.25)),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      shadow: BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.35),
                            color.withOpacity(0.0),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          // Show dots only on endpoints or every data point if few
                          if (spots.length > 30 && index % 3 != 0 && index != spots.length - 1 && index != 0) {
                            return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0);
                          }
                          return FlDotCirclePainter(
                            radius: 3.5,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: color,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
