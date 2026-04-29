// Penjelasan file:
// Feature: profile
// Layer: logic
// File: profile_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String? kecamatanId;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.kecamatanId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'petani',
      phone: json['phone']?.toString() ?? '',
      kecamatanId: json['kecamatan_id']?.toString(),
    );
  }

  UserProfile copyWith({String? name, String? phone, String? kecamatanId}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      kecamatanId: kecamatanId ?? this.kecamatanId,
    );
  }
}

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class ProfileState {}

// State ini menunjukkan kondisi 'ProfileInitial' pada fitur ini.
class ProfileInitial extends ProfileState {}

// State ini menunjukkan kondisi 'ProfileLoading' pada fitur ini.
class ProfileLoading extends ProfileState {}

// State ini menunjukkan kondisi 'ProfileLoaded' pada fitur ini.
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  ProfileLoaded(this.profile);
}

// State ini menunjukkan kondisi 'ProfileSaving' pada fitur ini.
class ProfileSaving extends ProfileState {
  final UserProfile profile;
  ProfileSaving(this.profile);
}

// State ini menunjukkan kondisi 'ProfileSaved' pada fitur ini.
class ProfileSaved extends ProfileState {
  final UserProfile profile;
  final String message;
  ProfileSaved(this.profile, this.message);
}

// State ini menunjukkan kondisi 'ProfileError' pada fitur ini.
class ProfileError extends ProfileState {
  final String message;
  final UserProfile? profile;
  ProfileError(this.message, {this.profile});
}
