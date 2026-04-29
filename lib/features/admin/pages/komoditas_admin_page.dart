// Doc:
// Tujuan: Menampilkan CRUD komoditas admin termasuk penggantian gambar komoditas via URL/Galeri dan preview.
// Dipakai oleh: Route `/admin/komoditas` dari profil/admin menu mobile.
// Dependensi utama: AdminRepository, DioException, AppConstants, Flutter Material, Bloc context, dan image_picker.
// Fungsi public/utama: KomoditasAdminPage, _loadData, _create, _update, _showForm, _buildTile.
// Side effect penting: HTTP read/write data komoditas, upload foto ke backend, dan render preview gambar jaringan.
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../data/admin_repository.dart';

class KomoditasAdminPage extends StatefulWidget {
  const KomoditasAdminPage({super.key});

  @override
  State<KomoditasAdminPage> createState() => _KomoditasAdminPageState();
}

class _KomoditasAdminPageState extends State<KomoditasAdminPage> {
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
      final items = await _repository.fetchKomoditas();
      setState(() {
        _list = items;
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
    String nama,
    String satuan,
    String kategori,
    String? gambarUrl,
  ) async {
    try {
      await _repository.createKomoditas(
        nama: nama,
        satuan: satuan,
        kategori: kategori,
        gambarUrl: gambarUrl,
      );
      _showSnack('Komoditas berhasil ditambahkan');
      _loadData();
    } on DioException catch (e) {
      _showSnack(
        _repository.getErrorMessage(e, fallback: 'Gagal menambahkan'),
        isError: true,
      );
    }
  }

  Future<void> _update(
    String id,
    String nama,
    String satuan,
    String kategori,
    String? gambarUrl,
  ) async {
    try {
      await _repository.updateKomoditas(
        id: id,
        nama: nama,
        satuan: satuan,
        kategori: kategori,
        gambarUrl: gambarUrl,
      );
      _showSnack('Komoditas berhasil diperbarui');
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
        title: const Text('Hapus Komoditas'),
        content:
            Text('Hapus "$nama"? Data harga terkait juga akan terpengaruh.'),
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
      await _repository.deleteKomoditas(id);
      _showSnack('Komoditas berhasil dihapus');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
      ),
    );
  }

  String? _normalizeImageUrl(String? rawUrl) {
    final value = rawUrl?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final apiUri = Uri.parse(AppConstants.baseUrl);
    final origin =
        '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  Widget _buildKomoditasImage(String? rawUrl, {double size = 44}) {
    final imageUrl = _normalizeImageUrl(rawUrl);
    if (imageUrl == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF2E7D32),
          size: 22,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF2E7D32),
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showForm({Map<String, dynamic>? existing}) {
    final namaCtrl = TextEditingController(text: existing?['nama'] ?? '');
    final satuanCtrl = TextEditingController(text: existing?['satuan'] ?? 'kg');
    final kategoriCtrl =
        TextEditingController(text: existing?['kategori'] ?? '');
    final gambarCtrl =
        TextEditingController(text: existing?['gambar_url']?.toString() ?? '');
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
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: gambarCtrl,
                builder: (context, value, _) {
                  final previewUrl = _normalizeImageUrl(value.text);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildKomoditasImage(value.text, size: 64),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              previewUrl == null
                                  ? 'Belum ada gambar komoditas'
                                  : 'Preview gambar akan dipakai di daftar komoditas.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: gambarCtrl,
                        decoration: InputDecoration(
                          labelText: 'URL Gambar',
                          prefixIcon: const Icon(Icons.image_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.photo_library),
                            tooltip: 'Pilih dari Galeri',
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null && context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                try {
                                  final url = await _repository
                                      .uploadFoto(pickedFile.path);
                                  gambarCtrl.text = url;
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Gagal upload gambar'),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) Navigator.pop(context);
                                }
                              }
                            },
                          ),
                          hintText: 'https://... atau /uploads/namafile.jpg',
                        ),
                        validator: (v) {
                          final text = v?.trim() ?? '';
                          if (text.isEmpty) {
                            return null;
                          }
                          final uri = Uri.tryParse(text);
                          final isHttp = uri != null &&
                              (uri.scheme == 'http' || uri.scheme == 'https');
                          if (isHttp || text.startsWith('/uploads/')) {
                            return null;
                          }
                          return 'Gunakan URL http/https atau path /uploads/...';
                        },
                      ),
                    ],
                  );
                },
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
                          gambarCtrl.text.trim().isEmpty
                              ? null
                              : gambarCtrl.text.trim(),
                        );
                      } else {
                        _create(
                          namaCtrl.text.trim(),
                          satuanCtrl.text.trim().isEmpty
                              ? 'kg'
                              : satuanCtrl.text.trim(),
                          kategoriCtrl.text.trim(),
                          gambarCtrl.text.trim().isEmpty
                              ? null
                              : gambarCtrl.text.trim(),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
          const SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
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
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_list.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Belum ada komoditas',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
    final gambarUrl = item['gambar_url']?.toString();
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildKomoditasImage(gambarUrl),
        title: Text(
          nama,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${satuan.isNotEmpty ? satuan : '-'}${kategori.isNotEmpty ? ' Â· $kategori' : ''}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Color(0xFF2E7D32),
              ),
              onPressed: () => _showForm(existing: item),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.redAccent,
              ),
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
          Text(
            _error ?? 'Terjadi kesalahan',
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
    );
  }
}
