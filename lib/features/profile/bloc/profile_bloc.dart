import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../data/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit,) async {
    emit(ProfileLoading());
    try {
      final data = await _repository.fetchProfile();
      final profile = UserProfile.fromJson(data);
      emit(ProfileLoaded(profile));
    } on DioException catch (e) {
      emit(
        ProfileError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal terhubung ke server',
          ),
        ),
      );
    } catch (e) {
      emit(ProfileError('Terjadi kesalahan: $e'));
    }
  }

  Future<void> _onUpdateProfile(
      UpdateProfile event, Emitter<ProfileState> emit,) async {
    final current = _currentProfile();
    if (current == null) return;
    emit(ProfileSaving(current));
    try {
      await _repository.updateProfile(
        name: event.name,
        phone: event.phone,
        kecamatanId: event.kecamatanId,
      );
      final updated = current.copyWith(
          name: event.name,
          phone: event.phone,
          kecamatanId: event.kecamatanId,);
      emit(ProfileSaved(updated, 'Profil berhasil diperbarui'));
    } on DioException catch (e) {
      emit(
        ProfileError(
          _repository.getErrorMessage(
            e,
            fallback: 'Gagal memperbarui profil',
          ),
          profile: current,
        ),
      );
    }
  }

  Future<void> _onChangePassword(
      ChangePassword event, Emitter<ProfileState> emit,) async {
    final current = _currentProfile();
    if (current == null) return;
    emit(ProfileSaving(current));
    try {
      await _repository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );
      emit(ProfileSaved(current, 'Kata sandi berhasil diubah'));
    } on DioException catch (e) {
      emit(
        ProfileError(
          _repository.getErrorMessage(e, fallback: 'Kata sandi lama salah'),
          profile: current,
        ),
      );
    }
  }

  UserProfile? _currentProfile() {
    if (state is ProfileLoaded) return (state as ProfileLoaded).profile;
    if (state is ProfileSaving) return (state as ProfileSaving).profile;
    if (state is ProfileSaved) return (state as ProfileSaved).profile;
    if (state is ProfileError) return (state as ProfileError).profile;
    return null;
  }
}
