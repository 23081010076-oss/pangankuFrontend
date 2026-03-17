import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../bloc/harga_bloc.dart';
import '../bloc/harga_event.dart';
import '../bloc/harga_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/network/dio_client.dart';

class HargaPage extends StatefulWidget {
  const HargaPage({super.key});

  @override
  State<HargaPage> createState() => _HargaPageState();
}

class _HargaPageState extends State<HargaPage> {
  String _selectedKategori = 'Semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HargaBloc>().add(LoadHargaList());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HargaBloc, HargaState>(
      listener: (ctx, state) {
        if (state is HargaCreated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Data harga berhasil ditambahkan'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
        if (state is HargaUpdated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Data harga berhasil diperbarui'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
        if (state is HargaDeleted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Data harga berhasil dihapus'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
        if (state is HargaError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      builder: (ctx, state) {
        final authState = ctx.read<AuthBloc>().state;
        final role = authState is AuthAuthenticated ? authState.role : '';
        final canUpdate = role == 'admin' ||
            role == 'petugas' ||
            role == 'petani' ||
            role == 'pedagang';
        final canDelete = role == 'admin' || role == 'petugas';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
            floatingActionButton: canUpdate
              ? FloatingActionButton.extended(
                  onPressed: () => _showCreateForm(ctx),
                  label: const Text('Tambah Data'),
                  icon: const Icon(Icons.add),
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                )
              : null,
          body: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async => ctx.read<HargaBloc>().add(RefreshHarga()),
            child: CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverToBoxAdapter(child: _buildSearchBar()),
                if (state is HargaLoaded) ...[
                  SliverToBoxAdapter(
                    child: _buildKategoriFilter(state.kategoris),
                  ),
                  _buildList(ctx, state, canUpdate, canDelete),
                ] else if (state is HargaLoading) ...[
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ] else if (state is HargaError) ...[
                  SliverFillRemaining(
                    child: _buildError(ctx, state.message),
                  ),
                ] else ...[
                  const SliverFillRemaining(child: SizedBox()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
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
                  'Harga Komoditas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Data harga terkini dari seluruh kecamatan',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Cari komoditas...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildKategoriFilter(List<String> kategoris) {
    final all = ['Semua', ...kategoris];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: all.map((k) {
            final isSelected = _selectedKategori == k;
            return GestureDetector(
              onTap: () => setState(() => _selectedKategori = k),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  k,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  SliverList _buildList(
    BuildContext ctx,
    HargaLoaded state,
    bool canUpdate,
    bool canDelete,
  ) {
    var items = state.hargaList;
    if (_selectedKategori != 'Semua') {
      items = items.where((i) => i.kategori == _selectedKategori).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items
          .where(
            (i) => i.komoditasNama.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    if (items.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 80),
          const Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Tidak ada data ditemukan',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx2, i) =>
            _buildKomoditasCard(ctx, items[i], state, canUpdate, canDelete),
        childCount: items.length,
      ),
    );
  }

  Widget _buildKomoditasCard(
    BuildContext ctx,
    HargaItem item,
    HargaLoaded state,
    bool canUpdate,
    bool canDelete,
  ) {
    final trendColor = item.trend == 'NAIK'
        ? const Color(0xFFC62828)
        : item.trend == 'TURUN'
            ? const Color(0xFF2E7D32)
            : Colors.grey;
    final trendIcon = item.trend == 'NAIK'
        ? Icons.trending_up
        : item.trend == 'TURUN'
            ? Icons.trending_down
            : Icons.trending_flat;

    return GestureDetector(
      onTap: () => _showDetailSheet(ctx, item, state),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _emoji(item.komoditasNama, item.kategori),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.komoditasNama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  Text(
                    item.kecamatanNama.isEmpty
                        ? 'Rata-rata semua kecamatan'
                        : item.kecamatanNama,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${NumberFormat('#,###', 'id').format(item.harga)}/kg',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 13, color: trendColor),
                    const SizedBox(width: 2),
                    Text(
                      '${item.perubahanPersen.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                if (canUpdate || canDelete) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canUpdate)
                        GestureDetector(
                          onTap: () {
                            _showEditHargaDialog(ctx, item);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      if (canDelete)
                        GestureDetector(
                          onTap: () {
                            _confirmDeleteHarga(ctx, item);
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFFC62828),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(
    BuildContext ctx,
    HargaItem item,
    HargaLoaded state,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<HargaBloc>(),
        child: _HargaDetailSheet(item: item, initialState: state),
      ),
    );
  }

  void _showCreateForm(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<HargaBloc>(),
        child: const _TambahHargaSheet(),
      ),
    );
  }

  void _showEditHargaDialog(BuildContext ctx, HargaItem item) {
    final hargaCtrl = TextEditingController(
      text: item.harga.toStringAsFixed(0),
    );
    DateTime tanggal = DateTime.tryParse(item.tanggal) ?? DateTime.now();

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx2, setDialogState) => AlertDialog(
          title: const Text('Edit Harga'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: hargaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Harga per kg',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(DateFormat('dd MMM yyyy', 'id').format(tanggal)),
                trailing: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx2,
                    initialDate: tanggal,
                    firstDate: DateTime.now().subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => tanggal = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx2).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(hargaCtrl.text.replaceAll(',', '.'));
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: const Text('Harga tidak valid'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                  return;
                }

                final now = DateTime.now();
                final isToday = tanggal.year == now.year &&
                    tanggal.month == now.month &&
                    tanggal.day == now.day;
                final tanggalUtc = isToday
                    ? now.toUtc().toIso8601String()
                    : '${DateFormat('yyyy-MM-dd').format(tanggal)}T23:59:59Z';

                ctx.read<HargaBloc>().add(
                      UpdateHarga(
                        id: item.id,
                        hargaPerKg: value,
                        tanggal: tanggalUtc,
                      ),
                    );
                Navigator.of(dialogCtx2).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHarga(BuildContext ctx, HargaItem item) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data Harga?'),
        content: Text('Hapus data ${item.komoditasNama} ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<HargaBloc>().add(DeleteHarga(item.id));
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

  Widget _buildError(BuildContext ctx, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 56,
            color: Color(0xFFEF5350),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ctx.read<HargaBloc>().add(LoadHargaList()),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _emoji(String nama, String kategori) {
    final n = nama.toLowerCase();
    if (n.contains('beras')) return '\u{1F33E}';
    if (n.contains('jagung')) return '\u{1F33D}';
    if (n.contains('kedelai')) return '\u{1FAD8}';
    if (n.contains('kacang')) return '\u{1F95C}';
    if (n.contains('cabai') || n.contains('cabai')) return '\u{1F336}';
    if (n.contains('bawang')) return '\u{1F9C5}';
    if (n.contains('telur')) return '\u{1F95A}';
    if (n.contains('daging')) return '\u{1F969}';
    if (n.contains('ayam')) return '\u{1F357}';
    if (n.contains('ikan')) return '\u{1F41F}';
    if (n.contains('gula')) return '\u{1F36C}';
    if (n.contains('minyak')) return '\u{1FAD9}';
    switch (kategori.toLowerCase()) {
      case 'padi-padian':
        return '\u{1F33E}';
      case 'kacang-kacangan':
        return '\u{1F95C}';
      case 'sayuran':
        return '\u{1F96C}';
      case 'hewani':
        return '\u{1F969}';
      default:
        return '\u{1F6D2}';
    }
  }
}

// ── Detail Sheet ──────────────────────────────────────────
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey[200]!, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) => Text(
                  '${(v / 1000).toStringAsFixed(0)}rb',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
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
              color: const Color(0xFF2E7D32),
              barWidth: 2.5,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF2E7D32).withOpacity(0.08),
              ),
              dotData: const FlDotData(show: false),
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
      final c = DioClient();
      final res = await Future.wait([
        c.dio.get('/komoditas'),
        c.dio.get('/kecamatan'),
      ]);
      if (mounted) {
        setState(() {
          _komList = List<Map<String, dynamic>>.from(
            res[0].data is Map
                ? (res[0].data['data'] ?? res[0].data)
                : res[0].data,
          );
          _kecList = List<Map<String, dynamic>>.from(
            res[1].data is Map
                ? (res[1].data['data'] ?? res[1].data)
                : res[1].data,
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
