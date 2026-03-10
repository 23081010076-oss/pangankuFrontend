import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        return const SizedBox();
      },
    );
  }

  Widget _buildRingkasanContent(DashboardStats s) {
    final currencyFmt = NumberFormat('#,###', 'id');
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async =>
          context.read<AnalyticsBloc>().add(LoadDashboardStats()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'KPI Hari Ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _kpiCard(
              'Total Komoditas',
              '${s.totalKomoditas}',
              Icons.inventory_2_outlined,
              const Color(0xFF2E7D32),
              const Color(0xFFE8F5E9),
            ),
            const SizedBox(width: 10),
            _kpiCard(
              'Alert Aktif',
              '${s.alertCount}',
              Icons.warning_amber_outlined,
              const Color(0xFFF57C00),
              const Color(0xFFFFF3E0),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _kpiCard(
              'Update Hari Ini',
              '${s.updateHariIni}',
              Icons.update_outlined,
              Colors.blue,
              Colors.blue.shade50,
            ),
            const SizedBox(width: 10),
            _kpiCard(
              'Distribusi Aktif',
              '${s.distribusiAktif}',
              Icons.local_shipping_outlined,
              const Color(0xFF7B1FA2),
              const Color(0xFFF3E5F5),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _kpiCard(
              'Laporan Bulan Ini',
              '${s.laporanBulanIni}',
              Icons.report_outlined,
              const Color(0xFFC62828),
              const Color(0xFFFFEBEE),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 20),
          const Text(
            'Status Ketahanan Kecamatan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          _statusBarCard(
              s.kecamatanAman, s.kecamatanWaspada, s.kecamatanKritis),
          const SizedBox(height: 20),
          _hargaBerasCard(s.avgHargaBeras, currencyFmt),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBarCard(int aman, int waspada, int kritis) {
    final total = aman + waspada + kritis;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (aman > 0)
                    Flexible(
                      flex: aman,
                      child:
                          Container(height: 16, color: const Color(0xFF2E7D32)),
                    ),
                  if (waspada > 0)
                    Flexible(
                      flex: waspada,
                      child:
                          Container(height: 16, color: const Color(0xFFFF8F00)),
                    ),
                  if (kritis > 0)
                    Flexible(
                      flex: kritis,
                      child:
                          Container(height: 16, color: const Color(0xFFC62828)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statusLegend('Aman', aman, const Color(0xFF2E7D32)),
              _statusLegend('Waspada', waspada, const Color(0xFFFF8F00)),
              _statusLegend('Kritis', kritis, const Color(0xFFC62828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusLegend(String label, int count, Color color) {
    return Column(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 4),
        Text('$count',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _hargaBerasCard(double avg, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Harga Rata-rata Beras (7 hari)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${fmt.format(avg)}/kg',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
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
          return _buildStatusList(ctx, state.items);
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
    if (items.isEmpty) {
      return const Center(
        child: Text('Belum ada data kecamatan',
            style: TextStyle(color: Colors.grey)),
      );
    }

    // Sort: kritis first, then waspada, then aman
    final sorted = [...items]..sort((a, b) {
        final order = {
          'kritis': 0,
          'waspada': 1,
          'aman': 2,
          'tidak_ada_data': 3
        };
        return (order[a.statusStok] ?? 4).compareTo(order[b.statusStok] ?? 4);
      });

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async => ctx.read<AnalyticsBloc>().add(LoadStatusPangan()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _statusTile(sorted[i]),
      ),
    );
  }

  Widget _statusTile(StatusPanganItem item) {
    final statusColor = _statusColor(item.statusStok);
    final statusLabel = _statusLabel(item.statusStok);
    final trendIcon = item.hargaTrend == 'NAIK'
        ? Icons.arrow_upward
        : item.hargaTrend == 'TURUN'
            ? Icons.arrow_downward
            : Icons.remove;
    final trendColor = item.hargaTrend == 'NAIK'
        ? Colors.red
        : item.hargaTrend == 'TURUN'
            ? Colors.green
            : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.kecamatanNama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stok ${item.stokPersen.toStringAsFixed(1)}%',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.stokPersen / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      'Harga ${item.hargaTrend}',
                      style: TextStyle(
                          fontSize: 12,
                          color: trendColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            if (item.jumlahLaporanAktif > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.report_outlined,
                      size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    '${item.jumlahLaporanAktif} laporan aktif',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
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
