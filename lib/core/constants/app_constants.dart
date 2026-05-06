// Penjelasan file:
// Feature: core
// Layer: core-constants
// File: app_constants
// Fungsi utama: File ini menyimpan konstanta global yang dipakai berulang di aplikasi.
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

// Kumpulan konstanta global aplikasi.
// File ini dipakai untuk nilai yang sering digunakan berulang,
// misalnya base URL API dan key penyimpanan token/user.
class AppConstants {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  // Auto-detect platform untuk baseUrl yang tepat
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _trimTrailingSlash(_configuredBaseUrl);
    }

    if (kIsWeb) {
      // Web: gunakan localhost
      return 'http://localhost:8080/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator memakai 10.0.2.2 untuk mengarah ke host machine.
        // Untuk HP fisik, jalankan dengan --dart-define API_BASE_URL.
        return 'http://10.0.2.2:8080/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080/api/v1';
    }
  }

  static String get apiOrigin {
    final url = baseUrl;
    if (url.endsWith('/api/v1')) {
      return url.substring(0, url.length - '/api/v1'.length);
    }
    return url;
  }

  static String _trimTrailingSlash(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  // Key di bawah ini dipakai saat menyimpan data login ke secure storage.
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String userIdKey = 'user_id';
}
