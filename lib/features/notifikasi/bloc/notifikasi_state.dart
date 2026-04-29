// Penjelasan file:
// Feature: notifikasi
// Layer: logic
// File: notifikasi_state
// Fungsi utama: File ini mengatur alur proses, event, state, dan aturan aplikasi.
class NotifikasiItem {
  final String id;
  final String judul;
  final String isi;
  final String tipe; // info|warning|error|success
  final bool isRead;
  final String createdAt;

  const NotifikasiItem({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tipe,
    required this.isRead,
    required this.createdAt,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> json) {
    return NotifikasiItem(
      id: json['id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? 'info',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  NotifikasiItem copyWith({bool? isRead}) => NotifikasiItem(
        id: id,
        judul: judul,
        isi: isi,
        tipe: tipe,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

// Base state ini menjadi induk untuk semua kondisi tampilan atau proses pada fitur ini.
abstract class NotifikasiState {}

// State ini menunjukkan kondisi 'NotifikasiInitial' pada fitur ini.
class NotifikasiInitial extends NotifikasiState {}

// State ini menunjukkan kondisi 'NotifikasiLoading' pada fitur ini.
class NotifikasiLoading extends NotifikasiState {}

// State ini menunjukkan kondisi 'NotifikasiLoaded' pada fitur ini.
class NotifikasiLoaded extends NotifikasiState {
  final List<NotifikasiItem> items;
  final int unreadCount;

  NotifikasiLoaded(this.items)
      : unreadCount = items.where((n) => !n.isRead).length;
}

// State ini menunjukkan kondisi 'NotifikasiError' pada fitur ini.
class NotifikasiError extends NotifikasiState {
  final String message;
  NotifikasiError(this.message);
}
