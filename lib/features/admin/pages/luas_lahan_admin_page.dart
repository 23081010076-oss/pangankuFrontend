// Penjelasan file:
// Feature: admin
// Layer: ui
// File: luas_lahan_admin_page
// Fungsi utama: File ini mengatur tampilan halaman, komponen visual, dan interaksi pengguna.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../data/admin_repository.dart';

class LuasLahanAdminPage extends StatefulWidget {
  const LuasLahanAdminPage({super.key});

  @override
  State<LuasLahanAdminPage> createState() => _LuasLahanAdminPageState();
}

class _LuasLahanAdminPageState extends State<LuasLahanAdminPage> {
  late final AdminRepository _repository;
  final _fmt = NumberFormat('#,##0.##', 'id');

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _komoditasList = [];
  List<Map<String, dynamic>> _kecamatanList = [];

  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repository.fetchLuasLahan(limit: 500),
        _repository.fetchKomoditas(),
        _repository.fetchKecamatan(),
      ]);

      setState(() {
        _items = results[0];
        _komoditasList = results[1];
        _kecamatanList = results[2];
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _repository.getErrorMessage(
          e,
          fallback: 'Gagal memuat data luas lahan',
        );
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Gagal memuat data luas lahan';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _items;
    }
    final q = _searchQuery.toLowerCase();
    return _items.where((item) {
      final komoditas =
          ((item['komoditas'] as Map?)?['nama'] ?? '').toString().toLowerCase();
      final kecamatan =
          ((item['kecamatan'] as Map?)?['nama'] ?? '').toString().toLowerCase();
      final tahun = (item['tahun'] ?? '').toString().toLowerCase();
      return komoditas.contains(q) ||
          kecamatan.contains(q) ||
          tahun.contains(q);
    }).toList();
  }

  Future<void> _saveLuasLahan(Map<String, dynamic> data) async {
    try {
      await _repository.saveLuasLahan(data);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data luas lahan berhasil disimpan'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      _loadData();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _repository.getErrorMessage(
        e,
        fallback: 'Gagal menyimpan data luas lahan',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _deleteLuasLahan(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;

    final komoditas = ((item['komoditas'] as Map?)?['nama'] ?? '-').toString();
    final kecamatan = ((item['kecamatan'] as Map?)?['nama'] ?? '-').toString();
    final tahun = item['tahun']?.toString() ?? '-';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Luas Lahan'),
        content: Text('Hapus data $komoditas - $kecamatan ($tahun)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteLuasLahan(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data luas lahan berhasil dihapus'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      _loadData();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _repository.getErrorMessage(
        e,
        fallback: 'Gagal menghapus data luas lahan',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _showForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LuasLahanFormSheet(
        komoditasList: _komoditasList,
        kecamatanList: _kecamatanList,
        existing: existing,
        onSave: _saveLuasLahan,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Tambah Luas Lahan'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Luas Lahan${_loading ? '' : ' (${_items.length})'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
            ),
            SliverToBoxAdapter(child: _buildSearchSection()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_filteredItems.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildItemCard(_filteredItems[i]),
                    childCount: _filteredItems.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final totalLuas = _items.fold<double>(
      0,
      (sum, item) => sum + ((item['luas_ha'] as num?)?.toDouble() ?? 0),
    );
    final tahunSet = _items
        .map((item) => item['tahun']?.toString() ?? '')
        .where((tahun) => tahun.isNotEmpty)
        .toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total Data',
                  '${_items.length}',
                  Icons.dataset_outlined,
                  const Color(0xFF2E7D32),
                  const Color(0xFFE8F5E9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Total Luas',
                  '${_fmt.format(totalLuas)} ha',
                  Icons.landscape_outlined,
                  const Color(0xFF1976D2),
                  const Color(0xFFE3F2FD),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Tahun Aktif',
                  '${tahunSet.length}',
                  Icons.calendar_today_outlined,
                  const Color(0xFFF57C00),
                  const Color(0xFFFFF3E0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari komoditas, kecamatan, atau tahun...',
              prefixIcon:
                  const Icon(Icons.search, color: Colors.grey, size: 20),
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
            onChanged: (v) =>
                setState(() => _searchQuery = v.trim().toLowerCase()),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
    Color fg,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final komoditas = item['komoditas'] as Map? ?? {};
    final kecamatan = item['kecamatan'] as Map? ?? {};
    final luasHa = (item['luas_ha'] as num?)?.toDouble() ?? 0;
    final tahun = item['tahun']?.toString() ?? '-';
    final updatedAt = item['updated_at'] != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
            'id',
          ).format(
            DateTime.tryParse(item['updated_at'].toString()) ?? DateTime.now(),
          )
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.landscape_outlined,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        komoditas['nama']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        kecamatan['nama']?.toString() ?? '-',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    tahun,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FBF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Luas Lahan',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fmt.format(luasHa)} Ha',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _showForm(existing: item),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteLuasLahan(item),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.update, size: 11, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Diperbarui: $updatedAt',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF5350)),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuasLahanFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> komoditasList;
  final List<Map<String, dynamic>> kecamatanList;
  final Map<String, dynamic>? existing;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _LuasLahanFormSheet({
    required this.komoditasList,
    required this.kecamatanList,
    required this.onSave,
    this.existing,
  });

  @override
  State<_LuasLahanFormSheet> createState() => _LuasLahanFormSheetState();
}

class _LuasLahanFormSheetState extends State<_LuasLahanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selKomoditas;
  String? _selKecamatan;
  final _luasCtrl = TextEditingController();
  final _tahunCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _selKomoditas = (existing['komoditas'] as Map?)?['id']?.toString() ??
          existing['komoditas_id']?.toString();
      _selKecamatan = (existing['kecamatan'] as Map?)?['id']?.toString() ??
          existing['kecamatan_id']?.toString();
      _luasCtrl.text = (existing['luas_ha'] as num?)?.toString() ?? '';
      _tahunCtrl.text = (existing['tahun'] ?? DateTime.now().year).toString();
    } else {
      _tahunCtrl.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _luasCtrl.dispose();
    _tahunCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
              Text(
                isEdit ? 'Edit Luas Lahan' : 'Tambah Luas Lahan',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selKomoditas,
                      isExpanded: true,
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
                      items: widget.komoditasList
                          .map(
                            (k) => DropdownMenuItem<String>(
                              value: k['id']?.toString(),
                              child: Text(
                                k['nama']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEdit
                          ? null
                          : (v) => setState(() => _selKomoditas = v),
                      validator: (v) => v == null ? 'Pilih komoditas' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selKecamatan,
                      isExpanded: true,
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
                      items: widget.kecamatanList
                          .map(
                            (k) => DropdownMenuItem<String>(
                              value: k['id']?.toString(),
                              child: Text(
                                k['nama']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isEdit
                          ? null
                          : (v) => setState(() => _selKecamatan = v),
                      validator: (v) => v == null ? 'Pilih kecamatan' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tahunCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tahun',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Masukkan tahun';
                        final year = int.tryParse(v);
                        if (year == null || year < 2000 || year > 2100) {
                          return 'Tahun tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _luasCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Luas Lahan (Ha)',
                        suffixText: 'Ha',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Masukkan luas lahan';
                        }
                        final value = double.tryParse(v.replaceAll(',', '.'));
                        if (value == null || value <= 0) {
                          return 'Nilai tidak valid';
                        }
                        return null;
                      },
                    ),
                    if (isEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Komoditas dan kecamatan tetap, data akan diperbarui',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEdit ? 'Perbarui Data' : 'Simpan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave({
      'komoditas_id': _selKomoditas,
      'kecamatan_id': _selKecamatan,
      'tahun': int.parse(_tahunCtrl.text),
      'luas_ha': double.parse(_luasCtrl.text.replaceAll(',', '.')),
    });
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.landscape_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Belum ada data luas lahan',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
