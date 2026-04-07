import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/notifikasi_bloc.dart';
import '../bloc/notifikasi_event.dart';
import '../bloc/notifikasi_state.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotifikasiBloc, NotifikasiState>(
      builder: (context, state) {
        final unread = state is NotifikasiLoaded ? state.unreadCount : 0;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async =>
                context.read<NotifikasiBloc>().add(RefreshNotifikasi()),
            child: CustomScrollView(
              slivers: [
                _buildHeader(context, unread),
                if (state is NotifikasiLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                else if (state is NotifikasiError)
                  SliverFillRemaining(
                    child: _buildError(context, (state).message),
                  )
                else if (state is NotifikasiLoaded)
                  _buildList(context, state)
                else
                  const SliverFillRemaining(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int unread) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF9C27B0)],
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unread > 0
                            ? 'Notifikasi  ($unread belum dibaca)'
                            : 'Notifikasi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Peringatan & informasi sistem',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (unread > 0)
                  TextButton(
                    onPressed: () =>
                        context.read<NotifikasiBloc>().add(MarkAllRead()),
                    child: const Text(
                      'Tandai Semua',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildList(BuildContext context, NotifikasiLoaded state) {
    if (state.items.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 80),
          const Center(
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('Tidak ada notifikasi',
                    style: TextStyle(color: Colors.grey),),
              ],
            ),
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _buildTile(context, state.items[i]),
        childCount: state.items.length,
      ),
    );
  }

  Widget _buildTile(BuildContext context, NotifikasiItem item) {
    final tipeColor = _tipeColor(item.tipe);
    final tipeIcon = _tipeIcon(item.tipe);
    final dt = DateTime.tryParse(item.createdAt);
    final timeStr = dt != null
        ? DateFormat('dd MMM, HH:mm', 'id').format(dt.toLocal())
        : '';

    return GestureDetector(
      onTap: () {
        if (!item.isRead) {
          context.read<NotifikasiBloc>().add(MarkAsRead(item.id));
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : tipeColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead ? Colors.grey[200]! : tipeColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tipeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tipeIcon, size: 20, color: tipeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.judul,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: const Color(0xFF212121),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tipeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.isi,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
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

  Widget _buildError(BuildContext context, String message) {
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
                  context.read<NotifikasiBloc>().add(LoadNotifikasiList()),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'warning':
        return const Color(0xFFF57C00);
      case 'error':
        return const Color(0xFFC62828);
      case 'success':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF1565C0);
    }
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }
}
