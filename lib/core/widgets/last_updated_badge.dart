// Penjelasan file:
// Feature: core
// Layer: ui
// File: last_updated_badge
// Fungsi utama: File ini mengatur tampilan halaman, komponen visual, dan interaksi pengguna.
import 'dart:async';

import 'package:flutter/material.dart';

// Widget ini menampilkan teks seperti:
// "Terakhir diperbarui 10 dtk lalu"
// sehingga user tahu kapan data terakhir disegarkan.
class LastUpdatedBadge extends StatefulWidget {
  // Waktu terakhir data diperbarui.
  final DateTime? timestamp;

  // Warna latar badge.
  final Color backgroundColor;

  // Warna teks dan icon.
  final Color foregroundColor;

  // Awalan teks, misalnya "Terakhir diperbarui".
  final String prefix;

  const LastUpdatedBadge({
    super.key,
    required this.timestamp,
    this.backgroundColor = const Color(0xFFE8F5E9),
    this.foregroundColor = const Color(0xFF1B5E20),
    this.prefix = 'Terakhir diperbarui',
  });

  @override
  State<LastUpdatedBadge> createState() => _LastUpdatedBadgeState();
}

class _LastUpdatedBadgeState extends State<LastUpdatedBadge> {
  // Timer dipakai agar tulisan "10 dtk lalu" bisa berubah otomatis.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant LastUpdatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timestamp != widget.timestamp) {
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _timer?.cancel();

    // Jika timestamp belum ada, tidak perlu timer.
    if (widget.timestamp == null) {
      return;
    }

    // Update tampilan setiap 1 detik.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _relativeLabel(DateTime timestamp) {
    // Hitung selisih waktu dari sekarang ke timestamp terakhir.
    final seconds = DateTime.now().difference(timestamp).inSeconds;
    if (seconds <= 4) {
      return 'baru saja';
    }
    if (seconds < 60) {
      return '$seconds dtk lalu';
    }

    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '$minutes mnt lalu';
    }

    final hours = minutes ~/ 60;
    if (hours < 24) {
      return '$hours jam lalu';
    }

    final days = hours ~/ 24;
    return '$days hr lalu';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.timestamp;

    // Jika timestamp belum ada, tampilkan pesan default.
    final text = timestamp == null
        ? '${widget.prefix} belum tersedia'
        : '${widget.prefix} ${_relativeLabel(timestamp)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: widget.foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: widget.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
