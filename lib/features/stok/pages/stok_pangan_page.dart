import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/stok_bloc.dart';
import '../bloc/stok_event.dart';
import '../bloc/stok_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/network/dio_client.dart';

class StokPanganPage extends StatefulWidget {
  const StokPanganPage({super.key});

  @override
  State<StokPanganPage> createState() => _StokPanganPageState();
}

class _StokPanganPageState extends State<StokPanganPage> {
  String _selectedStatus = 'semua';

  static const _statusFilters = ['semua', 'aman', 'waspada', 'kritis'];

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final canEdit = role == 'admin' || role == 'petugas';

    return BlocConsumer<StokBloc, StokState>(
      listener: (ctx, state) {
        if (state is StokSaved) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Data stok berhasil diperbarui'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          ctx.read<StokBloc>().add(LoadStokList());
        } else if (state is StokError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text((state).message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  onPressed: () => _showUpsertForm(context),
                  label: const Text('Update Stok'),
                  icon: const Icon(Icons.add),
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                )
              : null,
          body: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async => context.read<StokBloc>().add(RefreshStok()),
            child: CustomScrollView(
              slivers: [
                _buildHeader(state),
                SliverToBoxAdapter(child: _buildFilters()),
                if (state is StokLoading)
                  const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32))),
                  )
                else if (state is StokError)
                  SliverFillRemaining(child: _buildError((state).message))
                else if (state is StokLoaded)
                  _buildList(state)
                else
                  const SliverFillRemaining(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(StokState state) {
    int aman = 0, waspada = 0, kritis = 0;
    if (state is StokLoaded) {
      final byKec = _groupByKecamatan(state.items);
      for (final items in byKec.values) {
        final worst = _worstStatus(items);
        if (worst == 'aman') {
          aman++;
        } else if (worst == 'waspada')
          waspada++;
        else
          kritis++;
      }
    }

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
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
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stok Pangan',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text('Kondisi per kecamatan',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white.withOpacity(0.8), size: 28),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statBadge('$aman', 'Aman', const Color(0xFFE8F5E9),
                        const Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    _statBadge('$waspada', 'Waspada', const Color(0xFFFFF3E0),
                        const Color(0xFFF57C00)),
                    const SizedBox(width: 8),
                    _statBadge('$kritis', 'Kritis', const Color(0xFFFFEBEE),
                        const Color(0xFFC62828)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: fg)),
            Text(label, style: TextStyle(fontSize: 10, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((s) {
            final isSelected = _selectedStatus == s;
            final color = _statusColor(s);
            return GestureDetector(
              onTap: () => setState(() => _selectedStatus = s),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: isSelected ? color : Colors.grey[300]!),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(
                  s[0].toUpperCase() + s.substring(1),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  SliverList _buildList(StokLoaded state) {
    final byKec = _groupByKecamatan(state.items);
    final filtered = byKec.entries.where((e) {
      if (_selectedStatus == 'semua') return true;
      return _worstStatus(e.value) == _selectedStatus;
    }).toList();

    if (filtered.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 80),
          const Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Tidak ada data stok',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _buildKecamatanCard(filtered[i].key, filtered[i].value),
        childCount: filtered.length,
      ),
    );
  }

  Widget _buildKecamatanCard(String kecamatanNama, List<StokItem> items) {
    final worst = _worstStatus(items);
    final statusColor = _statusColor(worst);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(kecamatanNama,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121))),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(worst), size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        worst[0].toUpperCase() + worst.substring(1),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: items.map(_buildKomoditasRow).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildKomoditasRow(StokItem item) {
    final color = _statusColor(item.statusStok);
    final fmt = NumberFormat('#,##0', 'id');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(item.komoditasNama,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242)))),
              Text('${fmt.format(item.stokKg)} ${item.komoditasSatuan}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Text('${item.stokPersen.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.stokPersen / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFEF5350)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<StokBloc>().add(LoadStokList()),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<StokItem>> _groupByKecamatan(List<StokItem> items) {
    final map = <String, List<StokItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.kecamatanNama, () => []).add(item);
    }
    return map;
  }

  String _worstStatus(List<StokItem> items) {
    if (items.any((i) => i.statusStok == 'kritis')) return 'kritis';
    if (items.any((i) => i.statusStok == 'waspada')) return 'waspada';
    return 'aman';
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
        return Icons.info_outline;
    }
  }

  void _showUpsertForm(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<StokBloc>(),
        child: const _UpsertStokSheet(),
      ),
    );
  }
}

class _UpsertStokSheet extends StatefulWidget {
  const _UpsertStokSheet();

  @override
  State<_UpsertStokSheet> createState() => _UpsertStokSheetState();
}

class _UpsertStokSheetState extends State<_UpsertStokSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selKomoditas;
  String? _selKecamatan;
  final _stokCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
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
    _stokCtrl.dispose();
    _kapasitasCtrl.dispose();
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              'Update Data Stok',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (_loadingOpts)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
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
                      controller: _stokCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Stok Saat Ini (kg)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Masukkan stok';
                        if (double.tryParse(v) == null || double.parse(v) < 0) {
                          return 'Nilai tidak valid';
                        }
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Masukkan kapasitas';
                        if (double.tryParse(v) == null ||
                            double.parse(v) <= 0) {
                          return 'Nilai tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    BlocBuilder<StokBloc, StokState>(
                      builder: (ctx, bstate) => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              bstate is StokSaving ? null : () => _submit(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: bstate is StokSaving
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
                                  style: TextStyle(fontWeight: FontWeight.w600),
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
    ctx.read<StokBloc>().add(
          CreateOrUpdateStok(
            komoditasId: _selKomoditas!,
            kecamatanId: _selKecamatan!,
            stokKg: double.parse(_stokCtrl.text),
            kapasitasKg: double.parse(_kapasitasCtrl.text),
          ),
        );
    Navigator.of(ctx).pop();
  }
}
