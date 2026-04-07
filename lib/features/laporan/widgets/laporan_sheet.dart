part of '../pages/laporan_page.dart';

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  const _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Container(color: Colors.white, child: _tabBar);

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ── Create Laporan Sheet ──────────────────────────────────
class _CreateLaporanSheet extends StatefulWidget {
  const _CreateLaporanSheet();

  @override
  State<_CreateLaporanSheet> createState() => _CreateLaporanSheetState();
}

class _CreateLaporanSheetState extends State<_CreateLaporanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _jenisMasalahCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  late final KecamatanRepository _kecamatanRepository;
  String? _selKecamatan;
  int _prioritas = 3;
  bool _loadingOpts = true;
  List<Map<String, dynamic>> _kecList = [];

  @override
  void initState() {
    super.initState();
    _kecamatanRepository = context.read<KecamatanRepository>();
    _loadOptions();
  }

  @override
  void dispose() {
    _jenisMasalahCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final list = await _kecamatanRepository.fetchKecamatanList();
      if (mounted) {
        setState(() {
          _kecList = list;
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
              'Buat Laporan Darurat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingOpts)
              const CircularProgressIndicator(color: Color(0xFF2E7D32))
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _jenisMasalahCtrl,
                      decoration: InputDecoration(
                        labelText: 'Jenis Masalah',
                        hintText: 'mis. Kekurangan beras',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Masukkan jenis masalah' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Masukkan deskripsi' : null,
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
                    Row(
                      children: [
                        const Text(
                          'Prioritas: ',
                          style: TextStyle(fontSize: 13),
                        ),
                        ...List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _prioritas = i + 1),
                            child: Icon(
                              Icons.star,
                              color: i < _prioritas
                                  ? Colors.amber
                                  : Colors.grey[300],
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_prioritas',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<LaporanBloc, LaporanState>(
                      builder: (ctx, bstate) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: bstate is LaporanSubmitting
                              ? null
                              : () => _submit(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: bstate is LaporanSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kirim Laporan',
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
    ctx.read<LaporanBloc>().add(
          CreateLaporan(
            jenisMasalah: _jenisMasalahCtrl.text.trim(),
            deskripsi: _deskripsiCtrl.text.trim(),
            kecamatanId: _selKecamatan!,
            prioritas: _prioritas,
          ),
        );
    Navigator.of(ctx).pop();
  }
}

