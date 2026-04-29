// Penjelasan file:
// Feature: analytics
// Layer: logic
// File: analytics_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class AnalyticsEvent {}

// Event ini mewakili aksi 'LoadDashboardStats' yang akan diproses oleh bloc.
class LoadDashboardStats extends AnalyticsEvent {
  final String periode;
  LoadDashboardStats({this.periode = '7d'});
}

// Event ini mewakili aksi 'RefreshDashboardStats' yang akan diproses oleh bloc.
class RefreshDashboardStats extends AnalyticsEvent {
  final String periode;
  RefreshDashboardStats({this.periode = '7d'});
}

// Event ini mewakili aksi 'LoadStatusPangan' yang akan diproses oleh bloc.
class LoadStatusPangan extends AnalyticsEvent {}
