import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DioClient _client;

  ProfileBloc(this._client) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<ChangePassword>(_onChangePassword);
  }

  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit,) async {
    emit(ProfileLoading());
    try {
      final response = await _client.dio.get('/users/profile');
      if (response.statusCode == 200) {
        final profile =
            UserProfile.fromJson(response.data as Map<String, dynamic>);
        emit(ProfileLoaded(profile));
      } else {
        emit(ProfileError('Gagal memuat profil'));
      }
    } on DioException catch (e) {
      emit(ProfileError(
          e.response?.data['error'] ?? 'Gagal terhubung ke server',),);
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
      final response = await _client.dio.put('/users/profile', data: {
        'name': event.name,
        if (event.phone != null && event.phone!.isNotEmpty)
          'phone': event.phone,
        if (event.kecamatanId != null) 'kecamatan_id': event.kecamatanId,
      },);
      if (response.statusCode == 200) {
        final updated = current.copyWith(
            name: event.name,
            phone: event.phone,
            kecamatanId: event.kecamatanId,);
        emit(ProfileSaved(updated, 'Profil berhasil diperbarui'));
      } else {
        emit(ProfileError('Gagal memperbarui profil', profile: current));
      }
    } on DioException catch (e) {
      emit(ProfileError(e.response?.data['error'] ?? 'Gagal memperbarui profil',
          profile: current,),);
    }
  }

  Future<void> _onChangePassword(
      ChangePassword event, Emitter<ProfileState> emit,) async {
    final current = _currentProfile();
    if (current == null) return;
    emit(ProfileSaving(current));
    try {
      final response = await _client.dio.put('/users/change-password', data: {
        'old_password': event.oldPassword,
        'new_password': event.newPassword,
      },);
      if (response.statusCode == 200) {
        emit(ProfileSaved(current, 'Kata sandi berhasil diubah'));
      } else {
        emit(ProfileError('Gagal mengubah kata sandi', profile: current));
      }
    } on DioException catch (e) {
      emit(ProfileError(e.response?.data['error'] ?? 'Kata sandi lama salah',
          profile: current,),);
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
