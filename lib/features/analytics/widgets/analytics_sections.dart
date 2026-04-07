part of '../pages/analytics_page.dart';

extension _AnalyticsPageSections on _AnalyticsPageState {
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
                    // ignore: invalid_use_of_protected_member
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
            style: TextStyle(color: Colors.grey),),
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
              style: TextStyle(color: Colors.grey),),
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
                      color: Colors.red.withValues(alpha: 0.6),
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
                      color: Colors.green.withValues(alpha: 0.6),
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
                gridData: const FlGridData(show: true, horizontalInterval: 20),
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
                          color: Colors.grey.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),),),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                            horizontal: 8, vertical: 3,),
                        decoration: BoxDecoration(
                          color: _statusColor(item.statusStok).withValues(alpha: 0.12),
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
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFE9EEF3),
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
                  color: Colors.black.withValues(alpha: 0.04),
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
}
