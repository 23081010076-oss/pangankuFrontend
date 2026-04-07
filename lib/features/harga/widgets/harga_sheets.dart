part of '../pages/harga_page.dart';

class _HargaDetailSheet extends StatefulWidget {
  final HargaItem item;
  final HargaLoaded initialState;

  const _HargaDetailSheet({
    required this.item,
    required this.initialState,
  });

  @override
  State<_HargaDetailSheet> createState() => _HargaDetailSheetState();
}

class _HargaDetailSheetState extends State<_HargaDetailSheet> {
  String _periode = '30d';

  @override
  void initState() {
    super.initState();
    context.read<HargaBloc>().add(
          LoadHargaTrend(
            komoditasId: widget.item.komoditasId,
            periode: _periode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocBuilder<HargaBloc, HargaState>(
          builder: (ctx, state) {
            final loaded = state is HargaLoaded ? state : widget.initialState;
            final trendData =
                loaded.selectedKomoditas == widget.item.komoditasId
                    ? loaded.trendData
                    : null;
            final isLoading = state is HargaLoading;

            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                Row(
                  children: [
                    Text(
                      widget.item.komoditasNama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _trendBadge(widget.item.trend),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp ${NumberFormat('#,###', 'id').format(widget.item.harga)}/kg  '
                  '\u{2022}  ${widget.item.kecamatanNama.isEmpty ? 'Semua kecamatan' : widget.item.kecamatanNama}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Tren Harga',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ...['7d', '30d', '90d'].map(
                      (p) => GestureDetector(
                        onTap: () {
                          setState(() => _periode = p);
                          ctx.read<HargaBloc>().add(
                                LoadHargaTrend(
                                  komoditasId: widget.item.komoditasId,
                                  periode: p,
                                ),
                              );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _periode == p
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _periode == p
                                  ? Colors.white
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                else if (trendData != null && trendData.isNotEmpty)
                  _buildTrendChart(trendData)
                else
                  SizedBox(
                    height: 140,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.show_chart,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tidak ada data trend',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _trendBadge(String trend) {
    final color = trend == 'NAIK'
        ? const Color(0xFFC62828)
        : trend == 'TURUN'
            ? const Color(0xFF2E7D32)
            : Colors.grey;
    final bg = trend == 'NAIK'
        ? const Color(0xFFFFEBEE)
        : trend == 'TURUN'
            ? const Color(0xFFE8F5E9)
            : Colors.grey[100]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        trend,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<TrendData> data) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.avg))
        .toList();
    if (spots.isEmpty) return const SizedBox();
    final allY = data.map((d) => d.avg).toList();
    final minY = (allY.reduce((a, b) => a < b ? a : b)) * 0.97;
    final maxY = (allY.reduce((a, b) => a > b ? a : b)) * 1.03;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E293B).withValues(alpha: 0.9),
              tooltipRoundedRadius: 10,
              fitInsideHorizontally: true,
              tooltipBorder: const BorderSide(color: Colors.white24, width: 1),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  if (idx < 0 || idx >= data.length) return null;
                  final dt = DateTime.tryParse(data[idx].tanggal);
                  final label = dt != null ? DateFormat('dd/MM').format(dt) : '';
                  return LineTooltipItem(
                    '$label\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'Rp ${NumberFormat('#,###', 'id_ID').format(spot.y)}',
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
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: Colors.grey.withValues(alpha: 0.15),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, meta) {
                  if (v == meta.max || v == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${(v / 1000).toStringAsFixed(0)}rb',
                    style: const TextStyle(
                      fontSize: 9, 
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (data.length / 5).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= data.length) return const SizedBox();
                  final dt = DateTime.tryParse(data[idx].tanggal);
                  if (dt == null) return const SizedBox();
                  return Text(
                    DateFormat('dd/MM').format(dt),
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: const Color(0xFF2E7D32),
              barWidth: 3,
              isStrokeCapRound: true,
              shadow: BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2E7D32).withValues(alpha: 0.35),
                    const Color(0xFF2E7D32).withValues(alpha: 0.0),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (spots.length > 30 && index % 3 != 0 && index != spots.length - 1 && index != 0) {
                    return FlDotCirclePainter(radius: 0, color: Colors.transparent, strokeWidth: 0);
                  }
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: const Color(0xFF2E7D32),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tambah Harga Sheet ────────────────────────────────────
class _TambahHargaSheet extends StatefulWidget {
  const _TambahHargaSheet();

  @override
  State<_TambahHargaSheet> createState() => _TambahHargaSheetState();
}

class _TambahHargaSheetState extends State<_TambahHargaSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selKomoditas;
  String? _selKecamatan;
  final _hargaCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  bool _loadingOpts = true;
  List<Map<String, dynamic>> _komList = [];
  List<Map<String, dynamic>> _kecList = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _hargaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final repository = context.read<MasterDataRepository>();
      final res = await Future.wait([
        repository.fetchKomoditas(),
        repository.fetchKecamatan(),
      ]);
      if (mounted) {
        setState(() {
          _komList = res[0];
          _kecList = res[1];
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
              'Tambah Data Harga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingOpts)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
              )
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selKomoditas,
                      decoration: InputDecoration(
                        labelText: 'Komoditas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: _komList
                          .map(
                            (k) => DropdownMenuItem(
                              value: k['id']?.toString(),
                              child: Text(k['nama']?.toString() ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selKomoditas = v),
                      validator: (v) => v == null ? 'Pilih komoditas' : null,
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
                    TextFormField(
                      controller: _hargaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Harga per kg',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Masukkan harga';
                        }
                        if (double.tryParse(v) == null ||
                            double.parse(v) <= 0) {
                          return 'Harga tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggal,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _tanggal = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                        ),
                        child: Text(
                          DateFormat('dd MMMM yyyy', 'id').format(_tanggal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<HargaBloc, HargaState>(
                      builder: (ctx, bstate) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: bstate is HargaCreating
                              ? null
                              : () => _submit(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: bstate is HargaCreating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
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
    // Untuk tanggal hari ini gunakan timestamp saat ini (UTC),
    // agar entry baru selalu jadi yang paling terbaru di /harga/latest.
    // Untuk tanggal lampau gunakan T23:59:59Z supaya terbaru di hari itu.
    final now = DateTime.now();
    final isToday = _tanggal.year == now.year &&
        _tanggal.month == now.month &&
        _tanggal.day == now.day;
    final tanggalUtc = isToday
        ? now.toUtc().toIso8601String()
        : '${DateFormat('yyyy-MM-dd').format(_tanggal)}T23:59:59Z';

    ctx.read<HargaBloc>().add(
          CreateHarga(
            komoditasId: _selKomoditas!,
            kecamatanId: _selKecamatan!,
            hargaPerKg: double.parse(_hargaCtrl.text.replaceAll(',', '.')),
            tanggal: tanggalUtc,
          ),
        );
    Navigator.of(ctx).pop();
  }
}

