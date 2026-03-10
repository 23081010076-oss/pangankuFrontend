import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AppConstants {
  // Auto-detect platform untuk baseUrl yang tepat
  static String get baseUrl {
    if (kIsWeb) {
      // Web: gunakan localhost
      return 'http://localhost:8080/api/v1';
    } else if (Platform.isAndroid) {
      // Emulator Android: 10.0.2.2 = host machine localhost
      return 'http://10.0.2.2:8080/api/v1';
    } else if (Platform.isIOS) {
      // iOS Simulator: langsung localhost
      return 'http://localhost:8080/api/v1';
    } else {
      // Desktop (Windows/Linux/macOS): localhost
      return 'http://localhost:8080/api/v1';
    }
  }

  // Untuk production (uncomment dan ganti dengan domain production)
  // static const String baseUrl = 'https://api.panganku.lamongan.go.id/api/v1';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userNameKey = 'user_name';
  static const String userIdKey = 'user_id';
}
