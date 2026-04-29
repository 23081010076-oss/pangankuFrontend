// Penjelasan file:
// Feature: core
// Layer: core-network
// File: dio_client
// Fungsi utama: File ini mengatur koneksi HTTP dan kebutuhan jaringan utama aplikasi.
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

// DioClient adalah pusat koneksi HTTP aplikasi.
// Semua request API biasanya akan lewat object ini.
class DioClient {
  // Secure storage dipakai untuk menyimpan access token dan refresh token.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Future<String?>? _refreshFuture;

  void Function()? onSessionExpired;

  // Objek Dio ini akan dipakai repository untuk melakukan GET/POST/PUT/DELETE.
  late final Dio dio;

  DioClient() {
    // BaseOptions berisi konfigurasi dasar untuk semua request.
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Interceptor dipakai untuk "menyisipkan" logika tambahan
    // sebelum request dikirim atau saat response error diterima.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ambil access token dari secure storage.
          final token = await _storage.read(key: AppConstants.accessTokenKey);

          // Jika token ada, tempelkan ke header Authorization.
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Lanjutkan request ke proses berikutnya.
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (_shouldAttemptRefresh(e)) {
            final newAccessToken = await _refreshAccessToken();
            if (newAccessToken != null) {
              final retryOptions = e.requestOptions;
              retryOptions.extra['auth_retry'] = true;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              return handler.resolve(await dio.fetch(retryOptions));
            }

            await _clearAuthSession();
            onSessionExpired?.call();
          }
          handler.next(e);
        },
      ),
    );
  }

  bool _shouldAttemptRefresh(DioException e) {
    if (e.response?.statusCode != 401) return false;
    if (e.requestOptions.extra['auth_retry'] == true) return false;

    final path = e.requestOptions.path;
    return !path.endsWith('/auth/login') &&
        !path.endsWith('/auth/register') &&
        !path.endsWith('/auth/refresh');
  }

  Future<String?> _refreshAccessToken() {
    final existingRefresh = _refreshFuture;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final future = _doRefreshAccessToken();
    _refreshFuture = future;
    return future.whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _doRefreshAccessToken() async {
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = res.data['access_token']?.toString();
      final newRefreshToken = res.data['refresh_token']?.toString();
      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return null;
      }

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccessToken,
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearAuthSession() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userRoleKey);
    await _storage.delete(key: AppConstants.userNameKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }

  // Helper ini mengubah error teknis dari Dio
  // menjadi pesan yang lebih mudah dipahami pengguna.
  String getErrorMessage(DioException e) {
    if (e.response?.data is Map && e.response?.data['error'] != null) {
      return e.response?.data['error'];
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout, coba lagi';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request dibatalkan';
      default:
        return 'Gagal terhubung ke server';
    }
  }
}
