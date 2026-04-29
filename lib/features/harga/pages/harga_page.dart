// Doc:
// Tujuan: Menampilkan daftar harga komoditas serta shortcut ke halaman prediksi harga.
// Dipakai oleh: DashboardPage tab harga dan route /harga.
// Dependensi utama: HargaBloc event/state, AuthBloc, MasterDataRepository, GoRouter, harga_sheets.
// Fungsi public/utama: HargaPage, _HargaPageState lifecycle, _buildHeader, _buildSearchBar, _buildKategoriFilter, _buildList.
// Side effect penting: Dispatch load/refresh HargaBloc, membuka sheet CRUD, dan navigasi ke /harga/forecast.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/harga_bloc.dart';
import '../bloc/harga_event.dart';
import '../bloc/harga_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/repositories/master_data_repository.dart';
import '../../../core/widgets/live_refresh.dart';
import '../../../core/widgets/last_updated_badge.dart';
import '../../../core/widgets/komoditas_image.dart';

part '../widgets/harga_sheets.dart';

class HargaPage extends StatefulWidget {
  const HargaPage({super.key});

  @override
  State<HargaPage> createState() => _HargaPageState();
}

class _HargaPageState extends State<HargaPage> {
  String _selectedKategori = 'Semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  DateTime? _lastUpdatedAt;

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
        if (state is HargaLoaded) {
          setState(() => _lastUpdatedAt = DateTime.now());
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
        final canUpdate =
            role == 'admin' || role == 'petugas' || role == 'petani';
        final canDelete = role == 'admin' || role == 'petugas';

        return LiveRefresh(
          interval: const Duration(seconds: 25),
          onRefresh: () async {
            ctx.read<HargaBloc>().add(RefreshHarga());
          },
          child: Scaffold(
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LastUpdatedBadge(timestamp: _lastUpdatedAt),
                      ),
                    ),
                  ),
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
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/harga/forecast'),
                      icon: const Icon(Icons.auto_graph_outlined, size: 16),
                      label: const Text('Prediksi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
    final isRecordPerKecamatan =
        item.kecamatanId.isNotEmpty && item.id.isNotEmpty;
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            KomoditasImage(
              gambarUrl: item.gambarUrl,
              nama: item.komoditasNama,
              kategori: item.kategori,
              size: 46,
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
                if (isRecordPerKecamatan && (canUpdate || canDelete)) ...[
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 90)),
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
                final value =
                    double.tryParse(hargaCtrl.text.replaceAll(',', '.'));
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
}
