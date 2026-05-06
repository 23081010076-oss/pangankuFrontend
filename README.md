# PanganKu Mobile

Aplikasi mobile untuk sistem informasi ketahanan pangan Kabupaten Lamongan.

## Features

- 🔐 Autentikasi (Login, Register, Logout)
- 📊 Dashboard dengan statistik real-time
- 💰 Monitoring harga komoditas
- 📈 Prediksi harga (Machine Learning - DP + EMA)
- 🗺️ Peta distribusi pangan
- 🚨 Alert & notifikasi anomali harga
- 📱 Offline support dengan local cache

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: BLoC (flutter_bloc)
- **Routing**: go_router
- **HTTP Client**: Dio
- **Local Storage**: flutter_secure_storage, Hive
- **Charts**: fl_chart
- **Maps**: google_maps_flutter

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 atau lebih baru
- Dart SDK 3.0.0 atau lebih baru
- Android Studio atau VS Code
- Backend API running (lihat panganku_backend)

### Installation

1. Clone repository:

```bash
git clone <repository-url>
cd panganku_mobile
```

2. Install dependencies:

```bash
flutter pub get
```

3. Konfigurasi base URL API:

Aplikasi ini membaca URL API dari compile-time variable `API_BASE_URL`.
Tidak perlu mengubah source code untuk deploy.

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

4. Run app:

```bash
# Debug mode
flutter run

# Release mode
flutter run --release --dart-define=API_BASE_URL=https://your-api-url/api/v1
```

## Project Structure

```
lib/
├── core/
│   ├── constants/      # Konstanta app
│   ├── network/        # HTTP client & interceptors
│   └── theme/          # Theme & styling
├── features/
│   ├── auth/           # Authentication
│   │   ├── bloc/
│   │   └── pages/
│   ├── dashboard/      # Dashboard
│   └── harga/          # Harga komoditas
└── main.dart
```

## Testing

Run unit & widget tests:

```bash
flutter test
```

Run integration tests:

```bash
flutter test integration_test
```

## Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-url/api/v1

# Split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi --dart-define=API_BASE_URL=https://your-api-url/api/v1
```

## Build Web

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-api-url/api/v1
```

## Build iOS

```bash
flutter build ios --release --dart-define=API_BASE_URL=https://your-api-url/api/v1
```

## Environment Variables

Flutter app memakai `--dart-define`, bukan file `.env` runtime:

```
API_BASE_URL=https://your-api-url/api/v1
```

## Contributing

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## License

Copyright © 2026 Diskominfo Kabupaten Lamongan
