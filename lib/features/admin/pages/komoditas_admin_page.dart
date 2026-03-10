import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class KomoditasAdminPage extends StatefulWidget {
  const KomoditasAdminPage({super.key});

  @override
  State<KomoditasAdminPage> createState() => _KomoditasAdminPageState();
}

class _KomoditasAdminPageState extends State<KomoditasAdminPage> {
  final _client = DioClient();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _client.dio.get('/komoditas');
      final raw = res.data is Map ? res.data['data'] : res.data;
      setState(() {
        _list = List<Map<String, dynamic>>.from(raw as List);
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['error'] ?? 'Gagal memuat data';
        _loading = false;
      });
    }
  }

  Future<void> _create(String nama, String satuan, String kategori) async {
    try {
      await _client.dio.post('/komoditas', data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
      });
      _showSnack('Komoditas berhasil ditambahkan');
      _loadData();
    } on DioException catch (e) {
      _showSnack(e.response?.data['error'] ?? 'Gagal menambahkan',
          isError: true);
    }
  }

  Future<void> _update(
      String id, String nama, String satuan, String kategori) async {
    try {
      await _client.dio.put('/komoditas/$id', data: {
        'nama': nama,
        'satuan': satuan,
        'kategori': kategori,
      });
      _showSnack('Komoditas berhasil diperbarui');
      _loadData();
    } on DioException catch (e) {
      _showSnack(e.response?.data['error'] ?? 'Gagal memperbarui',
          isError: true);
    }
  }

  Future<void> _delete(String id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Komoditas'),
        content:
            Text('Hapus "$nama"? Data harga terkait juga akan terpengaruh.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _client.dio.delete('/komoditas/$id');
      _showSnack('Komoditas berhasil dihapus');
      _loadData();
    } on DioException catch (e) {
      _showSnack(e.response?.data['error'] ?? 'Gagal menghapus', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
    ));
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final namaCtrl = TextEditingController(text: existing?['nama'] ?? '');
    final satuanCtrl = TextEditingController(text: existing?['satuan'] ?? 'kg');
    final kategoriCtrl =
        TextEditingController(text: existing?['kategori'] ?? '');
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
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Komoditas' : 'Tambah Komoditas',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Komoditas',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: satuanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Satuan (kg, liter, dll)',
                  prefixIcon: Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kategoriCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kategori (beras, sayuran, dll)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      if (isEdit) {
                        _update(
                          existing['id'].toString(),
                          namaCtrl.text.trim(),
                          satuanCtrl.text.trim().isEmpty
                              ? 'kg'
                              : satuanCtrl.text.trim(),
                          kategoriCtrl.text.trim(),
                        );
                      } else {
                        _create(
                          namaCtrl.text.trim(),
                          satuanCtrl.text.trim().isEmpty
                              ? 'kg'
                              : satuanCtrl.text.trim(),
                          kategoriCtrl.text.trim(),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan'),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: const FlexibleSpaceBar(
              title:
                  Text('Manajemen Komoditas', style: TextStyle(fontSize: 16)),
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
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_list.isEmpty)
            const SliverFillRemaining(
              child: Center(
                  child: Text('Belum ada komoditas',
                      style: TextStyle(color: Colors.grey))),
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
    final satuan = item['satuan']?.toString() ?? 'kg';
    final kategori = item['kategori']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
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
          child: const Icon(Icons.inventory_2_outlined,
              color: Color(0xFF2E7D32), size: 22),
        ),
        title: Text(nama,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${satuan.isNotEmpty ? satuan : '-'}${kategori.isNotEmpty ? ' · $kategori' : ''}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: Color(0xFF2E7D32)),
              onPressed: () => _showForm(existing: item),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent),
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
              style: const TextStyle(color: Colors.grey)),
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
