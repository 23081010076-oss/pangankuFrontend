import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/laporan_bloc.dart';
import '../bloc/laporan_event.dart';
import '../bloc/laporan_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../analytics/bloc/analytics_bloc.dart';
import '../../analytics/bloc/analytics_event.dart';
import '../../analytics/bloc/analytics_state.dart';
import '../../../core/network/dio_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    context.read<LaporanBloc>().add(LoadLaporanList());
    context.read<AnalyticsBloc>().add(LoadDashboardStats());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LaporanBloc, LaporanState>(
      listener: (ctx, state) {
        if (state is LaporanCreated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Laporan berhasil dibuat'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        } else if (state is LaporanStatusUpdated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Status laporan diperbarui'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        } else if (state is LaporanDeleted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Laporan dihapus'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        } else if (state is LaporanError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        floatingActionButton: _buildFAB(context),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPersistentHeader(
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabCtrl,
                  labelColor: const Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2E7D32),
                  tabs: const [
                    Tab(text: 'Ringkasan'),
                    Tab(text: 'Laporan Darurat'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildRingkasan(context),
              _buildLaporanList(context),
            ],
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
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan & Analitik',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Informasi ketahanan pangan Kabupaten Lamongan',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingkasan(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (ctx, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (state is AnalyticsError) {
          return Center(child: Text(state.message));
        }
        if (state is AnalyticsLoaded) {
          final s = state.stats;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Statistik Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
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
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _kpiCard(
                    'Distribusi Aktif',
                    '${s.distribusiAktif}',
                    Icons.local_shipping_outlined,
                    Colors.blue,
                    Colors.blue.shade50,
                  ),
                  const SizedBox(width: 10),
                  _kpiCard(
                    'Laporan Bulan Ini',
                    '${s.laporanBulanIni}',
                    Icons.report_outlined,
                    const Color(0xFFC62828),
                    const Color(0xFFFFEBEE),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Status Kecamatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              _statusBar(
                  s.kecamatanAman, s.kecamatanWaspada, s.kecamatanKritis),
              const SizedBox(height: 20),
              const Text(
                'Rata-rata Harga Komoditas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  _hargaCard(
                    '🌾',
                    'Beras',
                    s.avgHargaBeras,
                    const Color(0xFF2E7D32),
                    const Color(0xFFE8F5E9),
                  ),
                  _hargaCard(
                    '🌽',
                    'Jagung',
                    s.avgHargaJagung,
                    const Color(0xFFF9A825),
                    const Color(0xFFFFFDE7),
                  ),
                  _hargaCard(
                    '🫘',
                    'Kedelai',
                    s.avgHargaKedelai,
                    const Color(0xFF795548),
                    const Color(0xFFEFEBE9),
                  ),
                  _hargaCard(
                    '🌶️',
                    'Cabai Merah',
                    s.avgHargaCabai,
                    const Color(0xFFC62828),
                    const Color(0xFFFFEBEE),
                  ),
                  _hargaCard(
                    '🍚',
                    'Gula Pasir',
                    s.avgHargaGula,
                    const Color(0xFF1976D2),
                    const Color(0xFFE3F2FD),
                  ),
                  _hargaCard(
                    '🫙',
                    'Minyak Goreng',
                    s.avgHargaMinyak,
                    const Color(0xFFF57C00),
                    const Color(0xFFFFF3E0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              BlocBuilder<LaporanBloc, LaporanState>(
                builder: (lCtx, lState) {
                  final items = lState is LaporanLoaded
                      ? lState.laporanList
                      : <LaporanItem>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tren Laporan 7 Hari Terakhir',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF424242)),
                      ),
                      const SizedBox(height: 12),
                      _buildTrenChart(items),
                      const SizedBox(height: 16),
                      _buildCetakPdfButton(s, items),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  // ── Line Chart ─────────────────────────────────────────────
  Widget _buildTrenChart(List<LaporanItem> items) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final baruCounts = List<double>.filled(7, 0);
    final prosesCounts = List<double>.filled(7, 0);
    final selesaiCounts = List<double>.filled(7, 0);

    for (final item in items) {
      final tanggal = DateTime.tryParse(item.tanggal);
      if (tanggal == null) continue;
      final dayOnly = DateTime(tanggal.year, tanggal.month, tanggal.day);
      for (int i = 0; i < days.length; i++) {
        if (dayOnly == days[i]) {
          if (item.status == 'baru') {
            baruCounts[i]++;
          } else if (item.status == 'proses') {
            prosesCounts[i]++;
          } else if (item.status == 'selesai') {
            selesaiCounts[i]++;
          }
          break;
        }
      }
    }

    final labels = days.map((d) => DateFormat('dd/MM').format(d)).toList();
    final allValues = [...baruCounts, ...prosesCounts, ...selesaiCounts];
    final maxY = allValues.fold(0.0, (a, b) => a > b ? a : b);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chartLegend('Baru', const Color(0xFFC62828)),
              const SizedBox(width: 16),
              _chartLegend('Proses', const Color(0xFFF57C00)),
              const SizedBox(width: 16),
              _chartLegend('Selesai', const Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY < 1 ? 3 : maxY + 1,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF0F0F0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2E7D32),
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
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), baruCounts[i]),
                    ),
                    color: const Color(0xFFC62828),
                    isCurved: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFC62828).withOpacity(0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), prosesCounts[i]),
                    ),
                    color: const Color(0xFFF57C00),
                    isCurved: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF57C00).withOpacity(0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      7,
                      (i) => FlSpot(i.toDouble(), selesaiCounts[i]),
                    ),
                    color: const Color(0xFF2E7D32),
                    isCurved: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2E7D32).withOpacity(0.06),
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

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCetakPdfButton(DashboardStats stats, List<LaporanItem> laporan) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _exportToPdf(stats, laporan),
        icon: const Icon(
          Icons.print_outlined,
          color: Color(0xFF2E7D32),
        ),
        label: const Text(
          'Cetak PDF Laporan',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFF2E7D32),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _exportToPdf(
    DashboardStats stats,
    List<LaporanItem> laporan,
  ) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);
    final headerBg = PdfColor(46 / 255, 125 / 255, 50 / 255);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: headerBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KETAHANAN PANGAN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Kabupaten Lamongan - $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ringkasan Statistik',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Indikator', 'Nilai'],
            data: [
              ['Total Komoditas', '${stats.totalKomoditas}'],
              ['Alert Aktif', '${stats.alertCount}'],
              ['Distribusi Aktif', '${stats.distribusiAktif}'],
              ['Laporan Bulan Ini', '${stats.laporanBulanIni}'],
              ['Update Hari Ini', '${stats.updateHariIni}'],
              [
                'Harga Rata-rata Beras',
                'Rp ${NumberFormat('#,###').format(stats.avgHargaBeras)}/kg',
              ],
              ['Kecamatan Aman', '${stats.kecamatanAman}'],
              ['Kecamatan Waspada', '${stats.kecamatanWaspada}'],
              ['Kecamatan Kritis', '${stats.kecamatanKritis}'],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: headerBg),
            border: pw.TableBorder.all(),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            cellHeight: 22,
          ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Daftar Laporan Darurat',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (laporan.isEmpty)
            pw.Text(
              'Belum ada laporan darurat.',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'No',
                'Jenis Masalah',
                'Kecamatan',
                'Status',
                'Prio',
                'Tanggal',
              ],
              data: laporan.asMap().entries.map((e) {
                final item = e.value;
                final tgl = DateTime.tryParse(item.tanggal);
                return [
                  '${e.key + 1}',
                  item.jenisMasalah,
                  item.kecamatanNama,
                  item.status.toUpperCase(),
                  '${item.prioritas}',
                  tgl != null ? DateFormat('dd/MM/yy').format(tgl) : '-',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: headerBg),
              border: pw.TableBorder.all(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.FixedColumnWidth(22),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(52),
                4: const pw.FixedColumnWidth(28),
                5: const pw.FixedColumnWidth(52),
              },
              cellHeight: 20,
            ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Dicetak pada: $dateStr',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // ── KPI Card ────────────────────────────────────────────────
  Widget _hargaCard(
    String emoji,
    String nama,
    double harga,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Text(
                  harga > 0
                      ? 'Rp ${NumberFormat('#,###', 'id').format(harga.round())}'
                      : 'Belum ada data',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: harga > 0 ? color : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
      String label, String value, IconData icon, Color color, Color bg) {
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBar(int aman, int waspada, int kritis) {
    final total = aman + waspada + kritis;
    if (total == 0) return const SizedBox();
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
          Row(
            children: [
              Expanded(
                flex: aman,
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: waspada,
                child: Container(
                  height: 12,
                  color: const Color(0xFFF57C00),
                ),
              ),
              Expanded(
                flex: kritis,
                child: Container(
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC62828),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendDot('\u2022 $aman Aman', const Color(0xFF2E7D32)),
              _legendDot('\u2022 $waspada Waspada', const Color(0xFFF57C00)),
              _legendDot('\u2022 $kritis Kritis', const Color(0xFFC62828)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildLaporanList(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final canEdit = role == 'admin' || role == 'petugas';

    return BlocBuilder<LaporanBloc, LaporanState>(
      builder: (ctx, state) {
        if (state is LaporanLoading || state is LaporanSubmitting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (state is LaporanError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFEF5350)),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      ctx.read<LaporanBloc>().add(LoadLaporanList()),
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF2E7D32),
                  ),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is LaporanLoaded) {
          if (state.laporanList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan darurat',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async =>
                ctx.read<LaporanBloc>().add(RefreshLaporan()),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: state.laporanList.length,
              itemBuilder: (_, i) =>
                  _buildLaporanCard(ctx, state.laporanList[i], canEdit),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildLaporanCard(
    BuildContext ctx,
    LaporanItem item,
    bool canEdit,
  ) {
    final statusColor = item.status == 'selesai'
        ? const Color(0xFF2E7D32)
        : item.status == 'proses'
            ? Colors.orange
            : const Color(0xFFC62828);
    final statusBg = item.status == 'selesai'
        ? const Color(0xFFE8F5E9)
        : item.status == 'proses'
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFFFEBEE);

    final tanggal = DateTime.tryParse(item.tanggal);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.jenisMasalah,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.kecamatanNama,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (item.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 13,
                  color: i < item.prioritas ? Colors.amber : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Prioritas ${item.prioritas}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
              if (tanggal != null)
                Text(
                  DateFormat('dd/MM/yy').format(tanggal),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusDropdown(ctx, item),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(ctx, item.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Color(0xFFC62828),
                  ),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC62828),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusDropdown(BuildContext ctx, LaporanItem item) {
    const statuses = ['baru', 'proses', 'selesai'];
    return DropdownButton<String>(
      value: statuses.contains(item.status) ? item.status : 'baru',
      isDense: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 12, color: Color(0xFF212121)),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (newStatus) {
        if (newStatus != null && newStatus != item.status) {
          ctx.read<LaporanBloc>().add(
                UpdateLaporanStatus(id: item.id, status: newStatus),
              );
        }
      },
    );
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<LaporanBloc>().add(DeleteLaporan(id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateLaporan(context),
      label: const Text('Buat Laporan'),
      icon: const Icon(Icons.add),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    );
  }

  void _showCreateLaporan(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<LaporanBloc>(),
        child: const _CreateLaporanSheet(),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Container(color: Colors.white, child: _tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ── Create Laporan Sheet ──────────────────────────────────
class _CreateLaporanSheet extends StatefulWidget {
  const _CreateLaporanSheet();

  @override
  State<_CreateLaporanSheet> createState() => _CreateLaporanSheetState();
}

class _CreateLaporanSheetState extends State<_CreateLaporanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _jenisMasalahCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  String? _selKecamatan;
  int _prioritas = 3;
  bool _loadingOpts = true;
  List<Map<String, dynamic>> _kecList = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _jenisMasalahCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final res = await DioClient().dio.get('/kecamatan');
      if (mounted) {
        setState(() {
          _kecList = List<Map<String, dynamic>>.from(
            res.data is Map ? (res.data['data'] ?? res.data) : res.data,
          );
          _loadingOpts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOpts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buat Laporan Darurat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingOpts)
              const CircularProgressIndicator(color: Color(0xFF2E7D32))
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _jenisMasalahCtrl,
                      decoration: InputDecoration(
                        labelText: 'Jenis Masalah',
                        hintText: 'mis. Kekurangan beras',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Masukkan jenis masalah' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Masukkan deskripsi' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selKecamatan,
                      decoration: InputDecoration(
                        labelText: 'Kecamatan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: _kecList
                          .map(
                            (k) => DropdownMenuItem(
                              value: k['id']?.toString(),
                              child: Text(k['nama']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selKecamatan = v),
                      validator: (v) => v == null ? 'Pilih kecamatan' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Prioritas: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        ...List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _prioritas = i + 1),
                            child: Icon(
                              Icons.star,
                              color: i < _prioritas
                                  ? Colors.amber
                                  : Colors.grey[300],
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_prioritas',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<LaporanBloc, LaporanState>(
                      builder: (ctx, bstate) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: bstate is LaporanSubmitting
                              ? null
                              : () => _submit(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: bstate is LaporanSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kirim Laporan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<LaporanBloc>().add(
          CreateLaporan(
            jenisMasalah: _jenisMasalahCtrl.text.trim(),
            deskripsi: _deskripsiCtrl.text.trim(),
            kecamatanId: _selKecamatan!,
            prioritas: _prioritas,
          ),
        );
    Navigator.of(ctx).pop();
  }
}
