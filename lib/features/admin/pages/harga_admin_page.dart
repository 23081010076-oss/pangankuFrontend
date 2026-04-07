import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';

class HargaAdminPage extends StatefulWidget {
  const HargaAdminPage({super.key});

  @override
  State<HargaAdminPage> createState() => _HargaAdminPageState();
}

class _HargaAdminPageState extends State<HargaAdminPage> {
  late final AdminRepository _repository;
  final _currFmt = NumberFormat('#,##0', 'id');

  List<Map<String, dynamic>> _hargaList = [];
  List<Map<String, dynamic>> _komoditasList = [];
  List<Map<String, dynamic>> _kecamatanList = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String? _filterKomoditas;
  String? _filterKecamatan;

  int _page = 1;
  static const _limit = 20;
  bool _hasMore = true;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadMeta();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 120 &&
        !_loadingMore &&
        _hasMore) {
      _loadMoreHarga();
    }
  }

  Future<void> _loadMeta() async {
    try {
      final results = await Future.wait([
        _repository.fetchKomoditas(),
        _repository.fetchKecamatan(),
      ]);
      setState(() {
        _komoditasList = results[0];
        _kecamatanList = results[1];
      });
      await _loadHarga(reset: true);
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat metadata';
        _loading = false;
      });
    }
  }

  Future<void> _loadHarga({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _hargaList = [];
      });
    }

    try {
      final result = await _repository.fetchHargaPage(
        page: _page,
        limit: _limit,
        komoditasId: _filterKomoditas,
        kecamatanId: _filterKecamatan,
      );
      final items = List<Map<String, dynamic>>.from(result['items'] as List);
      final total = result['total'] as int;

      setState(() {
        if (reset) {
          _hargaList = items;
        } else {
          _hargaList.addAll(items);
        }
        _hasMore = _hargaList.length < total;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data harga';
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreHarga() async {
    setState(() {
      _loadingMore = true;
      _page++;
    });
    try {
      final result = await _repository.fetchHargaPage(
        page: _page,
        limit: _limit,
        komoditasId: _filterKomoditas,
        kecamatanId: _filterKecamatan,
      );
      final items = List<Map<String, dynamic>>.from(result['items'] as List);
      final total = result['total'] as int;

      setState(() {
        _hargaList.addAll(items);
        _hasMore = _hargaList.length < total;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() {
        _loadingMore = false;
        _page--;
      });
    }
  }

  Future<void> _createHarga(Map<String, dynamic> data) async {
    try {
      await _repository.createHarga(data);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data harga berhasil ditambahkan'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        _loadHarga(reset: true);
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

  void _applyFilter() {
    _loadHarga(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateForm(context),
        label: const Text('Tambah Harga'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () => _loadHarga(reset: true),
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Manajemen Harga',
                  style: TextStyle(
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
            ),
            SliverToBoxAdapter(child: _buildFilterSection()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildError())
            else if (_hargaList.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(children: [
                    Icon(Icons.history, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Data historis — tidak dapat diedit',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == _hargaList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF2E7D32),),
                          ),
                        );
                      }
                      return _buildHargaCard(_hargaList[i]);
                    },
                    childCount: _hargaList.length + (_loadingMore ? 1 : 0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,),),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _filterKomoditas,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Komoditas',
                  labelStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Semua komoditas'),),
                  ..._komoditasList.map((k) => DropdownMenuItem<String?>(
                        value: k['id']?.toString(),
                        child: Text(k['nama']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,),
                      ),),
                ],
                onChanged: (v) {
                  setState(() => _filterKomoditas = v);
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _filterKecamatan,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Kecamatan',
                  labelStyle: const TextStyle(fontSize: 12),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Semua kecamatan'),),
                  ..._kecamatanList.map((k) => DropdownMenuItem<String?>(
                        value: k['id']?.toString(),
                        child: Text(k['nama']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,),
                      ),),
                ],
                onChanged: (v) {
                  setState(() => _filterKecamatan = v);
                  _applyFilter();
                },
              ),
            ),
          ],),
        ],
      ),
    );
  }

  Widget _buildHargaCard(Map<String, dynamic> harga) {
    final komoditas = harga['komoditas'] as Map? ?? {};
    final kecamatan = harga['kecamatan'] as Map? ?? {};
    final hargaPerKg = (harga['harga_per_kg'] as num?)?.toDouble() ?? 0;
    final tanggalStr = harga['tanggal']?.toString() ?? '';
    final tanggal = DateTime.tryParse(tanggalStr);
    final tanggalFmt =
        tanggal != null ? DateFormat('dd MMM yyyy', 'id').format(tanggal) : '-';

    final trend = harga['trend']?.toString();
    final perubahan = (harga['perubahan_persen'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.price_change_outlined,
                  color: Color(0xFF2E7D32), size: 18,),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rp ${_currFmt.format(hargaPerKg)}/kg',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trend != null && trend.isNotEmpty) ...[
                      Icon(
                        trend == 'NAIK'
                            ? Icons.arrow_upward
                            : trend == 'TURUN'
                                ? Icons.arrow_downward
                                : Icons.remove,
                        size: 11,
                        color: trend == 'NAIK'
                            ? Colors.red
                            : trend == 'TURUN'
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                      ),
                      if (perubahan != null)
                        Text(
                          '${perubahan.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: trend == 'NAIK'
                                ? Colors.red
                                : trend == 'TURUN'
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tanggalFmt,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
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
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadHarga(reset: true),
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

  void _showCreateForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HargaFormSheet(
        komoditasList: _komoditasList,
        kecamatanList: _kecamatanList,
        onSave: _createHarga,
      ),
    );
  }
}

// ── Harga Form Sheet ─────────────────────────────────────
class _HargaFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> komoditasList;
  final List<Map<String, dynamic>> kecamatanList;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const _HargaFormSheet({
    required this.komoditasList,
    required this.kecamatanList,
    required this.onSave,
  });

  @override
  State<_HargaFormSheet> createState() => _HargaFormSheetState();
}

class _HargaFormSheetState extends State<_HargaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selKomoditas;
  String? _selKecamatan;
  final _hargaCtrl = TextEditingController();
  DateTime _tanggal = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _hargaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2E7D32)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tanggalFmt = DateFormat('dd MMMM yyyy', 'id').format(_tanggal);

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
            const Text(
              'Tambah Data Harga',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Data harga bersifat historis dan tidak dapat diubah',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: _selKomoditas,
                  isExpanded: true,
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
                            child: Text(k['nama']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,),
                          ),)
                      .toList(),
                  onChanged: (v) => setState(() => _selKomoditas = v),
                  validator: (v) => v == null ? 'Pilih komoditas' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selKecamatan,
                  isExpanded: true,
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
                            child: Text(k['nama']?.toString() ?? '',
                                overflow: TextOverflow.ellipsis,),
                          ),)
                      .toList(),
                  onChanged: (v) => setState(() => _selKecamatan = v),
                  validator: (v) => v == null ? 'Pilih kecamatan' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hargaCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga per kg',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Masukkan harga';
                    final val = double.tryParse(v.replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Nilai tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _pickDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tanggal',
                        hintText: tanggalFmt,
                        prefixIcon:
                            const Icon(Icons.calendar_today_outlined, size: 18),
                        suffixIcon:
                            const Icon(Icons.edit_calendar_outlined, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),),
                      ),
                      controller: TextEditingController(text: tanggalFmt),
                    ),
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
                          borderRadius: BorderRadius.circular(12),),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,),)
                        : const Text('Simpan',
                            style: TextStyle(fontWeight: FontWeight.w600),),
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
    await widget.onSave({
      'komoditas_id': _selKomoditas,
      'kecamatan_id': _selKecamatan,
      'harga_per_kg': double.parse(_hargaCtrl.text.replaceAll(',', '.')),
      'tanggal': DateFormat('yyyy-MM-dd').format(_tanggal),
    });
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
            Icon(Icons.price_change_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada data harga',
                style: TextStyle(color: Colors.grey, fontSize: 14),),
          ],
        ),
      ),
    );
  }
}
