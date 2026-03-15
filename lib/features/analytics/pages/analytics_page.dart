import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      final bloc = context.read<AnalyticsBloc>();
      final state = bloc.state;
      if (_tabCtrl.index == 0 &&
          state is! AnalyticsLoading &&
          state is! AnalyticsLoaded &&
          state is! AnalyticsError) {
        bloc.add(LoadDashboardStats());
      }
      if (_tabCtrl.index == 1 &&
          state is! StatusPanganLoading &&
          state is! StatusPanganLoaded &&
          state is! StatusPanganError) {
        bloc.add(LoadStatusPangan());
      }
    });
    context.read<AnalyticsBloc>().add(LoadDashboardStats());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabCtrl,
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2E7D32),
                tabs: const [
                  Tab(text: 'Ringkasan'),
                  Tab(text: 'Status per Kecamatan'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildRingkasanTab(),
            _buildStatusPanganTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analitik Pangan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pantau ketahanan pangan Kabupaten Lamongan',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingkasanTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      buildWhen: (prev, curr) =>
          curr is AnalyticsLoading ||
          curr is AnalyticsLoaded ||
          curr is AnalyticsError,
      builder: (ctx, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (state is AnalyticsError) {
          return _buildError(
            state.message,
            () => ctx.read<AnalyticsBloc>().add(LoadDashboardStats()),
          );
        }
        if (state is AnalyticsLoaded) {
          return _buildRingkasanContent(state.stats);
        }
        // Reload ringkasan saat state terakhir berasal dari tab lain.
        return Builder(
          builder: (ctx2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ctx2.read<AnalyticsBloc>().add(LoadDashboardStats());
            });
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          },
        );
      },
    );
  }

  Widget _buildRingkasanContent(DashboardStats s) {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async =>
          context.read<AnalyticsBloc>().add(LoadDashboardStats()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _chartSectionTitle('Grafik KPI Operasional'),
          const SizedBox(height: 10),
          _buildKpiChart(s),
          const SizedBox(height: 20),
          _chartSectionTitle('Grafik Komposisi Status Kecamatan'),
          const SizedBox(height: 10),
          _buildStatusCompositionChart(s),
          const SizedBox(height: 20),
          _chartSectionTitle('Grafik Tren Harga 7 Hari'),
          const SizedBox(height: 10),
          _buildPriceTrendChart(s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chartSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF424242),
      ),
    );
  }

  Widget _chartCard({required Widget child, double height = 260}) {
    return Container(
      height: height,
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
      child: child,
    );
  }

  Widget _buildKpiChart(DashboardStats s) {
    final values = [
      s.totalKomoditas.toDouble(),
      s.alertCount.toDouble(),
      s.updateHariIni.toDouble(),
      s.distribusiAktif.toDouble(),
      s.laporanBulanIni.toDouble(),
    ];
    final labels = ['Komoditas', 'Alert', 'Update', 'Distribusi', 'Laporan'];
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.3).clamp(5, 1000);
    final barColors = const [
      Color(0xFF2E7D32),
      Color(0xFFF57C00),
      Color(0xFF1976D2),
      Color(0xFF6A1B9A),
      Color(0xFFC62828),
    ];

    return _chartCard(
      child: BarChart(
        BarChartData(
          maxY: maxY.toDouble(),
          gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxY / 5,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(values.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 22,
                  borderRadius: BorderRadius.circular(6),
                  color: barColors[i],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatusCompositionChart(DashboardStats s) {
    final total = (s.kecamatanAman + s.kecamatanWaspada + s.kecamatanKritis)
        .toDouble();
    if (total == 0) {
      return _chartCard(
        child: const Center(
          child: Text('Belum ada data status kecamatan'),
        ),
      );
    }

    return _chartCard(
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: s.kecamatanAman.toDouble(),
                    color: const Color(0xFF2E7D32),
                    title:
                        '${((s.kecamatanAman / total) * 100).toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: s.kecamatanWaspada.toDouble(),
                    color: const Color(0xFFF57C00),
                    title:
                        '${((s.kecamatanWaspada / total) * 100).toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: s.kecamatanKritis.toDouble(),
                    color: const Color(0xFFC62828),
                    title:
                        '${((s.kecamatanKritis / total) * 100).toStringAsFixed(0)}%',
                    radius: 48,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('Aman', s.kecamatanAman, const Color(0xFF2E7D32)),
                const SizedBox(height: 8),
                _legendItem(
                    'Waspada', s.kecamatanWaspada, const Color(0xFFF57C00)),
                const SizedBox(height: 8),
                _legendItem('Kritis', s.kecamatanKritis, const Color(0xFFC62828)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTrendChart(DashboardStats s) {
    final beras = s.harga7HariBeras;
    final jagung = s.harga7HariJagung;
    final cabai = s.harga7HariCabai;
    final all = [...beras, ...jagung, ...cabai];
    final double minY =
      all.isEmpty ? 0.0 : all.reduce((a, b) => a < b ? a : b) * 0.95;
    final double maxY =
      all.isEmpty ? 10.0 : all.reduce((a, b) => a > b ? a : b) * 1.05;

    List<FlSpot> spots(List<double> values) {
      return values.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value);
      }).toList();
    }

    return _chartCard(
      height: 290,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(show: true, horizontalInterval: (maxY - minY) / 5),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                interval: (maxY - minY) / 5,
                getTitlesWidget: (value, _) => Text(
                  '${(value / 1000).toStringAsFixed(0)}rb',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  'H-${6 - value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots(beras),
              isCurved: true,
              color: const Color(0xFF2E7D32),
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spots(jagung),
              isCurved: true,
              color: const Color(0xFF1976D2),
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spots(cabai),
              isCurved: true,
              color: const Color(0xFFC62828),
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanganTab() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      buildWhen: (prev, curr) =>
          curr is StatusPanganLoading ||
          curr is StatusPanganLoaded ||
          curr is StatusPanganError,
      builder: (ctx, state) {
        if (state is StatusPanganLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (state is StatusPanganError) {
          return _buildError(
            state.message,
            () => ctx.read<AnalyticsBloc>().add(LoadStatusPangan()),
          );
        }
        if (state is StatusPanganLoaded) {
          return _buildStatusCharts(ctx, state.items);
        }
        // Trigger load when tab is shown for the first time
        return Builder(
          builder: (ctx2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ctx2.read<AnalyticsBloc>().add(LoadStatusPangan());
            });
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusList(BuildContext ctx, List<StatusPanganItem> items) {
    return _buildStatusCharts(ctx, items);
  }

  Widget _buildStatusCharts(BuildContext ctx, List<StatusPanganItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada data kecamatan',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final sorted = [...items]..sort((a, b) {
        final order = {
          'kritis': 0,
          'waspada': 1,
          'aman': 2,
          'tidak_ada_data': 3
        };
        return (order[a.statusStok] ?? 4).compareTo(order[b.statusStok] ?? 4);
      });

    final top = sorted.take(8).toList();
    final naik = items.where((e) => e.hargaTrend == 'NAIK').length;
    final turun = items.where((e) => e.hargaTrend == 'TURUN').length;
    final stabil = items.where((e) => e.hargaTrend == 'STABIL').length;
    final totalTrend = (naik + turun + stabil).clamp(1, 999999);

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async => ctx.read<AnalyticsBloc>().add(LoadStatusPangan()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _chartSectionTitle('Grafik Stok per Kecamatan (Top 8 Prioritas)'),
          const SizedBox(height: 10),
          _chartCard(
            height: 300,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(show: true, horizontalInterval: 20),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final i = group.x;
                      if (i < 0 || i >= top.length) return null;
                      return BarTooltipItem(
                        '${top[i].kecamatanNama}\n${top[i].stokPersen.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 34,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= top.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(top.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: top[i].stokPersen,
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: _statusColor(top[i].statusStok),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(top.length, (i) {
                final item = top[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == top.length - 1 ? 0 : 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${i + 1}.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.kecamatanNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(item.statusStok).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.stokPersen.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(item.statusStok),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          _chartSectionTitle('Grafik Tren Harga per Status'),
          const SizedBox(height: 10),
          _chartCard(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: [naik, turun, stabil, 1].reduce((a, b) => a > b ? a : b) *
                    1.4,
                gridData: FlGridData(show: true, horizontalInterval: 1),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final labels = ['Naik', 'Turun', 'Stabil'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: naik.toDouble(),
                        width: 28,
                        color: const Color(0xFFC62828),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: turun.toDouble(),
                        width: 28,
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: stabil.toDouble(),
                        width: 28,
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _trendBadge(
                  'Naik',
                  naik,
                  '${(naik * 100 / totalTrend).toStringAsFixed(0)}%',
                  const Color(0xFFC62828),
                ),
                const SizedBox(width: 8),
                _trendBadge(
                  'Turun',
                  turun,
                  '${(turun * 100 / totalTrend).toStringAsFixed(0)}%',
                  const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                _trendBadge(
                  'Stabil',
                  stabil,
                  '${(stabil * 100 / totalTrend).toStringAsFixed(0)}%',
                  const Color(0xFF1976D2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendBadge(String label, int count, String pct, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count kec.',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              pct,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aman':
        return const Color(0xFF2E7D32);
      case 'waspada':
        return const Color(0xFFFF8F00);
      case 'kritis':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'aman':
        return '✅ Aman';
      case 'waspada':
        return '⚠️ Waspada';
      case 'kritis':
        return '🚨 Kritis';
      default:
        return 'Tidak Ada Data';
    }
  }

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
