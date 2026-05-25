// Penjelasan file:
// Feature: analytics
// Layer: ui
// File: analytics_page
// Fungsi utama: File ini mengatur tampilan halaman, komponen visual, dan interaksi pengguna.
// Tujuan tambahan: Menampilkan gambar komoditas pada mover/tren analitik jika metadata gambar tersedia.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/live_refresh.dart';
import '../../../core/widgets/last_updated_badge.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';
import 'luas_lahan_page.dart';

part '../widgets/analytics_sections.dart';

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
  DateTime? _ringkasanLastUpdatedAt;
  DateTime? _statusLastUpdatedAt;

  static const Map<String, String> _periodeOptions = {
    '7d': '7 Hari',
    '30d': '30 Hari',
    '90d': '90 Hari',
  };

  static const _komoditasColors = [
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFF795548),
    Color(0xFFC62828),
    Color(0xFF1976D2),
    Color(0xFFF57C00),
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
    return LiveRefresh(
      interval: const Duration(seconds: 30),
      onRefresh: () async {
        final bloc = context.read<AnalyticsBloc>();
        final state = bloc.state;
        if (_tabCtrl.index == 0) {
          final periode = state is AnalyticsLoaded ? state.stats.periode : '7d';
          bloc.add(RefreshDashboardStats(periode: periode));
          return;
        }
        bloc.add(LoadStatusPangan());
      },
      child: BlocListener<AnalyticsBloc, AnalyticsState>(
        listener: (context, state) {
          if (state is AnalyticsLoaded) {
            setState(() => _ringkasanLastUpdatedAt = DateTime.now());
          } else if (state is StatusPanganLoaded) {
            setState(() => _statusLastUpdatedAt = DateTime.now());
          }
        },
        child: Scaffold(
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analitik Pangan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau ketahanan pangan Kabupaten Lamongan',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              LastUpdatedBadge(
                timestamp: _tabCtrl.index == 0
                    ? _ringkasanLastUpdatedAt
                    : _statusLastUpdatedAt,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
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
      onRefresh: () async => context
          .read<AnalyticsBloc>()
          .add(LoadDashboardStats(periode: s.periode)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: ListView(
            key: const PageStorageKey('ringkasan_tab_list'),
            padding: const EdgeInsets.all(16),
            children: [
              _buildMarketOverviewBanner(s),
              const SizedBox(height: 16),
              _buildMarketMovers(s),
              const SizedBox(height: 20),
              _buildTrendHargaCard(s),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTrend(
    String name,
    List<double> data,
    String imageUrl,
  ) {
    if (data.length < 2) {
      return {
        'name': name,
        'change': 0.0,
        'val': data.isEmpty ? 0.0 : data.last,
        'imageUrl': imageUrl,
      };
    }

    // Cari harga pertama dan terakhir yang tidak 0
    double first = data.firstWhere((e) => e > 0, orElse: () => 0.0);
    double last = data.lastWhere((e) => e > 0, orElse: () => 0.0);

    double change = first > 0 ? ((last - first) / first) * 100 : 0.0;
    return {'name': name, 'change': change, 'val': last, 'imageUrl': imageUrl};
  }

  String? _normalizeImageUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final apiUri = Uri.parse(AppConstants.baseUrl);
    final origin =
        '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  Widget _commodityImage(String? rawUrl, {double size = 34}) {
    final imageUrl = _normalizeImageUrl(rawUrl);
    if (imageUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          size: size * 0.52,
          color: const Color(0xFF2E7D32),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: size * 0.52,
            color: const Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketOverviewBanner(DashboardStats s) {
    final trends = [
      ...s.komoditasTrend.map(
        (k) => _getTrend(k.nama, k.hargaHarian, k.gambarUrl),
      ),
    ];

    int countNaik = trends.where((e) => (e['change'] as double) > 0).length;
    int countTurun = trends.where((e) => (e['change'] as double) < 0).length;

    String insightText = 'Pasar stabil.';
    if (countNaik > 3) {
      insightText = 'Sebagian besar pangan mengalami **kenaikan** harga.';
    } else if (countTurun > 3) {
      insightText = 'Terdapat tren **penurunan** harga secara umum.';
    } else if (countNaik > 0 || countTurun > 0) {
      insightText =
          'Harga pangan sedang **fluktuatif** (Naik: $countNaik, Turun: $countTurun)';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF15361A),
            const Color(0xFF215B29),
            countNaik >= countTurun
                ? const Color(0xFF2E7D32)
                : const Color(0xFF7A2E2E),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
          const SizedBox(height: 14),
          Text(
            insightText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryPill(
                '${s.totalKomoditas} komoditas',
                Icons.inventory_2_outlined,
              ),
              _summaryPill(
                '$countNaik naik',
                Icons.trending_up,
              ),
              _summaryPill(
                '$countTurun turun',
                Icons.trending_down,
              ),
              _summaryPill(
                '${s.distribusiAktif} distribusi aktif',
                Icons.local_shipping_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMovers(DashboardStats s) {
    final trends = [
      ...s.komoditasTrend.map(
        (k) => _getTrend(k.nama, k.hargaHarian, k.gambarUrl),
      ),
    ];

    trends.sort(
      (a, b) => (b['change'] as double).compareTo(a['change'] as double),
    );

    final topRiser = trends.first;
    final topFaller = trends.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 720;
        if (vertical) {
          return Column(
            children: [
              _moverCard('Lonjakan Tertinggi', topRiser),
              const SizedBox(height: 12),
              _moverCard('Penurunan Terdalam', topFaller),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _moverCard('Lonjakan Tertinggi', topRiser)),
            const SizedBox(width: 12),
            Expanded(child: _moverCard('Penurunan Terdalam', topFaller)),
          ],
        );
      },
    );
  }

  Widget _summaryPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moverCard(String title, Map<String, dynamic> item) {
    final change = item['change'] as double;
    final isUp = change > 0;
    final isDown = change < 0;
    final color = isUp
        ? Colors.red[700]!
        : (isDown ? Colors.green[700]! : Colors.blue[800]!);
    final bg = isUp
        ? Colors.red[50]!
        : (isDown ? Colors.green[50]! : Colors.blue[50]!);
    final icon = isUp
        ? Icons.trending_up
        : (isDown ? Icons.trending_down : Icons.trending_flat);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bg, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              _commodityImage(item['imageUrl'] as String?),
              const SizedBox(width: 8),
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

  Widget _chartCard({required Widget child, double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  List<double> _getDataBySelectedKomoditas(DashboardStats s) {
    if (s.komoditasTrend.isEmpty) return [];
    final idx = _selectedKomoditasIdx % s.komoditasTrend.length;
    return s.komoditasTrend[idx].hargaHarian;
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

  void _openLuasLahanPage(DashboardStats stats) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LuasLahanPage(stats: stats),
      ),
    );
  }

  Widget _buildTrendHargaCard(DashboardStats s) {
    final data = _getDataBySelectedKomoditas(s);
    final labels = s.tanggalLabels.isEmpty
        ? List<String>.generate(data.length, (i) => 'H${i + 1}')
        : s.tanggalLabels;
    final showEvery = labels.length > 10 ? (labels.length / 6).ceil() : 1;
    final color =
        _komoditasColors[_selectedKomoditasIdx % _komoditasColors.length];

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
    final latestPrice = data.lastWhere((e) => e > 0, orElse: () => 0.0);
    final earliestPrice = data.firstWhere((e) => e > 0, orElse: () => 0.0);
    final changePct = earliestPrice == 0
        ? 0.0
        : ((latestPrice - earliestPrice) / earliestPrice) * 100;
    final validData = data.where((e) => e > 0).toList();
    final avgPrice = validData.isEmpty
        ? 0.0
        : validData.reduce((a, b) => a + b) / validData.length;
    final komoditasName =
        s.komoditasTrend[_selectedKomoditasIdx % s.komoditasTrend.length].nama;
    final trendColor =
        changePct >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF5), Color(0xFFF8FAF7)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E1D4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 700;
              final periodPicker = Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFE4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4DECE)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: s.periode,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3E4A42),
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
              );

              final metricBlock = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      komoditasName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF7A6F57),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Panel Tren Harga',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF203028),
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Rp ${_formatCompact(latestPrice)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: trendColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                changePct >= 0
                                    ? Icons.north_east_rounded
                                    : Icons.south_east_rounded,
                                size: 14,
                                color: trendColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: trendColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bandingkan pergerakan harga, rentang nilai, dan pola komoditas tanpa mengikuti layout dashboard.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6A736D),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [metricBlock],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: periodPicker,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  metricBlock,
                  const SizedBox(width: 14),
                  periodPicker,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBE3D5)),
            ),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth < 520
                        ? (constraints.maxWidth - 10) / 2
                        : (constraints.maxWidth - 20) / 3;
                    final summaryCards = [
                      _analyticsMetricTile(
                        'Rata-rata',
                        'Rp ${_formatCompact(avgPrice)}',
                        const Color(0xFF6F7F3D),
                        const Color(0xFFF3F6E9),
                      ),
                      _analyticsMetricTile(
                        'Minimum',
                        'Rp ${_formatCompact(data.isEmpty ? 0 : minRaw)}',
                        const Color(0xFF5C6B73),
                        const Color(0xFFF1F4F6),
                      ),
                      _analyticsMetricTile(
                        'Maksimum',
                        'Rp ${_formatCompact(data.isEmpty ? 0 : maxRaw)}',
                        const Color(0xFF1E88E5),
                        const Color(0xFFEAF4FF),
                      ),
                      _analyticsMetricTile(
                        'Rentang',
                        'Rp ${_formatCompact((maxRaw - minRaw).abs())}',
                        const Color(0xFF8E5A2B),
                        const Color(0xFFFFF1E8),
                      ),
                    ];
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final card in summaryCards)
                          SizedBox(width: itemWidth, child: card),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openLuasLahanPage(s),
                    icon: const Icon(Icons.landscape_outlined, size: 16),
                    label: const Text('Lihat Luas Lahan'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      backgroundColor: const Color(0xFFEFF7F0),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: s.komoditasTrend.length,
              itemBuilder: (_, i) {
                final isSelected = _selectedKomoditasIdx == i;
                final c = _komoditasColors[i % _komoditasColors.length];
                return GestureDetector(
                  onTap: () => setState(() => _selectedKomoditasIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? c.withValues(alpha: 0.12)
                          : const Color(0xFFF5F2EA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? c.withValues(alpha: 0.38)
                            : const Color(0xFFE5DFD1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _commodityImage(
                          s.komoditasTrend[i].gambarUrl,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.komoditasTrend[i].nama,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? c : const Color(0xFF6A6F68),
                          ),
                        ),
                      ],
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(
                  MediaQuery.of(context).size.width - 64,
                  labels.length * 34.0 + 50,
                ),
                height: 260,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFB),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFEEE6D8)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 18, 14, 12),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (labels.length - 1).toDouble(),
                        minY: chartMinY > 0 ? chartMinY : 0,
                        maxY: chartMaxY,
                        clipData: const FlClipData.all(),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: avgPrice,
                              color: const Color(0xFF9C6ADE).withValues(
                                alpha: 0.32,
                              ),
                              strokeWidth: 1.1,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 4),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8E44AD),
                                ),
                                labelResolver: (_) => 'Rata-rata',
                              ),
                            ),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipRoundedRadius: 12,
                            tooltipPadding: const EdgeInsets.all(10),
                            getTooltipColor: (_) => const Color(0xFF24332C),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final idx = spot.x.toInt();
                                final label = (idx >= 0 && idx < labels.length)
                                    ? labels[idx]
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
                                        fontWeight: FontWeight.w800,
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
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFB8C4BC).withValues(
                              alpha: 0.22,
                            ),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              interval: yInterval,
                              getTitlesWidget: (v, meta) {
                                if (v == meta.max || v == meta.min) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  _formatCompact(v),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF8A948D),
                                    fontWeight: FontWeight.w600,
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
                              getTitlesWidget: (v, meta) {
                                if (v % 1 != 0) {
                                  return const SizedBox.shrink();
                                }
                                final idx = v.toInt();
                                if (idx < 0 || idx >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                if (idx % showEvery != 0 &&
                                    idx != labels.length - 1) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[idx],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF8A948D),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFFC7D0C9).withValues(
                                alpha: 0.55,
                              ),
                            ),
                            bottom: BorderSide(
                              color: const Color(0xFFC7D0C9).withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: color,
                            barWidth: 3.2,
                            isStrokeCapRound: true,
                            shadow: BoxShadow(
                              color: color.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: index == spots.length - 1 ? 5 : 4,
                                color: index == spots.length - 1
                                    ? color
                                    : const Color(0xFFFFFEFB),
                                strokeWidth: 1.8,
                                strokeColor: color,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  color.withValues(alpha: 0.16),
                                  color.withValues(alpha: 0.01),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _analyticsMetricTile(
    String label,
    String value,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF23312B),
            ),
          ),
        ],
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
