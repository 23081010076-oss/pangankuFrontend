abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String? phone;
  final String? kecamatanId;

  UpdateProfile({required this.name, this.phone, this.kecamatanId});
}

class ChangePassword extends ProfileEvent {
  final String oldPassword;
  final String newPassword;

  ChangePassword({required this.oldPassword, required this.newPassword});
}
