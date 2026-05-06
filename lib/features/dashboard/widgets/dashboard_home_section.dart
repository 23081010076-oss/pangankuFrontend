// Doc:
// Tujuan: Menyusun beranda dashboard termasuk header, ringkasan status stok, grafik ringkas, menu cepat, dan alert operasional.
// Dipakai oleh: dashboard_page.dart melalui part _HomePage sebagai tab beranda utama.
// Dependensi utama: AuthBloc, AnalyticsBloc, NotifikasiBloc, GoRouter, widget chart dashboard dan badge shared.
// Fungsi public/utama: _HomePage.build, _buildHeader, _buildStatusCards, _buildMenuGrid, _buildAlerts.
// Side effect penting: Navigasi ke route fitur, membuka bottom sheet detail kecamatan, membaca state BLoC untuk render UI.
part of '../pages/dashboard_page.dart';

class _HomePage extends StatelessWidget {
  final void Function(int) onTabChange;
  final DateTime? lastUpdatedAt;

  const _HomePage({required this.onTabChange, this.lastUpdatedAt});

  String _currentRole(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.role : 'petani';
  }

  bool _isPrivilegedRole(String role) {
    return role == 'admin' || role == 'petugas';
  }

  @override
  Widget build(BuildContext context) {
    final role = _currentRole(context);
    final isPrivileged = _isPrivilegedRole(role);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: LastUpdatedBadge(timestamp: lastUpdatedAt),
                ),
                const SizedBox(height: 14),
                _buildStatusCards(context),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: 20),
                Text(
                  isPrivileged ? 'Menu Operasional' : 'Menu Informasi',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(context),
                if (isPrivileged) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Peringatan Aktif',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF424242),
                        ),
                      ),
                      BlocBuilder<AnalyticsBloc, AnalyticsState>(
                        builder: (ctx, s) {
                          final n =
                              s is AnalyticsLoaded ? s.stats.alertCount : 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$n Aktif',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFC62828),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAlerts(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1),
          end: Alignment(0.4, 1),
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (ctx, state) {
                            final name = state is AuthAuthenticated
                                ? state.name
                                : 'Pengguna';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang,',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/notifikasi'),
                        child: Stack(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            BlocBuilder<NotifikasiBloc, NotifikasiState>(
                              builder: (ctx, state) {
                                if (state is NotifikasiLoaded &&
                                    state.unreadCount > 0) {
                                  return Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5722),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onTabChange(5),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (ctx, state) {
        String aman = '-';
        String waspada = '-';
        String kritis = '-';
        List<String> listAman = [];
        List<String> listWaspada = [];
        List<String> listKritis = [];

        if (state is AnalyticsLoaded) {
          aman = state.stats.kecamatanAman.toString();
          waspada = state.stats.kecamatanWaspada.toString();
          kritis = state.stats.kecamatanKritis.toString();
          listAman = state.stats.listKecamatanAman;
          listWaspada = state.stats.listKecamatanWaspada;
          listKritis = state.stats.listKecamatanKritis;
        }

        final cards = [
          {
            'label': 'Aman',
            'value': aman,
            'list': listAman,
            'color': const Color(0xFF2E7D32),
            'bg': const Color(0xFFE8F5E9),
            'icon': Icons.check_circle_outline,
          },
          {
            'label': 'Waspada',
            'value': waspada,
            'list': listWaspada,
            'color': const Color(0xFFF57C00),
            'bg': const Color(0xFFFFF3E0),
            'icon': Icons.warning_amber_outlined,
          },
          {
            'label': 'Kritis',
            'value': kritis,
            'list': listKritis,
            'color': const Color(0xFFC62828),
            'bg': const Color(0xFFFFEBEE),
            'icon': Icons.error_outline,
          },
        ];
        return SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              final kecList = card['list'] as List<String>;
              return SizedBox(
                width: 220,
                child: GestureDetector(
                  onTap: kecList.isEmpty
                      ? null
                      : () {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (ctx) => _buildKecamatanListSheet(
                              card['label'] as String,
                              card['color'] as Color,
                              kecList,
                            ),
                          );
                        },
                  child: _buildDashboardStatusCard(
                    label: card['label'] as String,
                    value: card['value'] as String,
                    color: card['color'] as Color,
                    bg: card['bg'] as Color,
                    icon: card['icon'] as IconData,
                    detailCount: kecList.length,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboardStatusCard({
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required IconData icon,
    required int detailCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$detailCount area',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2933),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detailCount > 0
                ? 'Ketuk untuk lihat daftar kecamatan.'
                : 'Belum ada wilayah yang perlu dirinci.',
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: Colors.blueGrey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKecamatanListSheet(
    String label,
    Color color,
    List<String> list,
  ) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: color),
                const SizedBox(width: 8),
                Text(
                  'Kecamatan $label',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 30),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (ctx, i) {
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    radius: 12,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    list[i],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (_, state) => _ChartCardWidget(state: state),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final role = _currentRole(context);
    final isPrivileged = _isPrivilegedRole(role);
    final menus = isPrivileged
        ? [
            {
              'icon': Icons.bar_chart_outlined,
              'label': 'Analitik\nPangan',
              'color': const Color(0xFF7B1FA2),
              'index': -3,
            },
            {
              'icon': Icons.auto_graph_outlined,
              'label': 'Prediksi\nHarga',
              'color': const Color(0xFF512DA8),
              'index': -4,
            },
            {
              'icon': Icons.map_outlined,
              'label': 'Peta\nSebaran',
              'color': const Color(0xFF00838F),
              'index': -1,
            },
          ]
        : [
            {
              'icon': Icons.inventory_2,
              'label': 'Stok\nPangan',
              'color': const Color(0xFFF57C00),
              'index': 2,
            },
            {
              'icon': Icons.bar_chart_outlined,
              'label': 'Analitik\nPangan',
              'color': const Color(0xFF7B1FA2),
              'index': -3,
            },
            {
              'icon': Icons.auto_graph_outlined,
              'label': 'Prediksi\nHarga',
              'color': const Color(0xFF512DA8),
              'index': -4,
            },
            {
              'icon': Icons.map_outlined,
              'label': 'Peta\nSebaran',
              'color': const Color(0xFF00838F),
              'index': -1,
            },
          ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isPrivileged ? 3 : 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isPrivileged ? 1.0 : 0.95,
      ),
      itemCount: menus.length,
      itemBuilder: (context, idx) {
        final menu = menus[idx];
        return GestureDetector(
          onTap: () {
            final navIdx = menu['index'] as int;
            if (navIdx >= 0) {
              onTabChange(navIdx);
            } else if (navIdx == -1) {
              context.push('/peta');
            } else if (navIdx == -3) {
              context.push('/analytics');
            } else if (navIdx == -4) {
              context.push('/harga/forecast');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (menu['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    menu['icon'] as IconData,
                    size: 22,
                    color: menu['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  menu['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlerts() {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsLoaded || state.stats.activeAlerts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Belum ada laporan darurat aktif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF616161),
              ),
            ),
          );
        }

        return Column(
          children: state.stats.activeAlerts.map((alert) {
            final bool prioritasKritis = alert.prioritas <= 1;
            final bool prioritasSedang = alert.prioritas == 2;
            final Color color = prioritasKritis
                ? const Color(0xFFC62828)
                : prioritasSedang
                    ? const Color(0xFFF57C00)
                    : const Color(0xFF1976D2);
            final Color bg = prioritasKritis
                ? const Color(0xFFFFEBEE)
                : prioritasSedang
                    ? const Color(0xFFFFF3E0)
                    : const Color(0xFFE3F2FD);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      alert.status == 'proses'
                          ? Icons.sync_outlined
                          : Icons.warning_amber_outlined,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.jenisMasalah,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        Text(
                          'Kec. ${alert.kecamatanNama} - Prioritas ${alert.prioritas}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
