abstract class NotifikasiEvent {}

class LoadNotifikasiList extends NotifikasiEvent {}

class MarkAsRead extends NotifikasiEvent {
  final String id;
  MarkAsRead(this.id);
}

class MarkAllRead extends NotifikasiEvent {}

class RefreshNotifikasi extends NotifikasiEvent {}
