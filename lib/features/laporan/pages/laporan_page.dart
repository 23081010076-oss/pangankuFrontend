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
import '../../../core/repositories/kecamatan_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part '../widgets/laporan_sheet.dart';

part '../widgets/laporan_sections.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _periodeTren = 'Minggu';

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
              BlocBuilder<LaporanBloc, LaporanState>(
                builder: (lCtx, lState) {
                  final items = lState is LaporanLoaded
                      ? lState.laporanList
                      : <LaporanItem>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tren Laporan',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF424242),),
                          ),
                          DropdownButton<String>(
                            value: _periodeTren,
                            isDense: true,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2E7D32), size: 20),
                            items: ['Minggu', 'Bulan', 'Tahun']
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text('Per $e'),
                                    ),)
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _periodeTren = v);
                            },
                          ),
                        ],
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
    int count = 7;
    List<DateTime> ranges = [];
    List<String> labels = [];

    if (_periodeTren == 'Minggu') {
      count = 7;
      for (int i = 0; i < count; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        ranges.add(DateTime(d.year, d.month, d.day));
        labels.add(DateFormat('dd/MM').format(d));
      }
    } else if (_periodeTren == 'Bulan') {
      count = 4;
      for (int i = 0; i < count; i++) {
        final d = now.subtract(Duration(days: (3 - i) * 7));
        ranges.add(DateTime(d.year, d.month, d.day));
        labels.add('M${i+1}');
      }
    } else if (_periodeTren == 'Tahun') {
      count = 6;
      for (int i = 0; i < count; i++) {
        final d = DateTime(now.year, now.month - (count - 1 - i), 1);
        ranges.add(DateTime(d.year, d.month, 1));
        labels.add(DateFormat('MMM').format(d));
      }
    }

    final baruCounts = List<double>.filled(count, 0);
    final prosesCounts = List<double>.filled(count, 0);
    final selesaiCounts = List<double>.filled(count, 0);

    for (final item in items) {
      final tanggal = DateTime.tryParse(item.tanggal);
      if (tanggal == null) continue;
      
      int index = -1;
      if (_periodeTren == 'Minggu') {
        final dayOnly = DateTime(tanggal.year, tanggal.month, tanggal.day);
        index = ranges.indexWhere((d) => d == dayOnly);
      } else if (_periodeTren == 'Bulan') {
        final diff = now.difference(tanggal).inDays;
        if (diff >= 0 && diff < 28) {
          int weekDiff = diff ~/ 7;
          index = 3 - weekDiff; 
        }
      } else if (_periodeTren == 'Tahun') {
        for(int i = 0; i < count; i++) {
           if(tanggal.year == ranges[i].year && tanggal.month == ranges[i].month) {
             index = i; break;
           }
        }
      }

      if (index != -1 && index >= 0 && index < count) {
        if (item.status == 'baru') {
          baruCounts[index]++;
        } else if (item.status == 'proses') {
          prosesCounts[index]++;
        } else if (item.status == 'selesai') {
          selesaiCounts[index]++;
        }
      }
    }

    final allValues = [...baruCounts, ...prosesCounts, ...selesaiCounts];
    final maxY = allValues.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
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
                      count,
                      (i) => FlSpot(i.toDouble(), baruCounts[i]),
                    ),
                    color: const Color(0xFFC62828),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFC62828).withValues(alpha: 0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      count,
                      (i) => FlSpot(i.toDouble(), prosesCounts[i]),
                    ),
                    color: const Color(0xFFF57C00),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF57C00).withValues(alpha: 0.06),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                      count,
                      (i) => FlSpot(i.toDouble(), selesaiCounts[i]),
                    ),
                    color: const Color(0xFF2E7D32),
                    isCurved: true,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
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
        onPressed: () => _exportToPdf(stats, laporan, _periodeTren),
        icon: const Icon(
          Icons.print_outlined,
          color: Color(0xFF2E7D32),
        ),
        label: const Text(
          'Cetak PDF Analitik & Laporan',
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
    String periodeTren,
  ) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);
    const headerBg = PdfColor(46 / 255, 125 / 255, 50 / 255);
    const accentBlue = PdfColor(25 / 255, 118 / 255, 210 / 255);

    int count = 7;
    List<DateTime> ranges = [];
    List<String> labels = [];

    if (periodeTren == 'Minggu') {
      count = 7;
      for (int i = 0; i < count; i++) {
        final d = now.subtract(Duration(days: 6 - i));
        ranges.add(DateTime(d.year, d.month, d.day));
        labels.add(DateFormat('dd/MM').format(d));
      }
    } else if (periodeTren == 'Bulan') {
      count = 4;
      for (int i = 0; i < count; i++) {
        final d = now.subtract(Duration(days: (3 - i) * 7));
        ranges.add(DateTime(d.year, d.month, d.day));
        labels.add('M${i+1}');
      }
    } else if (periodeTren == 'Tahun') {
      count = 6;
      for (int i = 0; i < count; i++) {
        final d = DateTime(now.year, now.month - (count - 1 - i), 1);
        ranges.add(d);
        labels.add(DateFormat('MMM').format(d));
      }
    }

    final baruCounts = List<double>.filled(count, 0);
    final prosesCounts = List<double>.filled(count, 0);
    final selesaiCounts = List<double>.filled(count, 0);

    for (final item in laporan) {
      final tanggal = DateTime.tryParse(item.tanggal);
      if (tanggal == null) continue;
      
      int index = -1;
      if (periodeTren == 'Minggu') {
        final dayOnly = DateTime(tanggal.year, tanggal.month, tanggal.day);
        index = ranges.indexWhere((d) => d == dayOnly);
      } else if (periodeTren == 'Bulan') {
        final diff = now.difference(tanggal).inDays;
        if (diff >= 0 && diff < 28) {
          int weekDiff = diff ~/ 7;
          index = 3 - weekDiff; 
        }
      } else if (periodeTren == 'Tahun') {
        for(int i = 0; i < count; i++) {
           if(tanggal.year == ranges[i].year && tanggal.month == ranges[i].month) {
             index = i; break;
           }
        }
      }

      if (index != -1 && index >= 0 && index < count) {
        if (item.status == 'baru') {
          baruCounts[index]++;
        } else if (item.status == 'proses') {
          prosesCounts[index]++;
        } else if (item.status == 'selesai') {
          selesaiCounts[index]++;
        }
      }
    }

    List<List<String>> trendRows = [];
    for(int i=0; i<count; i++) {
        trendRows.add([labels[i], baruCounts[i].toInt().toString(), prosesCounts[i].toInt().toString(), selesaiCounts[i].toInt().toString()]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
              color: headerBg,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
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
              ['Total Laporan Bulan Ini', '${stats.laporanBulanIni}'],
              ['Kecamatan Aman', '${stats.kecamatanAman}'],
              ['Kecamatan Waspada', '${stats.kecamatanWaspada}'],
              ['Kecamatan Kritis', '${stats.kecamatanKritis}'],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: headerBg),
            border: pw.TableBorder.all(),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            cellHeight: 22,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Tren Laporan per $periodeTren',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Periode', 'Baru', 'Proses', 'Selesai'],
            data: trendRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: accentBlue),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 20,
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
              headerDecoration: const pw.BoxDecoration(color: headerBg),
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
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  // ── KPI Card ────────────────────────────────────────────────
  Widget _kpiCard(
      String label, String value, IconData icon, Color color, Color bg,) {
    return Expanded(
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12),),
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

}
