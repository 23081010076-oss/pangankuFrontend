// Doc:
// Tujuan: Menyimpan panel studio harga komoditas untuk dashboard beranda dengan gambar komoditas, ringkasan tren, dan chart interaktif.
// Dipakai oleh: _HomePage._buildChartCard melalui part of dashboard_page.dart.
// Dependensi utama: AnalyticsBloc state, AppConstants, fl_chart, data DashboardStats.
// Fungsi public/utama: _ChartCardWidget, _ChartCardWidgetState, _getData, _commodityIcon, _commodityImage, _formatCompact, _miniInsightChip.
// Side effect penting: Dispatch LoadDashboardStats saat periode chart diganti; render gambar via HTTP Image.network jika gambar_url tersedia.
part of '../pages/dashboard_page.dart';

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

  static const _komoditasColors = [
    Color(0xFF2E7D32),
    Color(0xFFF9A825),
    Color(0xFF795548),
    Color(0xFFC62828),
    Color(0xFF1976D2),
    Color(0xFFF57C00),
  ];

  static const _komoditasIcons = {
    'Beras': Icons.rice_bowl_rounded,
    'Jagung': Icons.grass_rounded,
    'Kedelai': Icons.spa_rounded,
    'Cabai Merah': Icons.local_fire_department_rounded,
    'Bawang Merah': Icons.local_florist_rounded,
    'Gula Pasir': Icons.cookie_rounded,
    'Minyak Goreng': Icons.water_drop_rounded,
    'Daging Ayam': Icons.restaurant_rounded,
    'Telur Ayam': Icons.egg_alt_rounded,
  };

  List<double> _getData(DashboardStats? stats) {
    if (stats == null || stats.komoditasTrend.isEmpty) {
      return List.filled(7, 0.0);
    }
    final index = _selectedIdx % stats.komoditasTrend.length;
    return stats.komoditasTrend[index].hargaHarian;
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

  String _normalizeImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = Uri.parse(AppConstants.baseUrl);
    final origin = '${base.scheme}://${base.authority}';
    return '$origin/${trimmed.replaceFirst(RegExp(r'^/+'), '')}';
  }

  IconData _commodityIcon(String name) {
    return _komoditasIcons[name] ?? Icons.eco_rounded;
  }

  Widget _commodityImage(
    String name,
    String rawUrl, {
    required Color color,
    required bool isSelected,
  }) {
    final imageUrl = _normalizeImageUrl(rawUrl);
    final fallback = Icon(
      _commodityIcon(name),
      size: 14,
      color: isSelected ? color : const Color(0xFF6B7280),
    );

    if (imageUrl.isEmpty) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 18,
        height: 18,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final stats = state is AnalyticsLoaded ? state.stats : null;
    final activeColor =
        _komoditasColors[_selectedIdx % _komoditasColors.length];
    final data = _getData(stats);
    final labels = stats?.tanggalLabels ?? const [];
    final axisLabels = labels.isEmpty
        ? List<String>.generate(data.length, (i) => 'H${i + 1}')
        : labels;
    final showEvery =
        axisLabels.length > 10 ? (axisLabels.length / 6).ceil() : 1;
    final spots = data
        .asMap()
        .entries
        .where((entry) => entry.value > 0)
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    final values = spots.map((entry) => entry.y).toList();
    final minRaw = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxRaw = values.isEmpty ? 1.0 : values.reduce(math.max);
    final span = (maxRaw - minRaw).abs();
    final padding = span > 0 ? span * 0.18 : (maxRaw > 0 ? maxRaw * 0.08 : 1.0);
    final chartMinY = math.max(0.0, minRaw - padding).toDouble();
    final chartMaxY = (maxRaw + padding).toDouble();
    final yInterval =
        ((chartMaxY - chartMinY) / 4).clamp(1, double.infinity).toDouble();
    final avgPrice =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

    double? percentChange;
    if (spots.length >= 2 && spots.first.y > 0) {
      percentChange = ((spots.last.y - spots.first.y) / spots.first.y) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCFCF7), Color(0xFFFFFFFF), Color(0xFFF6FBF7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1ECE4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Studio Harga Pangan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C2A22),
                          ),
                        ),
                        if (percentChange != null) ...[
                          const SizedBox(width: 8),
                          _trendPill(percentChange),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bandingkan ritme harga harian untuk memilih komoditas yang paling dinamis minggu ini.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6F1),
                  borderRadius: BorderRadius.circular(12),
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
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == _selectedPeriod) {
                        return;
                      }
                      setState(() => _selectedPeriod = value);
                      context.read<AnalyticsBloc>().add(
                            LoadDashboardStats(periode: value),
                          );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: stats?.komoditasTrend.length ?? 0,
              itemBuilder: (_, index) {
                final isSelected = _selectedIdx == index;
                final itemColor =
                    _komoditasColors[index % _komoditasColors.length];
                final item = stats!.komoditasTrend[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIdx = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? itemColor.withValues(alpha: 0.12)
                          : const Color(0xFFF6F6F3),
                      border: Border.all(
                        color: isSelected
                            ? itemColor.withValues(alpha: 0.35)
                            : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _commodityImage(
                          item.nama,
                          item.gambarUrl,
                          color: itemColor,
                          isSelected: isSelected,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.nama,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? itemColor
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (spots.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4ECE5)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _miniInsightChip(
                    'Rata-rata Rp ${_formatCompact(avgPrice)}',
                    const Color(0xFF3F6C51),
                  ),
                  _miniInsightChip(
                    'Terbaru Rp ${_formatCompact(values.last)}',
                    activeColor,
                  ),
                  _miniInsightChip(
                    'Rentang Rp ${_formatCompact(minRaw)} - ${_formatCompact(maxRaw)}',
                    const Color(0xFF5F6B76),
                  ),
                ],
              ),
            ),
          if (spots.isNotEmpty) const SizedBox(height: 14),
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
                      Icons.candlestick_chart_rounded,
                      size: 42,
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
            Container(
              padding: const EdgeInsets.fromLTRB(10, 16, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    activeColor.withValues(alpha: 0.08),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: activeColor.withValues(alpha: 0.14)),
              ),
              child: SizedBox(
                height: 164,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (axisLabels.length - 1).toDouble(),
                    minY: chartMinY,
                    maxY: chartMaxY,
                    clipData: const FlClipData.all(),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: avgPrice,
                          color:
                              const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          strokeWidth: 1.1,
                          dashArray: const [5, 5],
                        ),
                      ],
                    ),
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF163226),
                        tooltipRoundedRadius: 12,
                        fitInsideHorizontally: true,
                        tooltipBorder:
                            const BorderSide(color: Colors.white24, width: 1),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            final label =
                                (index >= 0 && index < axisLabels.length)
                                    ? axisLabels[index]
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
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFF9AA8A0).withValues(alpha: 0.18),
                        strokeWidth: 1,
                        dashArray: const [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max || value == meta.min) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              _formatCompact(value),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF7A8691),
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
                          interval: 1,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= axisLabels.length) {
                              return const SizedBox();
                            }
                            if (index % showEvery != 0 &&
                                index != axisLabels.length - 1) {
                              return const SizedBox();
                            }
                            return Text(
                              axisLabels[index],
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF7A8691),
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
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        gradient: LinearGradient(
                          colors: [
                            activeColor,
                            activeColor.withValues(alpha: 0.75),
                          ],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        shadow: BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              activeColor.withValues(alpha: 0.35),
                              activeColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            if (spots.length > 30 &&
                                index % 3 != 0 &&
                                index != spots.length - 1 &&
                                index != 0) {
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                              );
                            }
                            return FlDotCirclePainter(
                              radius: index == spots.length - 1 ? 5.2 : 3.4,
                              color: index == spots.length - 1
                                  ? activeColor
                                  : Colors.white,
                              strokeWidth: 2.2,
                              strokeColor: activeColor,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _trendPill(double percentChange) {
    final isUp = percentChange > 0;
    final isDown = percentChange < 0;
    final bg = isUp
        ? const Color(0xFFFFF0EE)
        : (isDown ? const Color(0xFFEAF7EE) : const Color(0xFFF3F4F6));
    final fg = isUp
        ? const Color(0xFFC2410C)
        : (isDown ? const Color(0xFF166534) : const Color(0xFF6B7280));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            isUp
                ? Icons.trending_up
                : (isDown ? Icons.trending_down : Icons.trending_flat),
            size: 10,
            color: fg,
          ),
          const SizedBox(width: 2),
          Text(
            '${percentChange.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInsightChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
