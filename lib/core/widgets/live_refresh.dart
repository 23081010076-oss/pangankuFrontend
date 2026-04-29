// Penjelasan file:
// Feature: core
// Layer: ui
// File: live_refresh
// Fungsi utama: File ini mengatur tampilan halaman, komponen visual, dan interaksi pengguna.
import 'dart:async';

import 'package:flutter/material.dart';

// Widget pembungkus ini dipakai untuk membuat halaman
// refresh otomatis tiap beberapa detik atau saat app aktif lagi.
class LiveRefresh extends StatefulWidget {
  // Child adalah halaman/widget yang dibungkus.
  final Widget child;

  // Fungsi yang dipanggil saat refresh otomatis dijalankan.
  final FutureOr<void> Function() onRefresh;

  // Jarak waktu antar refresh.
  final Duration interval;

  // Jika true, saat app kembali aktif dari background maka refresh dijalankan.
  final bool refreshOnResume;

  const LiveRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.interval = const Duration(seconds: 30),
    this.refreshOnResume = true,
  });

  @override
  State<LiveRefresh> createState() => _LiveRefreshState();
}

class _LiveRefreshState extends State<LiveRefresh> with WidgetsBindingObserver {
  // Timer untuk refresh berkala.
  Timer? _timer;

  // Flag ini mencegah refresh jalan bersamaan.
  bool _isRefreshing = false;

  // Menyimpan status hidup aplikasi saat ini.
  AppLifecycleState? _lifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleState = WidgetsBinding.instance.lifecycleState;
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.resumed && widget.refreshOnResume) {
      _runRefresh();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    // Jalankan refresh berkala sesuai interval yang diberikan.
    _timer = Timer.periodic(widget.interval, (_) => _runRefresh());
  }

  Future<void> _runRefresh() async {
    // Jangan refresh kalau widget sudah tidak aktif
    // atau sedang ada refresh lain yang berjalan.
    if (!mounted || _isRefreshing) {
      return;
    }

    // Jangan refresh saat app sedang tidak berada di foreground.
    if (_lifecycleState != null &&
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    _isRefreshing = true;
    try {
      // Jalankan callback refresh dari halaman yang memakai widget ini.
      await widget.onRefresh();
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
