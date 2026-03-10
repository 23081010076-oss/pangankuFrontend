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

abstract class NotifikasiState {}

class NotifikasiInitial extends NotifikasiState {}

class NotifikasiLoading extends NotifikasiState {}

class NotifikasiLoaded extends NotifikasiState {
  final List<NotifikasiItem> items;
  final int unreadCount;

  NotifikasiLoaded(this.items)
      : unreadCount = items.where((n) => !n.isRead).length;
}

class NotifikasiError extends NotifikasiState {
  final String message;
  NotifikasiError(this.message);
}
