import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Request interceptor untuk menambahkan token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized - coba refresh token
          if (e.response?.statusCode == 401) {
            final refreshToken =
                await _storage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              try {
                final res = await Dio().post(
                  '${AppConstants.baseUrl}/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                final newAccessToken = res.data['access_token'];
                final newRefreshToken = res.data['refresh_token'];

                await _storage.write(
                    key: AppConstants.accessTokenKey, value: newAccessToken,);
                await _storage.write(
                    key: AppConstants.refreshTokenKey, value: newRefreshToken,);

                // Retry original request dengan token baru
                e.requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                return handler.resolve(await dio.fetch(e.requestOptions));
              } catch (_) {
                // Refresh gagal, hapus semua data dan redirect ke login
                await _storage.deleteAll();
                // TODO: Trigger navigasi ke login via event bus atau router
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  // Helper untuk handle error
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
