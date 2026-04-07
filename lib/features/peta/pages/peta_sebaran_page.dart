import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../analytics/bloc/analytics_bloc.dart';
import '../../analytics/bloc/analytics_event.dart';
import '../../analytics/bloc/analytics_state.dart';
import '../../analytics/data/analytics_repository.dart';

class PetaSebaranPage extends StatelessWidget {
  const PetaSebaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AnalyticsBloc(context.read<AnalyticsRepository>())
            ..add(LoadStatusPangan()),
      child: const _PetaSebaranView(),
    );
  }
}

class _PetaSebaranView extends StatefulWidget {
  const _PetaSebaranView();

  @override
  State<_PetaSebaranView> createState() => _PetaSebaranViewState();
}

class _PetaSebaranViewState extends State<_PetaSebaranView> {
  StatusPanganItem? _selected;
  String _selectedLayer = 'stok';
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'kritis':
        return const Color(0xFFC62828);
      case 'waspada':
        return const Color(0xFFF57C00);
      case 'aman':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'kritis':
        return 'Kritis';
      case 'waspada':
        return 'Waspada';
      case 'aman':
        return 'Aman';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            flex: 5,
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (_, state) {
                if (state is StatusPanganLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF006064)),
                  );
                }
                if (state is StatusPanganError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.signal_wifi_off_outlined,
                            size: 48, color: Colors.grey,),
                        const SizedBox(height: 12),
                        Text(state.message,
                            style: const TextStyle(color: Colors.grey),),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context
                              .read<AnalyticsBloc>()
                              .add(LoadStatusPangan()),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                final items = state is StatusPanganLoaded
                    ? state.items
                    : <StatusPanganItem>[];
                return _buildMap(items);
              },
            ),
          ),
          BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (_, state) {
              final items = state is StatusPanganLoaded
                  ? state.items
                  : <StatusPanganItem>[];
              return _buildStatusPills(items);
            },
          ),
          Expanded(
            flex: 3,
            child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (_, state) {
                final items = state is StatusPanganLoaded
                    ? state.items
                    : <StatusPanganItem>[];
                final sorted = [...items]..sort((a, b) {
                    const order = {
                      'kritis': 0,
                      'waspada': 1,
                      'aman': 2,
                    };
                    return (order[a.statusStok] ?? 9)
                        .compareTo(order[b.statusStok] ?? 9);
                  });
                return _buildList(sorted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF26C6DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined,
                    color: Colors.white, size: 20,),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peta Sebaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),),
                    Text('Kabupaten Lamongan',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 10),),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedLayer =
                      _selectedLayer == 'stok' ? 'harga' : 'stok';
                }),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1,),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_outlined,
                          size: 14, color: Colors.white,),
                      const SizedBox(width: 4),
                      Text(
                        _selectedLayer == 'stok' ? 'Layer: Stok' : 'Layer: Harga',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    context.read<AnalyticsBloc>().add(LoadStatusPangan()),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.refresh,
                      size: 16, color: Colors.white,),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(List<StatusPanganItem> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(-7.09, 112.33),
                initialZoom: 10.0,
                maxZoom: 17,
                minZoom: 7,
                onTap: (_, __) => setState(() => _selected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.panganku_mobile',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: items.map((item) {
                    final color = _statusColor(item.statusStok);
                    final isSelected =
                        _selected?.kecamatanId == item.kecamatanId;
                    return Marker(
                      point: LatLng(item.lat, item.lng),
                      width: 88,
                      height: 42,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selected = isSelected ? null : item;
                        }),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3,),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : color.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: color, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                item.kecamatanNama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? color : Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5,),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            if (_selected != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildSelectedInfo(_selected!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedInfo(StatusPanganItem item) {
    final color = _statusColor(item.statusStok);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kecamatanNama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _InfoChip(
                        label: 'Stok: ${item.stokPersen.toStringAsFixed(0)}%',
                        color: color,),
                    _InfoChip(
                        label: 'Harga: ${item.hargaTrend}',
                        color: item.hargaTrend == 'NAIK'
                            ? const Color(0xFFC62828)
                            : item.hargaTrend == 'TURUN'
                                ? const Color(0xFF2E7D32)
                                : Colors.blueGrey,),
                    if (item.jumlahLaporanAktif > 0)
                      _InfoChip(
                          label: '${item.jumlahLaporanAktif} laporan',
                          color: const Color(0xFFF57C00),),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(item.statusStok),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPills(List<StatusPanganItem> items) {
    final aman = items.where((k) => k.statusStok == 'aman').length;
    final waspada = items.where((k) => k.statusStok == 'waspada').length;
    final kritis = items.where((k) => k.statusStok == 'kritis').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          _StatusPill(
            label: 'Aman',
            count: aman,
            color: const Color(0xFF2E7D32),
            bg: const Color(0xFFE8F5E9),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: 'Waspada',
            count: waspada,
            color: const Color(0xFFF57C00),
            bg: const Color(0xFFFFF3E0),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: 'Kritis',
            count: kritis,
            color: const Color(0xFFC62828),
            bg: const Color(0xFFFFEBEE),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<StatusPanganItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('Belum ada data kecamatan',
            style: TextStyle(color: Colors.grey[400]),),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Status per Kecamatan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (context, i) {
                final k = items[i];
                final color = _statusColor(k.statusStok);
                final isSelected =
                    _selected?.kecamatanId == k.kecamatanId;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selected = isSelected ? null : k;
                    });
                    if (!isSelected) {
                      _mapController.move(LatLng(k.lat, k.lng), 12.0);
                    }
                  },
                  child: Container(
                    color: isSelected
                        ? color.withValues(alpha: 0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            k.kecamatanNama,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                        Text(
                          _selectedLayer == 'stok'
                              ? 'Stok: ${k.stokPersen.toStringAsFixed(0)}%'
                              : 'Harga: ${k.hargaTrend}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(k.statusStok),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600, color: color,),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;
  const _StatusPill(
      {required this.label,
      required this.count,
      required this.color,
      required this.bg,});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600,),
            ),
          ],
        ),
      ),
    );
  }
}
