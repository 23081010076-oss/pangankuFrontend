// Doc:
// Tujuan: Menjadi shell halaman forecast harga dan mengelola state filter serta hasil prediksi.
// Dipakai oleh: Router/navigasi fitur harga menuju ForecastPage.
// Dependensi utama: HargaRepository, DioException, intl NumberFormat, part UI forecast.
// Fungsi public/utama: ForecastPage, _ForecastPageState lifecycle, _loadMeta, _loadForecast.
// Side effect penting: HTTP call via HargaRepository, baca metadata komoditas/kecamatan, dan tampilkan snackbar error input.
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../data/harga_repository.dart';

part 'forecast_filters_section.dart';
part 'forecast_result_section.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  late final HargaRepository _repository;
  final _currencyFmt = NumberFormat('#,###', 'id');

  List<Map<String, dynamic>> _komoditasList = [];
  List<Map<String, dynamic>> _kecamatanList = [];

  String? _selectedKomoditasId;
  String? _selectedKecamatanId;

  bool _loadingMeta = true;
  bool _loadingForecast = false;
  String? _error;

  List<double> _predictions = [];
  List<int> _anomalyIndexes = [];
  List<Map<String, dynamic>> _anomalyDetails = [];
  String _trend = '';

  String get _selectedKomoditasName {
    for (final item in _komoditasList) {
      if (item['id'] == _selectedKomoditasId) {
        return item['nama']?.toString() ?? 'Komoditas';
      }
    }
    return 'Komoditas';
  }

  String get _selectedKecamatanName {
    if (_selectedKecamatanId == null) {
      return 'Semua kecamatan';
    }
    for (final item in _kecamatanList) {
      if (item['id'] == _selectedKecamatanId) {
        return item['nama']?.toString() ?? 'Semua kecamatan';
      }
    }
    return 'Semua kecamatan';
  }

  double? get _changePercent {
    if (_predictions.length < 2 || _predictions.first <= 0) {
      return null;
    }
    return ((_predictions.last - _predictions.first) / _predictions.first) *
        100;
  }

  double get _avgPrediction {
    if (_predictions.isEmpty) {
      return 0;
    }
    return _predictions.reduce((a, b) => a + b) / _predictions.length;
  }

  double get _minPrediction =>
      _predictions.isEmpty ? 0 : _predictions.reduce(math.min);

  double get _maxPrediction =>
      _predictions.isEmpty ? 0 : _predictions.reduce(math.max);

  bool get _hasAnomalies => _anomalyIndexes.isNotEmpty;

  int get _anomalyCount => _anomalyIndexes.length;

  @override
  void initState() {
    super.initState();
    _repository = context.read<HargaRepository>();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    try {
      final results = await Future.wait([
        _repository.fetchKomoditas(),
        _repository.fetchKecamatan(),
      ]);

      setState(() {
        _komoditasList = results[0];
        _kecamatanList = results[1];
        _loadingMeta = false;
      });
    } catch (_) {
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
      _anomalyIndexes = [];
      _anomalyDetails = [];
    });

    try {
      final data = await _repository.fetchForecast(
        komoditasId: _selectedKomoditasId!,
        kecamatanId: _selectedKecamatanId,
      );
      setState(() {
        _predictions = List<double>.from(
          (data['predictions'] as List).map((v) => (v as num).toDouble()),
        );
        final rawAnomalies = data['anomaly_indexes'];
        _anomalyIndexes = rawAnomalies is List
            ? rawAnomalies
                .whereType<num>()
                .map((v) => v.toInt())
                .where((v) => v >= 0)
                .toList()
            : <int>[];
        final rawAnomalyDetails = data['anomaly_details'];
        _anomalyDetails = rawAnomalyDetails is List
            ? rawAnomalyDetails
                .whereType<Map>()
                .map((v) => Map<String, dynamic>.from(v))
                .toList()
            : <Map<String, dynamic>>[];
        _trend = data['trend'] as String? ?? '';
        _loadingForecast = false;
      });
    } on DioException catch (e) {
      final msg = _repository.getErrorMessage(
        e,
        fallback: 'Gagal memuat prediksi',
      );
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
                  fontWeight: FontWeight.w700,
                ),
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
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 980;

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 340,
                                child: _buildFilterCard(isWide: true),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: _buildContent()),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterCard(isWide: false),
                            const SizedBox(height: 20),
                            _buildContent(),
                          ],
                        );
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
}
