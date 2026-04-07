import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';

class KecamatanAdminPage extends StatefulWidget {
  const KecamatanAdminPage({super.key});

  @override
  State<KecamatanAdminPage> createState() => _KecamatanAdminPageState();
}

class _KecamatanAdminPageState extends State<KecamatanAdminPage> {
  late final AdminRepository _repository;
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _repository.fetchKecamatan();
      setState(() {
        _list = raw;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _repository.getErrorMessage(e, fallback: 'Gagal memuat data');
        _loading = false;
      });
    }
  }

  Future<void> _create(
      String nama, double lat, double lng, double luasHa,) async {
    try {
      await _repository.createKecamatan(
        nama: nama,
        lat: lat,
        lng: lng,
        luasHa: luasHa,
      );
      _showSnack('Kecamatan berhasil ditambahkan');
      _loadData();
    } on DioException catch (e) {
      _showSnack(
        _repository.getErrorMessage(e, fallback: 'Gagal menambahkan'),
        isError: true,
      );
    }
  }

  Future<void> _update(
      String id, String nama, double lat, double lng, double luasHa,) async {
    try {
      await _repository.updateKecamatan(
        id: id,
        nama: nama,
        lat: lat,
        lng: lng,
        luasHa: luasHa,
      );
      _showSnack('Kecamatan berhasil diperbarui');
      _loadData();
    } on DioException catch (e) {
      _showSnack(
        _repository.getErrorMessage(e, fallback: 'Gagal memperbarui'),
        isError: true,
      );
    }
  }

  Future<void> _delete(String id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kecamatan'),
        content: Text(
            'Hapus "$nama"? Data stok dan harga terkait juga dapat terpengaruh.',),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteKecamatan(id);
      _showSnack('Kecamatan berhasil dihapus');
      _loadData();
    } on DioException catch (e) {
      _showSnack(
        _repository.getErrorMessage(e, fallback: 'Gagal menghapus'),
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
    ),);
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final namaCtrl = TextEditingController(text: existing?['nama'] ?? '');
    final latCtrl = TextEditingController(
        text: existing?['lat'] != null ? existing!['lat'].toString() : '',);
    final lngCtrl = TextEditingController(
        text: existing?['lng'] != null ? existing!['lng'].toString() : '',);
    final luasCtrl = TextEditingController(
        text: existing?['luas_ha'] != null
            ? existing!['luas_ha'].toString()
            : '',);
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Kecamatan' : 'Tambah Kecamatan',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700,),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kecamatan',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true,),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true,),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                      ],
                    ),
                  ),
                ],),
                const SizedBox(height: 12),
                TextFormField(
                  controller: luasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Luas Wilayah (ha)',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx);
                        final lat = double.tryParse(latCtrl.text) ?? 0.0;
                        final lng = double.tryParse(lngCtrl.text) ?? 0.0;
                        final luas = double.tryParse(luasCtrl.text) ?? 0.0;
                        if (isEdit) {
                          _update(existing['id'].toString(),
                              namaCtrl.text.trim(), lat, lng, luas,);
                        } else {
                          _create(namaCtrl.text.trim(), lat, lng, luas);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),),
                    ),
                    child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Tambah'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title:
                  Text('Manajemen Kecamatan', style: TextStyle(fontSize: 16)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_list.isEmpty)
            const SliverFillRemaining(
              child: Center(
                  child: Text('Belum ada kecamatan',
                      style: TextStyle(color: Colors.grey),),),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildTile(_list[i]),
                  childCount: _list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> item) {
    final nama = item['nama']?.toString() ?? '';
    final lat = (item['lat'] ?? 0.0).toDouble();
    final lng = (item['lng'] ?? 0.0).toDouble();
    final luas = (item['luas_ha'] ?? 0.0).toDouble();
    final id = item['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: Color(0xFF2E7D32), size: 22,),
        ),
        title: Text(nama,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
        subtitle: Text(
          'Lat ${lat.toStringAsFixed(4)} · Lng ${lng.toStringAsFixed(4)}${luas > 0 ? ' · ${luas.toStringAsFixed(0)} ha' : ''}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: Color(0xFF2E7D32),),
              onPressed: () => _showForm(existing: item),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent,),
              onPressed: () => _delete(id, nama),
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error ?? 'Terjadi kesalahan',
              style: const TextStyle(color: Colors.grey),),
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
    );
  }
}
