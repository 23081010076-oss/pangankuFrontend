import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
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
  int _selectedKomoditasIdx = 0;
  List<String> _selectedKecamatanNames = [];

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
          context.read<AnalyticsBloc>().add(LoadDashboardStats(periode: s.periode)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMarketOverviewBanner(s),
          const SizedBox(height: 14),
          _buildMarketMovers(s),
          const SizedBox(height: 20),
          _buildTrendHargaCard(s),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Map<String, dynamic> _getTrend(String name, List<double> data, String emoji) {
    if (data.length < 2) return {'name': name, 'change': 0.0, 'val': data.isEmpty ? 0.0 : data.last, 'emoji': emoji};
    double first = data.first;
    double last = data.last;
    double change = first > 0 ? ((last - first) / first) * 100 : 0.0;
    return {'name': name, 'change': change, 'val': last, 'emoji': emoji};
  }

  Widget _buildMarketOverviewBanner(DashboardStats s) {
    final trends = [
      _getTrend('Beras', s.harga7HariBeras, '🌾'),
      _getTrend('Jagung', s.harga7HariJagung, '🌽'),
      _getTrend('Kedelai', s.harga7HariKedelai, '🫘'),
      _getTrend('Cabai', s.harga7HariCabai, '🌶️'),
      _getTrend('Gula', s.harga7HariGula, '🍚'),
      _getTrend('Minyak', s.harga7HariMinyak, '🫙'),
    ];
    
    int countNaik = trends.where((e) => (e['change'] as double) > 0).length;
    int countTurun = trends.where((e) => (e['change'] as double) < 0).length;
    
    String insightText = 'Pasar stabil.';
    if (countNaik > 3) {
      insightText = 'Sebagian besar pangan mengalami **kenaikan** harga.';
    } else if (countTurun > 3) {
      insightText = 'Terdapat tren **penurunan** harga secara umum.';
    } else if (countNaik > 0 || countTurun > 0) {
      insightText = 'Harga pangan sedang **fluktuatif** (Naik: $countNaik, Turun: $countTurun)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF154D1A), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Analisis Harga Pasar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${s.periode} Terakhir',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insightText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMovers(DashboardStats s) {
    final trends = [
      _getTrend('Beras', s.harga7HariBeras, '🌾'),
      _getTrend('Jagung', s.harga7HariJagung, '🌽'),
      _getTrend('Kedelai', s.harga7HariKedelai, '🫘'),
      _getTrend('Cabai', s.harga7HariCabai, '🌶️'),
      _getTrend('Gula', s.harga7HariGula, '🍚'),
      _getTrend('Minyak', s.harga7HariMinyak, '🫙'),
    ];

    trends.sort((a, b) => (b['change'] as double).compareTo(a['change'] as double));
    
    final topRiser = trends.first;
    final topFaller = trends.last;

    return Row(
      children: [
        Expanded(child: _moverCard('Lonjakan Tertinggi', topRiser)),
        const SizedBox(width: 12),
        Expanded(child: _moverCard('Penurunan Terdalam', topFaller)),
      ],
    );
  }

  Widget _moverCard(String title, Map<String, dynamic> item) {
    final change = item['change'] as double;
    final isUp = change > 0;
    final isDown = change < 0;
    final color = isUp ? Colors.red[700]! : (isDown ? Colors.green[700]! : Colors.blue[800]!);
    final bg = isUp ? Colors.red[50]! : (isDown ? Colors.green[50]! : Colors.blue[50]!);
    final icon = isUp ? Icons.trending_up : (isDown ? Icons.trending_down : Icons.trending_flat);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bg, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item['emoji'] as String,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${_formatCompact(item['val'] as double)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 10, color: color),
                    const SizedBox(width: 2),
                    Text(
                      '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

  List<double> _getDataBySelectedKomoditas(DashboardStats s) {
    switch (_selectedKomoditasIdx) {
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
        return s.harga7HariBeras;
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

  Widget _buildTrendHargaCard(DashboardStats s) {
    final data = _getDataBySelectedKomoditas(s);
    final labels = s.tanggalLabels.isEmpty
        ? List<String>.generate(data.length, (i) => 'H${i + 1}')
        : s.tanggalLabels;
    final showEvery = labels.length > 10 ? (labels.length / 6).ceil() : 1;
    final color = _komoditas[_selectedKomoditasIdx]['color'] as Color;

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
    final latestPrice = data.isEmpty ? 0.0 : data.last;
    final earliestPrice = data.isEmpty ? 0.0 : data.first;
    final changePct = earliestPrice == 0
      ? 0.0
      : ((latestPrice - earliestPrice) / earliestPrice) * 100;
    final avgPrice =
      data.isEmpty ? 0.0 : data.reduce((a, b) => a + b) / data.length;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panel Tren Harga',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Rp ${latestPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (changePct >= 0
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFEBEE))
                      .withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: changePct >= 0
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: s.periode,
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
                      if (value == null || value == s.periode) {
                        return;
                      }
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
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _komoditas.length,
              itemBuilder: (_, i) {
                final isSelected = _selectedKomoditasIdx == i;
                final c = _komoditas[i]['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedKomoditasIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          if (spots.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined, size: 40, color: Colors.grey[300]),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(MediaQuery.of(context).size.width - 64, labels.length * 28.0),
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: chartMaxY,
                    minY: chartMinY > 0 ? chartMinY : 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF1E293B).withOpacity(0.9),
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final idx = group.x;
                          final label = (idx >= 0 && idx < labels.length) ? labels[idx] : '';
                          return BarTooltipItem(
                            '$label\n',
                            const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Rp ${_formatCompact(rod.toY)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
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
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= labels.length) {
                              return const SizedBox();
                            }
                            if (idx % showEvery != 0 && idx != labels.length - 1) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
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
                    barGroups: data.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            width: 14,
                            color: color,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _priceStatBox('Min', data.isEmpty ? 0 : minRaw, const Color(0xFF546E7A)),
              const SizedBox(width: 8),
              _priceStatBox('Rata-rata', avgPrice, color),
              const SizedBox(width: 8),
              _priceStatBox('Maks', data.isEmpty ? 0 : maxRaw, const Color(0xFF1E88E5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceStatBox(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Rp ${value.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF37474F),
              ),
            ),
          ],
        ),
      ),
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

  void _showKecamatanFilter(List<StatusPanganItem> items) {
    // Ambil daftar unik nama kecamatan
    final allKecamatan = items.map((e) => e.kecamatanNama).toSet().toList();
    allKecamatan.sort();

    // Buat list temporary untuk state di dalam dialog
    List<String> tempSelected = List.from(_selectedKecamatanNames);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              title: const Text('Filter Kecamatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateBuilder(() => tempSelected = List.from(allKecamatan));
                          },
                          child: const Text('Pilih Semua'),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateBuilder(() => tempSelected.clear());
                          },
                          child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allKecamatan.length,
                        itemBuilder: (context, index) {
                          final name = allKecamatan[index];
                          final isSelected = tempSelected.contains(name);
                          return CheckboxListTile(
                            title: Text(name, style: const TextStyle(fontSize: 14)),
                            value: isSelected,
                            activeColor: const Color(0xFF2E7D32),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setStateBuilder(() {
                                if (value == true) {
                                  tempSelected.add(name);
                                } else {
                                  tempSelected.remove(name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () {
                    // Update state utama
                    setState(() {
                      _selectedKecamatanNames = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCharts(BuildContext ctx, List<StatusPanganItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada data kecamatan',
            style: TextStyle(color: Colors.grey)),
      );
    }

    // Perbaikan 1: Sorting berdasarkan stokPersen dari TERENDAH ke TERTINGGI (paling kritis di kiri)
    final sorted = [...items]..sort((a, b) => a.stokPersen.compareTo(b.stokPersen));

    // Filter by kecamatan jika ada
    final filteredItems = _selectedKecamatanNames.isEmpty
        ? sorted
        : sorted.where((e) => _selectedKecamatanNames.contains(e.kecamatanNama)).toList();

    // Tampilkan kecamatan yang sudah difilter
    final top = filteredItems.toList();
    if (top.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Terapkan setidaknya 1 filter kecamatan',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    
    final naik = items.where((e) => e.hargaTrend == 'NAIK').length;
    final turun = items.where((e) => e.hargaTrend == 'TURUN').length;
    final stabil = items.where((e) => e.hargaTrend == 'STABIL').length;
    final totalTrend = (naik + turun + stabil).clamp(1, 999999);
    final maxTrend = math.max(naik, math.max(turun, stabil)).toDouble();
    final trendMaxY = math.max(4.0, (maxTrend * 1.25).ceilToDouble());
    final trendInterval = math.max(1.0, (trendMaxY / 4).ceilToDouble());

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async => ctx.read<AnalyticsBloc>().add(LoadStatusPangan()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chartSectionTitle('Grafik Stok per Kecamatan'),
              TextButton.icon(
                onPressed: () => _showKecamatanFilter(items),
                icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF2E7D32)),
                label: const Text('Filter Area', style: TextStyle(color: Color(0xFF2E7D32))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _chartCard(
            height: 380, // Tinggi diperbesar untuk grafik bar yang lebih jelas
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(MediaQuery.of(ctx).size.width - 64, top.length * 60.0), // Ruang antar batang diperlebar
                child: BarChart(
                  BarChartData(
                    maxY: 120, // Beri jarak di atas bar untuk label persentase
                    extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 30, // Asumsi di bawah 30% itu kritis
                      color: Colors.red.withOpacity(0.6),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 5, bottom: 5),
                        style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        labelResolver: (_) => 'Batas Kritis (30%)',
                      ),
                    ),
                    HorizontalLine(
                      y: 70, // Asumsi di atas 70% itu aman
                      color: Colors.green.withOpacity(0.6),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(left: 5, bottom: 5),
                        style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        labelResolver: (_) => 'Batas Aman (70%)',
                      ),
                    ),
                  ],
                ),
                gridData: FlGridData(show: true, horizontalInterval: 20),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 6,
                    getTooltipColor: (_) => Colors.transparent,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final i = group.x;
                      if (i < 0 || i >= top.length) return null;
                      return BarTooltipItem(
                        '${top[i].stokPersen.toStringAsFixed(1)}%',
                        TextStyle(
                          color: _statusColor(top[i].statusStok),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
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
                      reservedSize: 85, // Memberikan ruang lebih besar untuk teks panjang yang diputar
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= top.length) return const SizedBox();
                        
                        String fullName = top[i].kecamatanNama;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              fullName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF455A64),
                              ),
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
                    showingTooltipIndicators: [0],
                    barRods: [
                      BarChartRodData(
                        toY: top[i].stokPersen,
                        width: 24, // Pertebal batang grafik
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        color: _statusColor(top[i].statusStok),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.grey.withOpacity(0.08),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ))),
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
                        width: 25,
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

          const SizedBox(height: 20),

          _chartSectionTitle('Grafik Tren Harga per Status'),
          const SizedBox(height: 10),
          _chartCard(
            height: 250,
            child: BarChart(
              BarChartData(
                maxY: trendMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, __) {
                      final labels = ['Naik', 'Turun', 'Stabil'];
                      final idx = group.x;
                      if (idx < 0 || idx >= labels.length) {
                        return null;
                      }
                      return BarTooltipItem(
                        '${labels[idx]}\n${rod.toY.toInt()} kecamatan',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: trendInterval,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFFE9EEF3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        final values = [naik, turun, stabil];
                        if (idx < 0 || idx >= values.length) {
                          return const SizedBox();
                        }
                        return Text(
                          values[idx].toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF455A64),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: trendInterval,
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
                        width: 24,
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
                        width: 24,
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
                        width: 24,
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
