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
      role: json['role']?.toString() ?? 'publik',
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

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  ProfileLoaded(this.profile);
}

class ProfileSaving extends ProfileState {
  final UserProfile profile;
  ProfileSaving(this.profile);
}

class ProfileSaved extends ProfileState {
  final UserProfile profile;
  final String message;
  ProfileSaved(this.profile, this.message);
}

class ProfileError extends ProfileState {
  final String message;
  final UserProfile? profile;
  ProfileError(this.message, {this.profile});
}
