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

Edit `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://your-api-url/api/v1';
```

4. Run app:

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
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
flutter build apk --release

# Split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi
```

## Build iOS

```bash
flutter build ios --release
```

## Environment Variables

Buat file `.env` di root project:

```
API_BASE_URL=http://your-api-url/api/v1
GOOGLE_MAPS_API_KEY=your_maps_key
```

## Contributing

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## License

Copyright © 2026 Diskominfo Kabupaten Lamongan
