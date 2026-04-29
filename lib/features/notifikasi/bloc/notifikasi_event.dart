// Penjelasan file:
// Feature: notifikasi
// Layer: logic
// File: notifikasi_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class NotifikasiEvent {}

// Event ini mewakili aksi 'LoadNotifikasiList' yang akan diproses oleh bloc.
class LoadNotifikasiList extends NotifikasiEvent {}

// Event ini mewakili aksi 'MarkAsRead' yang akan diproses oleh bloc.
class MarkAsRead extends NotifikasiEvent {
  final String id;
  MarkAsRead(this.id);
}

// Event ini mewakili aksi 'MarkAllRead' yang akan diproses oleh bloc.
class MarkAllRead extends NotifikasiEvent {}

// Event ini mewakili aksi 'RefreshNotifikasi' yang akan diproses oleh bloc.
class RefreshNotifikasi extends NotifikasiEvent {}
