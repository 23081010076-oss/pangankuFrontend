import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/distribusi_bloc.dart';
import '../bloc/distribusi_event.dart';
import '../bloc/distribusi_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../../core/repositories/kecamatan_repository.dart';
import '../../../core/repositories/master_data_repository.dart';
import '../data/distribusi_repository.dart';

part '../widgets/distribusi_forms.dart';

class DistribusiPage extends StatefulWidget {
  const DistribusiPage({super.key});

  @override
  State<DistribusiPage> createState() => _DistribusiPageState();
}

class _DistribusiPageState extends State<DistribusiPage> {
  String _selectedStatus = 'semua';
  int? _expandedIndex;
  final Map<String, _RuteData> _ruteCache = {};
  final Set<String> _loadingRute = {};
  final Map<String, String> _ruteError = {};
  late final DistribusiRepository _distribusiRepository;
  late final KecamatanRepository _kecamatanRepository;
  Map<String, LatLng>? _kecamatanCoords;

  @override
  void initState() {
    super.initState();
    _distribusiRepository = context.read<DistribusiRepository>();
    _kecamatanRepository = context.read<KecamatanRepository>();
  }

  static const _statusList = [
    'semua',
    'dijadwalkan',
    'proses',
    'selesai',
    'dibatalkan',
  ];

  Future<void> _toggleExpand(DistribusiItem item, int index) async {
    final isExpanded = _expandedIndex == index;
    setState(() => _expandedIndex = isExpanded ? null : index);
    if (!isExpanded) {
      await _loadRute(item.id);
    }
  }

  Future<void> _loadRute(String distribusiId) async {
    if (_ruteCache.containsKey(distribusiId) || _loadingRute.contains(distribusiId)) {
      return;
    }

    setState(() {
      _loadingRute.add(distribusiId);
      _ruteError.remove(distribusiId);
    });

    try {
      await _ensureKecamatanCoords();
      final data = await _distribusiRepository.fetchDistribusiRoute(distribusiId);
      final rawSteps = (data['rute'] as List<dynamic>? ?? []);
      final steps = rawSteps
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => _RuteStep(
              id: e['kecamatan_id']?.toString() ?? '',
              nama: e['kecamatan_nama']?.toString() ?? '-',
            ),
          )
          .where((s) => s.id.isNotEmpty)
          .toList();

      final points = <LatLng>[];
      final coords = _kecamatanCoords ?? {};
      for (final step in steps) {
        final p = coords[step.id];
        if (p != null) {
          points.add(p);
        }
      }

      setState(() {
        _ruteCache[distribusiId] = _RuteData(
          steps: steps,
          points: points,
          jarakKm: (data['jarak_km'] as num?)?.toDouble() ?? 0,
        );
      });
    } catch (_) {
      setState(() {
        _ruteError[distribusiId] = 'Rute gagal dimuat';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRute.remove(distribusiId));
      }
    }
  }

  Future<void> _ensureKecamatanCoords() async {
    if (_kecamatanCoords != null) {
      return;
    }
    _kecamatanCoords = await _kecamatanRepository.fetchKecamatanCoordinates();
  }

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
              content: Text('Perubahan distribusi berhasil disimpan'),
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
        } else if (item.status == 'selesai') {
          selesai++;
        } else if (item.status == 'dijadwalkan') {
          dijadwalkan++;
        }
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
                      color: Colors.white.withValues(alpha: 0.8),
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
                    size: 56, color: Colors.grey,),
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
      onTap: () => _toggleExpand(item, index),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4,),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
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
                    const SizedBox(height: 10),
                    _buildRuteSection(item),
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
            if (_canEditContext(context)) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Update: ',
                              style: TextStyle(fontSize: 12, color: Colors.grey),),
                          const SizedBox(width: 8),
                          if (item.status != 'selesai' && item.status != 'dibatalkan')
                            _statusUpdateDropdown(context, item)
                          else
                            const Text(
                              'Status final',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showEditStatusDialog(context, item),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF1976D2),
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteDistribusi(context, item.id),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Color(0xFFC62828),
                      ),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditStatusDialog(BuildContext ctx, DistribusiItem item) {
    const statuses = ['dijadwalkan', 'proses', 'selesai', 'dibatalkan'];
    String selected = statuses.contains(item.status) ? item.status : 'dijadwalkan';

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx2, setDialogState) => AlertDialog(
          title: const Text('Edit Status Distribusi'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setDialogState(() => selected = v);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx2),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                ctx.read<DistribusiBloc>().add(
                      UpdateDistribusiStatus(id: item.id, status: selected),
                    );
                Navigator.pop(dialogCtx2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDistribusi(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Distribusi?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<DistribusiBloc>().add(DeleteDistribusi(id));
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

  Widget _buildRuteSection(DistribusiItem item) {
    if (_loadingRute.contains(item.id)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final err = _ruteError[item.id];
    if (err != null) {
      return Text(
        err,
        style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
      );
    }

    final rute = _ruteCache[item.id];
    if (rute == null || rute.steps.isEmpty) {
      return const Text(
        'Data rute belum tersedia',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    final points = rute.points;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route_outlined, size: 14, color: Color(0xFF1976D2)),
            const SizedBox(width: 6),
            Text(
              'Rute ${rute.jarakKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: rute.steps
              .map(
                (s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.nama,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0)),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        if (points.length >= 2)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: points[0],
                  initialZoom: 10,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.panganku_mobile',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4,
                        color: const Color(0xFF1976D2),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: points.first,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.trip_origin,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                      Marker(
                        point: points.last,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFC62828),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          const Text(
            'Koordinat rute belum lengkap',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
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
