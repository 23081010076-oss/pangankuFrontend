// Doc:
// Tujuan: Menyimpan builder hasil forecast seperti hero, statistik, chart, tabel, dan state kosong/error.
// Dipakai oleh: ForecastPage melalui part of forecast_page.dart.
// Dependensi utama: fl_chart, intl NumberFormat, state lokal _ForecastPageState.
// Fungsi public/utama: _buildHeroCard, _buildStatsGrid, _buildChart, _buildPredictionTable, _buildErrorCard, _buildEmptyState.
// Side effect penting: Tidak ada side effect I/O; hanya render hasil prediksi dari state halaman.
part of 'forecast_page.dart';

extension _ForecastResultSection on _ForecastPageState {
  Widget _buildHeroCard() {
    final isNaik = _trend == 'NAIK';
    final isTurun = _trend == 'TURUN';
    final color = isNaik
        ? const Color(0xFFC62828)
        : isTurun
            ? const Color(0xFF2E7D32)
            : const Color(0xFFF57C00);
    final icon = isNaik
        ? Icons.trending_up
        : isTurun
            ? Icons.trending_down
            : Icons.trending_flat;
    final label = isNaik
        ? 'Harga diperkirakan meningkat'
        : isTurun
            ? 'Harga diperkirakan menurun'
            : 'Harga diperkirakan relatif stabil';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF163B1B),
            const Color(0xFF245F2A),
            color.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedKomoditasName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _selectedKecamatanName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_changePercent != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_changePercent! > 0 ? '+' : ''}${_changePercent!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estimasi ini merangkum 7 hari ke depan agar perubahan harga lebih cepat terbaca sebelum masuk ke laporan detail.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final cards = [
      _StatCardData(
        label: 'Hari Pertama',
        value: 'Rp ${_currencyFmt.format(_predictions.first)}',
        icon: Icons.today_outlined,
        color: const Color(0xFF1565C0),
      ),
      _StatCardData(
        label: 'Hari Ketujuh',
        value: 'Rp ${_currencyFmt.format(_predictions.last)}',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF2E7D32),
      ),
      _StatCardData(
        label: 'Rata-rata',
        value: 'Rp ${_currencyFmt.format(_avgPrediction)}',
        icon: Icons.analytics_outlined,
        color: const Color(0xFF6A1B9A),
      ),
      _StatCardData(
        label: 'Rentang',
        value:
            'Rp ${_currencyFmt.format(_minPrediction)} - ${_currencyFmt.format(_maxPrediction)}',
        icon: Icons.swap_vert_outlined,
        color: const Color(0xFFF57C00),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 580
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 3.8 : 2.2,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _buildStatCard(cards[index]),
        );
      },
    );
  }

  Widget _buildAnomalyCard() {
    final color =
        _hasAnomalies ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bg =
        _hasAnomalies ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final icon =
        _hasAnomalies ? Icons.warning_amber_rounded : Icons.verified_outlined;
    final title =
        _hasAnomalies ? 'Anomali Harga Terdeteksi' : 'Tidak Ada Anomali Harga';
    final subtitle = _hasAnomalies
        ? '$_anomalyCount data historis melewati ambang 2 standar deviasi.'
        : 'Data historis berada dalam batas variasi normal.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_anomalyCount titik',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),
                if (_hasAnomalies) ...[
                  const SizedBox(height: 12),
                  if (_anomalyDetails.isNotEmpty)
                    Column(
                      children: [
                        for (final detail in _anomalyDetails.take(3))
                          _anomalyDetailRow(detail, color),
                        if (_anomalyDetails.length > 3)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _anomalyMorePill(
                              _anomalyDetails.length - 3,
                              color,
                            ),
                          ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final index in _anomalyIndexes.take(6))
                          _anomalyIndexPill(index, color),
                        if (_anomalyIndexes.length > 6)
                          _anomalyMorePill(_anomalyIndexes.length - 6, color),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _anomalyDetailRow(Map<String, dynamic> detail, Color color) {
    final harga = (detail['harga_per_kg'] as num?)?.toDouble();
    final tanggal = _formatAnomalyDate(detail['tanggal']);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tanggal,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
          if (harga != null)
            Text(
              'Rp ${_currencyFmt.format(harga)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  String _formatAnomalyDate(dynamic rawDate) {
    final value = rawDate?.toString();
    if (value == null || value.isEmpty) {
      return 'Tanggal tidak tersedia';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return DateFormat('dd MMM yyyy', 'id').format(parsed);
  }

  Widget _anomalyIndexPill(int index, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        'Data #${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _anomalyMorePill(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        '+$count lainnya',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = _predictions
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = _predictions.reduce((a, b) => a < b ? a : b) * 0.97;
    final maxY = _predictions.reduce((a, b) => a > b ? a : b) * 1.03;
    final avgY = _avgPrediction;
    final totalDelta = _predictions.last - _predictions.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.show_chart,
                  color: Color(0xFF2E7D32),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Grafik Prediksi 7 Hari ke Depan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 6, bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chartInfoPill(
                  'Rentang Rp ${_currencyFmt.format(_minPrediction)} - ${_currencyFmt.format(_maxPrediction)}',
                  const Color(0xFF1565C0),
                ),
                _chartInfoPill(
                  'Rata-rata Rp ${_currencyFmt.format(avgY)}',
                  const Color(0xFF6A1B9A),
                ),
                _chartInfoPill(
                  '${totalDelta >= 0 ? 'Naik' : 'Turun'} Rp ${_currencyFmt.format(totalDelta.abs())}',
                  totalDelta >= 0
                      ? const Color(0xFFC62828)
                      : const Color(0xFF2E7D32),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (_predictions.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avgY,
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.55),
                      strokeWidth: 1.2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6A1B9A),
                        ),
                        labelResolver: (_) => 'Rata-rata',
                      ),
                    ),
                  ],
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    bottom: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
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
                          '${(value / 1000).toStringAsFixed(0)}rb',
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) {
                          return const SizedBox.shrink();
                        }
                        final day = DateTime.now()
                            .add(Duration(days: value.toInt() + 1));
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(day),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF2E7D32),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    shadow: BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final isEdge =
                            index == 0 || index == _predictions.length - 1;
                        return FlDotCirclePainter(
                          radius: isEdge ? 4.8 : 3,
                          color:
                              isEdge ? const Color(0xFF2E7D32) : Colors.white,
                          strokeWidth: isEdge ? 2.8 : 2,
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
                          const Color(0xFF2E7D32).withValues(alpha: 0.35),
                          const Color(0xFF2E7D32).withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF1E293B).withValues(alpha: 0.9),
                    tooltipRoundedRadius: 8,
                    fitInsideHorizontally: true,
                    tooltipBorder:
                        const BorderSide(color: Colors.white24, width: 1),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final day = DateTime.now()
                            .add(Duration(days: spot.spotIndex + 1));
                        return LineTooltipItem(
                          '${DateFormat('dd MMM', 'id').format(day)}\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Rp ${_currencyFmt.format(spot.y)}',
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

  Widget _chartInfoPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPredictionTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.table_rows_outlined,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rincian Prediksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tanggal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Prediksi Harga',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Arah',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_predictions.length, (i) {
            final day = DateTime.now().add(Duration(days: i + 1));
            final previous = i == 0 ? _predictions[i] : _predictions[i - 1];
            final current = _predictions[i];
            final isUp = current > previous;
            final isDown = current < previous;
            final statusColor = isUp
                ? const Color(0xFFC62828)
                : isDown
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFF57C00);
            final statusIcon = isUp
                ? Icons.north_east_rounded
                : isDown
                    ? Icons.south_east_rounded
                    : Icons.remove_rounded;
            final statusLabel = i == 0
                ? 'Basis'
                : isUp
                    ? 'Naik'
                    : isDown
                        ? 'Turun'
                        : 'Stabil';

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEE', 'id').format(day),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy', 'id').format(day),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Rp ${_currencyFmt.format(current)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _predictions.length - 1)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
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
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_graph, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 14),
          const Text(
            'Belum ada prediksi yang ditampilkan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih komoditas lalu tekan "Lihat Prediksi" untuk menampilkan grafik dan rincian estimasi harga.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
