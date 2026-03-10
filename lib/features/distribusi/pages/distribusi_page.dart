import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/distribusi_bloc.dart';
import '../bloc/distribusi_event.dart';
import '../bloc/distribusi_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/network/dio_client.dart';

class DistribusiPage extends StatefulWidget {
  const DistribusiPage({super.key});

  @override
  State<DistribusiPage> createState() => _DistribusiPageState();
}

class _DistribusiPageState extends State<DistribusiPage> {
  String _selectedStatus = 'semua';
  int? _expandedIndex;

  static const _statusList = [
    'semua',
    'dijadwalkan',
    'proses',
    'selesai',
    'dibatalkan',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final canEdit = role == 'admin' || role == 'petugas';

    return BlocConsumer<DistribusiBloc, DistribusiState>(
      listener: (ctx, state) {
        if (state is DistribusiSaved) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Distribusi berhasil dibuat'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          ctx.read<DistribusiBloc>().add(LoadDistribusiList());
        } else if (state is DistribusiStatusUpdated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Status distribusi diperbarui'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          ctx.read<DistribusiBloc>().add(LoadDistribusiList());
        } else if (state is DistribusiError) {
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
                  onPressed: () => _showCreateForm(context),
                  label: const Text('Buat Distribusi'),
                  icon: const Icon(Icons.add),
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                )
              : null,
          body: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async =>
                context.read<DistribusiBloc>().add(RefreshDistribusi()),
            child: CustomScrollView(
              slivers: [
                _buildHeader(state),
                SliverToBoxAdapter(child: _buildFilters(state)),
                if (state is DistribusiLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                else if (state is DistribusiError)
                  SliverFillRemaining(child: _buildError((state).message))
                else if (state is DistribusiLoaded)
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

  Widget _buildHeader(DistribusiState state) {
    int proses = 0, selesai = 0, dijadwalkan = 0;
    if (state is DistribusiLoaded) {
      for (final item in state.items) {
        if (item.status == 'proses') {
          proses++;
        } else if (item.status == 'selesai')
          selesai++;
        else if (item.status == 'dijadwalkan') dijadwalkan++;
      }
    }
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
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
                          Text(
                            'Distribusi Pangan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Jadwal & status pengiriman',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statBadge(
                      '$dijadwalkan',
                      'Dijadwalkan',
                      const Color(0xFFE3F2FD),
                      const Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 8),
                    _statBadge(
                      '$proses',
                      'Proses',
                      const Color(0xFFFFF3E0),
                      const Color(0xFFF57C00),
                    ),
                    const SizedBox(width: 8),
                    _statBadge(
                      '$selesai',
                      'Selesai',
                      const Color(0xFFE8F5E9),
                      const Color(0xFF2E7D32),
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

  Widget _statBadge(String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: fg)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(DistribusiState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusList.map((s) {
            final isSelected = _selectedStatus == s;
            final color = _statusColor(s);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = s;
                  _expandedIndex = null;
                });
                context
                    .read<DistribusiBloc>()
                    .add(LoadDistribusiList(status: s));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: isSelected ? color : Colors.grey[300]!),
                ),
                child: Text(
                  s[0].toUpperCase() + s.substring(1),
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

  SliverList _buildList(DistribusiLoaded state) {
    if (state.items.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 80),
          const Center(
            child: Column(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Tidak ada data distribusi',
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
        (ctx, i) => _buildCard(state.items[i], i),
        childCount: state.items.length,
      ),
    );
  }

  Widget _buildCard(DistribusiItem item, int index) {
    final isExpanded = _expandedIndex == index;
    final statusColor = _statusColor(item.status);

    DateTime? jadwal = DateTime.tryParse(item.jadwalBerangkat);
    DateTime? eta = item.eta != null ? DateTime.tryParse(item.eta!) : null;
    final dateStr = jadwal != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(jadwal)
        : '-';
    final etaStr = eta != null ? DateFormat('HH:mm', 'id').format(eta) : '-';

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.dari} → ${item.ke}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.status[0].toUpperCase() +
                              item.status.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.komoditas} — ${NumberFormat('#,##0', 'id').format(item.jumlahKg)} kg',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.person_outline, 'Driver', item.namaDriver),
                    const SizedBox(height: 6),
                    _detailRow(
                      Icons.local_shipping_outlined,
                      'Kendaraan',
                      item.namaKendaraan,
                    ),
                    const SizedBox(height: 6),
                    _detailRow(Icons.flag_outlined, 'ETA', etaStr),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey[400],
              ),
            ),
            if (_canEditContext(context) &&
                item.status != 'selesai' &&
                item.status != 'dibatalkan') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    const Text('Update: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    _statusUpdateDropdown(context, item),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canEditContext(BuildContext ctx) {
    final authState = ctx.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    return role == 'admin' || role == 'petugas';
  }

  Widget _statusUpdateDropdown(BuildContext ctx, DistribusiItem item) {
    const statuses = ['dijadwalkan', 'proses', 'selesai', 'dibatalkan'];
    return DropdownButton<String>(
      value: statuses.contains(item.status) ? item.status : 'dijadwalkan',
      isDense: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 12, color: Color(0xFF212121)),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (newStatus) {
        if (newStatus != null && newStatus != item.status) {
          ctx.read<DistribusiBloc>().add(
                UpdateDistribusiStatus(id: item.id, status: newStatus),
              );
        }
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1976D2)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
        ),
      ],
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<DistribusiBloc>().add(LoadDistribusiList()),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'proses':
        return const Color(0xFFF57C00);
      case 'selesai':
        return const Color(0xFF2E7D32);
      case 'dijadwalkan':
        return const Color(0xFF1976D2);
      case 'dibatalkan':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF757575);
    }
  }

  void _showCreateForm(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<DistribusiBloc>(),
        child: const _CreateDistribusiSheet(),
      ),
    );
  }
}

class _CreateDistribusiSheet extends StatefulWidget {
  const _CreateDistribusiSheet();

  @override
  State<_CreateDistribusiSheet> createState() => _CreateDistribusiSheetState();
}

class _CreateDistribusiSheetState extends State<_CreateDistribusiSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selDari;
  String? _selKe;
  String? _selKomoditas;
  final _jumlahCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _kendaraanCtrl = TextEditingController();
  DateTime _jadwal = DateTime.now().add(const Duration(days: 1));
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
    _jumlahCtrl.dispose();
    _driverCtrl.dispose();
    _kendaraanCtrl.dispose();
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
        child: SingleChildScrollView(
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
                'Buat Jadwal Distribusi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              if (_loadingOpts)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
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
                        initialValue: _selDari,
                        decoration: InputDecoration(
                          labelText: 'Dari Kecamatan',
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
                        onChanged: (v) => setState(() => _selDari = v),
                        validator: (v) =>
                            v == null ? 'Pilih kecamatan asal' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selKe,
                        decoration: InputDecoration(
                          labelText: 'Ke Kecamatan',
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
                        onChanged: (v) => setState(() => _selKe = v),
                        validator: (v) =>
                            v == null ? 'Pilih kecamatan tujuan' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jumlahCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Jumlah (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Masukkan jumlah';
                          }
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0) {
                            return 'Nilai tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked =
                              await showDateTimePicker(context: context);
                          if (picked != null) {
                            setState(() => _jadwal = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Jadwal Berangkat',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy HH:mm', 'id')
                                .format(_jadwal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _driverCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Driver (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kendaraanCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Kendaraan (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<DistribusiBloc, DistribusiState>(
                        builder: (ctx, bstate) => SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: bstate is DistribusiSaving
                                ? null
                                : () => _submit(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: bstate is DistribusiSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Buat Jadwal',
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
      ),
    );
  }

  Future<DateTime?> showDateTimePicker({required BuildContext context}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _jadwal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_jadwal),
    );
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<DistribusiBloc>().add(
          CreateDistribusi(
            dariKecamatanId: _selDari!,
            keKecamatanId: _selKe!,
            komoditasId: _selKomoditas!,
            jumlahKg: double.parse(_jumlahCtrl.text),
            jadwalBerangkat: _jadwal.toUtc().toIso8601String(),
            namaDriver: _driverCtrl.text.trim().isEmpty
                ? null
                : _driverCtrl.text.trim(),
            namaKendaraan: _kendaraanCtrl.text.trim().isEmpty
                ? null
                : _kendaraanCtrl.text.trim(),
          ),
        );
    Navigator.of(ctx).pop();
  }
}
