// Doc:
// Tujuan: Menyusun section utama tab analitik, terutama status pangan per kecamatan dan tren harga wilayah.
// Dipakai oleh: analytics_page.dart melalui part/extension _AnalyticsPageSections pada _AnalyticsPageState.
// Dependensi utama: AnalyticsBloc/AnalyticsState, model StatusPanganItem, fl_chart, helper warna/status di analytics page.
// Fungsi public/utama: _buildStatusPerKecamatanTab, _statusStatCard, _buildKecamatanStockLineChart, _stokRankRow, _buildStatusRankDropdown.
// Side effect penting: Trigger refresh BLoC event, membuka filter bottom sheet, render chart interaktif tanpa I/O langsung.
part of '../pages/analytics_page.dart';

extension _AnalyticsPageSections on _AnalyticsPageState {
  Widget _statusStatCard(String label, int count, Color color) {
    final icon = switch (label) {
      'Aman' => Icons.verified_rounded,
      'Waspada' => Icons.visibility_rounded,
      _ => Icons.warning_amber_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Text(
            '$count kec.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stokRankRow(StatusPanganItem item, int index, bool isLast) {
    final statusColor = _statusColor(item.statusStok);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kecamatanNama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.statusStok.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.stokPersen.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRankDropdown(List<StatusPanganItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const PageStorageKey<String>('status_kecamatan_rank_dropdown'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFCEAEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.format_list_numbered_rounded,
              color: Color(0xFFC62828),
            ),
          ),
          title: const Text(
            'Daftar Status Kecamatan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
          subtitle: Text(
            '${items.length} kecamatan - buka untuk lihat ranking',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78909C),
            ),
          ),
          children: [
            for (int i = 0; i < items.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
                child: _stokRankRow(items[i], i, i == items.length - 1),
              ),
          ],
        ),
      ),
    );
  }

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
              title: const Text(
                'Filter Kecamatan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                            setStateBuilder(
                              () => tempSelected = List.from(allKecamatan),
                            );
                          },
                          child: const Text('Pilih Semua'),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateBuilder(() => tempSelected.clear());
                          },
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(color: Colors.red),
                          ),
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
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 14),
                            ),
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
                  child:
                      const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                  ),
                  onPressed: () {
                    // Update state utama
                    // ignore: invalid_use_of_protected_member
                    setState(() {
                      _selectedKecamatanNames = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
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
        child: Text(
          'Belum ada data kecamatan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Perbaikan 1: Sorting berdasarkan stokPersen dari TERENDAH ke TERTINGGI (paling kritis di kiri)
    final sorted = [...items]
      ..sort((a, b) => a.stokPersen.compareTo(b.stokPersen));

    // Filter by kecamatan jika ada
    final filteredItems = _selectedKecamatanNames.isEmpty
        ? sorted
        : sorted
            .where((e) => _selectedKecamatanNames.contains(e.kecamatanNama))
            .toList();

    // Tampilkan kecamatan yang sudah difilter
    final top = filteredItems.toList();
    if (top.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Terapkan setidaknya 1 filter kecamatan',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final naik = items.where((e) => e.hargaTrend == 'NAIK').length;
    final turun = items.where((e) => e.hargaTrend == 'TURUN').length;
    final stabil = items.where((e) => e.hargaTrend == 'STABIL').length;
    final aman = top.where((e) => e.statusStok == 'aman').length;
    final waspada = top.where((e) => e.statusStok == 'waspada').length;
    final kritis = top.where((e) => e.statusStok == 'kritis').length;
    final avgStok =
        top.map((e) => e.stokPersen).reduce((a, b) => a + b) / top.length;
    final lowestStok = top.first;
    final highestStok = top.reduce(
      (a, b) => a.stokPersen >= b.stokPersen ? a : b,
    );
    final totalTrend = (naik + turun + stabil).clamp(1, 999999);
    final trendSummary = [
      (
        label: 'Naik',
        count: naik,
        color: const Color(0xFFC62828),
        accent: const Color(0xFFFFEBEE),
      ),
      (
        label: 'Turun',
        count: turun,
        color: const Color(0xFF2E7D32),
        accent: const Color(0xFFEAF6EC),
      ),
      (
        label: 'Stabil',
        count: stabil,
        color: const Color(0xFF1976D2),
        accent: const Color(0xFFE8F1FF),
      ),
    ];
    trendSummary.sort((a, b) => b.count.compareTo(a.count));
    final dominantTrend = trendSummary.first;

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () async => ctx.read<AnalyticsBloc>().add(LoadStatusPangan()),
      child: CustomScrollView(
        key: const PageStorageKey('status_kecamatan_tab_scroll_v2'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF15361A), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Ketahanan Pangan per Kecamatan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pantau stok wilayah yang paling aman hingga paling kritis, lalu gunakan filter area untuk fokus ke kecamatan tertentu.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth < 560
                    ? constraints.maxWidth
                    : constraints.maxWidth < 920
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 16) / 3;
                final cards = [
                  _statusStatCard('Aman', aman, const Color(0xFF2E7D32)),
                  _statusStatCard('Waspada', waspada, const Color(0xFFFF8F00)),
                  _statusStatCard('Kritis', kritis, const Color(0xFFC62828)),
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final card in cards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4EC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _chartSectionTitle('Peta Ritme Stok Kecamatan'),
                        const SizedBox(height: 4),
                        Text(
                          'Bandingkan stok per wilayah untuk melihat area paling kuat dan paling rentan.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showKecamatanFilter(items),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        foregroundColor: const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Filter Area'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _chartCard(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKecamatanStockHeader(
                      avgStok: avgStok,
                      lowest: lowestStok,
                      highest: highestStok,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildKecamatanStockLineChart(ctx, top),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildStatusRankDropdown(top),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE7F0FF), Color(0xFFD9E8FF)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grafik Tren Harga per Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF263238),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Lihat dominasi kenaikan, penurunan, dan harga stabil antar kecamatan.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF607D8B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _chartCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      dominantTrend.color
                                          .withValues(alpha: 0.20),
                                      dominantTrend.color
                                          .withValues(alpha: 0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: dominantTrend.color
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status dominan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueGrey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      dominantTrend.label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: dominantTrend.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dominantTrend.count} kecamatan',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD9E4EC),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF78909C),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$totalTrend',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF263238),
                                    ),
                                  ),
                                  const Text(
                                    'kec.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF78909C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EEF2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 18,
                              child: Row(
                                children: [
                                  if (naik > 0)
                                    Expanded(
                                      flex: naik,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFE53935),
                                              Color(0xFFC62828),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (turun > 0)
                                    Expanded(
                                      flex: turun,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF43A047),
                                              Color(0xFF2E7D32),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (stabil > 0)
                                    Expanded(
                                      flex: stabil,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF42A5F5),
                                              Color(0xFF1976D2),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 8) / 2;
                            final trendItems = [
                              (
                                label: 'Naik',
                                count: naik,
                                pct: (naik * 100 / totalTrend),
                                color: const Color(0xFFC62828),
                              ),
                              (
                                label: 'Turun',
                                count: turun,
                                pct: (turun * 100 / totalTrend),
                                color: const Color(0xFF2E7D32),
                              ),
                              (
                                label: 'Stabil',
                                count: stabil,
                                pct: (stabil * 100 / totalTrend),
                                color: const Color(0xFF1976D2),
                              ),
                            ];

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final item in trendItems)
                                  SizedBox(
                                    width: itemWidth,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            item.color.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: item.color
                                              .withValues(alpha: 0.26),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: item.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: item.color,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${item.count} - ${item.pct.toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF546E7A),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKecamatanStockHeader({
    required double avgStok,
    required StatusPanganItem lowest,
    required StatusPanganItem highest,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.stacked_bar_chart_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Peringkat Stok Kecamatan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Diurutkan dari paling rentan ke paling aman.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _stockMetricChip(
              'Rata-rata',
              '${avgStok.toStringAsFixed(1)}%',
              const Color(0xFF1976D2),
            ),
            _stockMetricChip(
              'Terendah',
              '${lowest.kecamatanNama} ${lowest.stokPersen.toStringAsFixed(0)}%',
              _statusColor(lowest.statusStok),
            ),
            _stockMetricChip(
              'Tertinggi',
              '${highest.kecamatanNama} ${highest.stokPersen.toStringAsFixed(0)}%',
              _statusColor(highest.statusStok),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 30,
              child: _thresholdSegment(
                'Kritis',
                '< 30%',
                const Color(0xFFC62828),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 40,
              child: _thresholdSegment(
                'Waspada',
                '30-69%',
                const Color(0xFFFF8F00),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 30,
              child: _thresholdSegment(
                'Aman',
                '>= 70%',
                const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKecamatanStockLineChart(
    BuildContext ctx,
    List<StatusPanganItem> top,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(MediaQuery.of(ctx).size.width - 64, top.length * 86.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 10, 0),
          child: LineChart(
            LineChartData(
              maxY: 100,
              minY: 0,
              minX: -0.25,
              maxX: math.max(0, top.length - 1).toDouble() + 0.25,
              clipData: const FlClipData.all(),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 30,
                    color: const Color(0xFFC62828).withValues(alpha: 0.42),
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                  ),
                  HorizontalLine(
                    y: 70,
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.42),
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                  ),
                ],
              ),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 20,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: const Color(0xFF90A4AE).withValues(alpha: 0.15),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(
                    color: Colors.blueGrey.withValues(alpha: 0.16),
                  ),
                  bottom: BorderSide(
                    color: Colors.blueGrey.withValues(alpha: 0.16),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipPadding: const EdgeInsets.all(9),
                  tooltipMargin: 6,
                  getTooltipColor: (_) => const Color(0xFF14332E),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      if (idx < 0 || idx >= top.length) return null;
                      final item = top[idx];
                      return LineTooltipItem(
                        '${item.kecamatanNama}\n${item.stokPersen.toStringAsFixed(1)}% - ${_stockStatusLabel(item.statusStok)}',
                        TextStyle(
                          color: _statusColor(item.statusStok),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      );
                    }).toList();
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
                    getTitlesWidget: (v, _) {
                      if (v < 0 || v > 100) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        '${v.toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF78909C),
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 46,
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      if (v % 1 != 0) return const SizedBox.shrink();
                      final i = v.toInt();
                      if (i < 0 || i >= top.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          top[i].kecamatanNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF455A64),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < top.length; i++)
                      FlSpot(
                        i.toDouble(),
                        top[i].stokPersen.clamp(0, 100).toDouble(),
                      ),
                  ],
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: const Color(0xFF0F766E),
                  barWidth: 3.6,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0F766E).withValues(alpha: 0.16),
                        const Color(0xFF0F766E).withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final item = top[index];
                      final statusColor = _statusColor(item.statusStok);
                      return FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 2.6,
                        strokeColor: statusColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stockMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thresholdSegment(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $value',
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  String _stockStatusLabel(String status) {
    switch (status) {
      case 'aman':
        return 'Aman';
      case 'waspada':
        return 'Waspada';
      case 'kritis':
        return 'Kritis';
      default:
        return 'Belum ada data';
    }
  }
}
