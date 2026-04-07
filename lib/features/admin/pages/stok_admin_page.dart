import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';

class StokAdminPage extends StatefulWidget {
  const StokAdminPage({super.key});

  @override
  State<StokAdminPage> createState() => _StokAdminPageState();
}

class _StokAdminPageState extends State<StokAdminPage> {
  late final AdminRepository _repository;
  final _fmt = NumberFormat('#,##0', 'id');

  List<Map<String, dynamic>> _stokList = [];
  List<Map<String, dynamic>> _komoditasList = [];
  List<Map<String, dynamic>> _kecamatanList = [];

  bool _loading = true;
  String? _error;

  String _filterStatus = 'semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _statusFilters = ['semua', 'aman', 'waspada', 'kritis'];

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
        _repository.fetchStok(limit: 200),
        _repository.fetchKomoditas(),
        _repository.fetchKecamatan(),
      ]);

      setState(() {
        _stokList = results[0];
        _komoditasList = results[1];
        _kecamatanList = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data stok';
        _loading = false;
      });
    }
  }

  Future<void> _saveStok(Map<String, dynamic> data,
      {String? existingId,}) async {
    try {
      await _repository.saveStok(data);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data stok berhasil disimpan'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        _loadData();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = _repository.getErrorMessage(
          e,
          fallback: 'Gagal menyimpan data',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredList {
    var list = _stokList;
    if (_filterStatus != 'semua') {
      list =
          list.where((s) => (s['status_stok'] ?? '') == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final kom =
            ((s['komoditas'] as Map?)?['nama'] ?? '').toString().toLowerCase();
        final kec =
            ((s['kecamatan'] as Map?)?['nama'] ?? '').toString().toLowerCase();
        return kom.contains(q) || kec.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        label: const Text('Tambah/Update Stok'),
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
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Manajemen Stok${_loading ? '' : ' (${_stokList.length})'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,),
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
              actions: [
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSummaryBadge(),
                  ),
              ],
            ),
            SliverToBoxAdapter(child: _buildSearchAndFilter()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_filteredList.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildStokCard(_filteredList[i]),
                    childCount: _filteredList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBadge() {
    final aman = _stokList.where((s) => s['status_stok'] == 'aman').length;
    final waspada =
        _stokList.where((s) => s['status_stok'] == 'waspada').length;
    final kritis = _stokList.where((s) => s['status_stok'] == 'kritis').length;
    if (kritis > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
        ),
        child: Text(
          '$kritis kritis • $waspada waspada • $aman aman',
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600,),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari komoditas atau kecamatan...',
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
                  borderSide: BorderSide.none,),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((s) {
                final isSelected = _filterStatus == s;
                final color = _statusColor(s);
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected ? color : Colors.grey[300]!,),
                    ),
                    child: Text(
                      s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStokCard(Map<String, dynamic> stok) {
    final komoditas = stok['komoditas'] as Map? ?? {};
    final kecamatan = stok['kecamatan'] as Map? ?? {};
    final stokKg = (stok['stok_kg'] as num?)?.toDouble() ?? 0;
    final kapasitasKg = (stok['kapasitas_kg'] as num?)?.toDouble() ?? 0;
    final stokPersen = (stok['stok_persen'] as num?)?.toDouble() ?? 0;
    final status = stok['status_stok'] as String? ?? 'kritis';
    final statusColor = _statusColor(status);

    final updatedAt = stok['updated_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(
            DateTime.tryParse(stok['updated_at'].toString()) ?? DateTime.now(),)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_statusIcon(status), color: statusColor, size: 20),
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
                            color: Color(0xFF212121),),
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showForm(context, existingStok: stok),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF2E7D32),),
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_fmt.format(stokKg)} / ${_fmt.format(kapasitasKg)} kg',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600],),
                          ),
                          Text(
                            '${stokPersen.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (stokPersen / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Row(
              children: [
                Icon(Icons.update, size: 11, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Diperbarui: $updatedAt',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
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
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aman':
        return const Color(0xFF2E7D32);
      case 'waspada':
        return const Color(0xFFF57C00);
      case 'kritis':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'aman':
        return Icons.check_circle_outline;
      case 'waspada':
        return Icons.warning_amber_outlined;
      case 'kritis':
        return Icons.error_outline;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _showForm(BuildContext context, {Map<String, dynamic>? existingStok}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StokFormSheet(
        komoditasList: _komoditasList,
        kecamatanList: _kecamatanList,
        existingStok: existingStok,
        onSave: _saveStok,
      ),
    );
  }
}

// ── Form Sheet ───────────────────────────────────────────
class _StokFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> komoditasList;
  final List<Map<String, dynamic>> kecamatanList;
  final Map<String, dynamic>? existingStok;
  final Future<void> Function(Map<String, dynamic> data, {String? existingId})
      onSave;

  const _StokFormSheet({
    required this.komoditasList,
    required this.kecamatanList,
    required this.onSave,
    this.existingStok,
  });

  @override
  State<_StokFormSheet> createState() => _StokFormSheetState();
}

class _StokFormSheetState extends State<_StokFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selKomoditas;
  String? _selKecamatan;
  final _stokCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStok;
    if (s != null) {
      _selKomoditas = (s['komoditas'] as Map?)?['id']?.toString() ??
          s['komoditas_id']?.toString();
      _selKecamatan = (s['kecamatan'] as Map?)?['id']?.toString() ??
          s['kecamatan_id']?.toString();
      _stokCtrl.text = (s['stok_kg'] as num?)?.toString() ?? '';
      _kapasitasCtrl.text = (s['kapasitas_kg'] as num?)?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _stokCtrl.dispose();
    _kapasitasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingStok != null;
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Data Stok' : 'Tambah Data Stok',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: _selKomoditas,
                  decoration: InputDecoration(
                    labelText: 'Komoditas',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12,),
                  ),
                  items: widget.komoditasList
                      .map((k) => DropdownMenuItem<String>(
                            value: k['id']?.toString(),
                            child: Text(k['nama']?.toString() ?? ''),
                          ),)
                      .toList(),
                  onChanged:
                      isEdit ? null : (v) => setState(() => _selKomoditas = v),
                  validator: (v) => v == null ? 'Pilih komoditas' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selKecamatan,
                  decoration: InputDecoration(
                    labelText: 'Kecamatan',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12,),
                  ),
                  items: widget.kecamatanList
                      .map((k) => DropdownMenuItem<String>(
                            value: k['id']?.toString(),
                            child: Text(k['nama']?.toString() ?? ''),
                          ),)
                      .toList(),
                  onChanged:
                      isEdit ? null : (v) => setState(() => _selKecamatan = v),
                  validator: (v) => v == null ? 'Pilih kecamatan' : null,
                ),
                if (isEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 13, color: Colors.grey,),
                        const SizedBox(width: 4),
                        Text(
                          'Komoditas & kecamatan tidak dapat diubah',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stokCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Stok Saat Ini (kg)',
                    suffixText: 'kg',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Masukkan stok';
                    final val = double.tryParse(v);
                    if (val == null || val < 0) return 'Nilai tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _kapasitasCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Kapasitas Maksimal (kg)',
                    suffixText: 'kg',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Masukkan kapasitas';
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return 'Nilai tidak valid';
                    final stok = double.tryParse(_stokCtrl.text) ?? 0;
                    if (stok > val) return 'Kapasitas harus ≥ stok saat ini';
                    return null;
                  },
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
                          borderRadius: BorderRadius.circular(12),),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,),)
                        : Text(isEdit ? 'Perbarui Stok' : 'Simpan',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),),
                  ),
                ),
              ],),
            ),
          ],),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onSave(
      {
        'komoditas_id': _selKomoditas,
        'kecamatan_id': _selKecamatan,
        'stok_kg': double.parse(_stokCtrl.text),
        'kapasitas_kg': double.parse(_kapasitasCtrl.text),
      },
    );
    if (mounted) setState(() => _saving = false);
  }
}

// ── Empty State ──────────────────────────────────────────
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
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Tidak ada data stok',
                style: TextStyle(color: Colors.grey, fontSize: 14),),
          ],
        ),
      ),
    );
  }
}
