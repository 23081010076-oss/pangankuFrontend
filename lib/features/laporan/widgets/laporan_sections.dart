part of '../pages/laporan_page.dart';

extension _LaporanPageSections on _LaporanPageState {
  Widget _buildLaporanList(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated ? authState.role : '';
    final canEdit = role == 'admin' || role == 'petugas';

    return BlocBuilder<LaporanBloc, LaporanState>(
      builder: (ctx, state) {
        if (state is LaporanLoading || state is LaporanSubmitting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (state is LaporanError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFEF5350),),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      ctx.read<LaporanBloc>().add(LoadLaporanList()),
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF2E7D32),
                  ),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is LaporanLoaded) {
          if (state.laporanList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_off_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada laporan darurat',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async {
              final bloc = ctx.read<LaporanBloc>();
              bloc.add(RefreshLaporan());
              await bloc.stream.firstWhere(
                (next) => next is LaporanLoaded || next is LaporanError,
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: state.laporanList.length,
              itemBuilder: (_, i) =>
                  _buildLaporanCard(ctx, state.laporanList[i], canEdit),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildLaporanCard(
    BuildContext ctx,
    LaporanItem item,
    bool canEdit,
  ) {
    final statusColor = item.status == 'selesai'
        ? const Color(0xFF2E7D32)
        : item.status == 'proses'
            ? Colors.orange
            : const Color(0xFFC62828);
    final statusBg = item.status == 'selesai'
        ? const Color(0xFFE8F5E9)
        : item.status == 'proses'
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFFFEBEE);

    final tanggal = DateTime.tryParse(item.tanggal);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.jenisMasalah,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.kecamatanNama,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (item.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star,
                  size: 13,
                  color: i < item.prioritas ? Colors.amber : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Prioritas ${item.prioritas}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
              if (tanggal != null)
                Text(
                  DateFormat('dd/MM/yy').format(tanggal),
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                _statusDropdown(ctx, item),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(ctx, item.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusDropdown(BuildContext ctx, LaporanItem item) {
    const statuses = ['baru', 'proses', 'selesai'];
    return DropdownButton<String>(
      value: statuses.contains(item.status) ? item.status : 'baru',
      isDense: true,
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 12, color: Color(0xFF212121)),
      items: statuses
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (newStatus) {
        if (newStatus != null && newStatus != item.status) {
          ctx.read<LaporanBloc>().add(
                UpdateLaporanStatus(id: item.id, status: newStatus),
              );
        }
      },
    );
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<LaporanBloc>().add(DeleteLaporan(id));
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

  Widget? _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateLaporan(context),
      label: const Text('Buat Laporan'),
      icon: const Icon(Icons.add),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    );
  }

  void _showCreateLaporan(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<LaporanBloc>(),
        child: const _CreateLaporanSheet(),
      ),
    );
  }
}
