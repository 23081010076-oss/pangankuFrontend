// Penjelasan file:
// Feature: profile
// Layer: logic
// File: profile_event
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
// Base event ini menjadi induk untuk semua aksi yang bisa dikirim ke bloc fitur ini.
abstract class ProfileEvent {}

// Event ini mewakili aksi 'LoadProfile' yang akan diproses oleh bloc.
class LoadProfile extends ProfileEvent {}

// Event ini mewakili aksi 'UpdateProfile' yang akan diproses oleh bloc.
class UpdateProfile extends ProfileEvent {
  final String name;
  final String? phone;
  final String? kecamatanId;

  UpdateProfile({required this.name, this.phone, this.kecamatanId});
}

// Event ini mewakili aksi 'ChangePassword' yang akan diproses oleh bloc.
class ChangePassword extends ProfileEvent {
  final String oldPassword;
  final String newPassword;

  ChangePassword({required this.oldPassword, required this.newPassword});
}
