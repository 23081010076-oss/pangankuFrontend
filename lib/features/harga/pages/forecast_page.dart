import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  final _client = DioClient();
  final _currencyFmt = NumberFormat('#,###', 'id');

  List<Map<String, dynamic>> _komoditasList = [];
  List<Map<String, dynamic>> _kecamatanList = [];

  String? _selectedKomoditasId;
  String? _selectedKecamatanId;
  String _selectedKomoditasNama = '';

  bool _loadingMeta = true;
  bool _loadingForecast = false;
  String? _error;

  // Forecast result
  List<double> _predictions = [];
  String _trend = '';

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final results = await Future.wait([
        _client.dio.get('/komoditas'),
        _client.dio.get('/kecamatan'),
      ]);
      final komoditasRaw = results[0].data;
      final kecamatanRaw = results[1].data;

      setState(() {
        _komoditasList = List<Map<String, dynamic>>.from(
          komoditasRaw is List ? komoditasRaw : (komoditasRaw['data'] ?? []),
        );
        _kecamatanList = List<Map<String, dynamic>>.from(
          kecamatanRaw is List ? kecamatanRaw : (kecamatanRaw['data'] ?? []),
        );
        _loadingMeta = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data';
        _loadingMeta = false;
      });
    }
  }

  Future<void> _loadForecast() async {
    if (_selectedKomoditasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih komoditas terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _loadingForecast = true;
      _error = null;
      _predictions = [];
    });

    try {
      final queryParams = <String, String>{
        'komoditas_id': _selectedKomoditasId!,
        if (_selectedKecamatanId != null) 'kecamatan_id': _selectedKecamatanId!,
      };
      final res = await _client.dio.get(
        '/harga/forecast',
        queryParameters: queryParams,
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _predictions = List<double>.from(
          (data['predictions'] as List).map((v) => (v as num).toDouble()),
        );
        _trend = data['trend'] as String? ?? '';

        _loadingForecast = false;
      });
    } on DioException catch (e) {
      final msg = e.response?.data['error'] ?? 'Gagal memuat prediksi';
      setState(() {
        _error = msg;
        _loadingForecast = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Prediksi Harga',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF43A047),
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          if (_loadingMeta)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterCard(),
                    const SizedBox(height: 20),
                    if (_loadingForecast)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32)),
                        ),
                      )
                    else if (_error != null)
                      _buildErrorCard()
                    else if (_predictions.isNotEmpty) ...[
                      _buildTrendBadge(),
                      const SizedBox(height: 16),
                      _buildChart(),
                      const SizedBox(height: 16),
                      _buildPredictionTable(),
                    ] else
                      _buildEmptyState(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Prediksi',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedKomoditasId,
            decoration: InputDecoration(
              labelText: 'Komoditas *',
              prefixIcon: const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF2E7D32)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2E7D32), width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: const Text('Pilih komoditas'),
            items: _komoditasList
                .map((k) => DropdownMenuItem<String>(
                      value: k['id'] as String,
                      child: Text(k['nama'] as String? ?? ''),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedKomoditasId = v;
                _selectedKomoditasNama = _komoditasList.firstWhere(
                    (k) => k['id'] == v,
                    orElse: () => {'nama': ''})['nama'] as String;
                _predictions = [];
                _error = null;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedKecamatanId,
            decoration: InputDecoration(
              labelText: 'Kecamatan (opsional)',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF2E7D32)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF2E7D32), width: 2)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            hint: const Text('Semua kecamatan'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua kecamatan'),
              ),
              ..._kecamatanList.map((k) => DropdownMenuItem<String>(
                    value: k['id'] as String,
                    child: Text(k['nama'] as String? ?? ''),
                  ))
            ],
            onChanged: (v) {
              setState(() {
                _selectedKecamatanId = v;
                _predictions = [];
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loadingForecast ? null : _loadForecast,
              icon: const Icon(Icons.auto_graph, size: 18),
              label: const Text('Lihat Prediksi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isNaik = _trend == 'NAIK';
    final isTurun = _trend == 'TURUN';
    final color = isNaik
        ? Colors.red[700]!
        : isTurun
            ? const Color(0xFF2E7D32)
            : Colors.orange[700]!;
    final icon = isNaik
        ? Icons.trending_up
        : isTurun
            ? Icons.trending_down
            : Icons.trending_flat;
    final label = isNaik
        ? 'Tren Naik'
        : isTurun
            ? 'Tren Turun'
            : 'Stabil';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prediksi 7 Hari',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text(
                      ' — ',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final spots = _predictions.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final minY = _predictions.reduce((a, b) => a < b ? a : b) * 0.97;
    final maxY = _predictions.reduce((a, b) => a > b ? a : b) * 1.03;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 0, 12),
            child: Text(
              'Grafik Prediksi 7 Hari ke Depan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700]),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  drawVerticalLine: true,
                  getDrawingVerticalLine: (_) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          'rb',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = DateTime.now()
                            .add(Duration(days: value.toInt() + 1));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('dd/MM').format(day),
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF2E7D32),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF2E7D32),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2E7D32).withOpacity(0.35),
                          const Color(0xFF2E7D32).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF1E293B).withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,
                    tooltipBorder:
                        const BorderSide(color: Colors.white24, width: 1),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final day = DateTime.now()
                            .add(Duration(days: spot.spotIndex + 1));
                        return LineTooltipItem(
                          '\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Rp ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.table_rows_outlined,
                    size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(
                  'Rincian Prediksi',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Header
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: Text('Tanggal',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20)))),
                const Expanded(
                    flex: 3,
                    child: Text('Prediksi Harga',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20)),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20)),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...List.generate(_predictions.length, (i) {
            final day = DateTime.now().add(Duration(days: i + 1));

            return Column(
              children: [
                Container(
                  color: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          DateFormat('EEE, dd MMM', 'id').format(day),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Rp ${_currencyFmt.format(_predictions[i])}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: const Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _predictions.length - 1)
                  const Divider(
                      height: 1, indent: 16, color: Color(0xFFF0F0F0)),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (_error?.contains('historis tidak cukup') ?? false)
            Text(
              'Backend membutuhkan minimal 7 hari data historis untuk komoditas & kecamatan yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.auto_graph, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Pilih komoditas lalu tekan\n"Lihat Prediksi"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
