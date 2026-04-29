// Widget untuk menampilkan gambar komoditas dengan fallback ke emoji
import 'package:flutter/material.dart';

class KomoditasImage extends StatelessWidget {
  final String? gambarUrl;
  final String nama;
  final String kategori;
  final double size;
  final Color backgroundColor;

  const KomoditasImage({
    super.key,
    this.gambarUrl,
    required this.nama,
    required this.kategori,
    this.size = 46,
    this.backgroundColor = const Color(0xFFE8F5E9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Jika ada gambar URL dan valid, tampilkan gambar
    if (gambarUrl != null && gambarUrl!.isNotEmpty) {
      // Ambil base URL dari environment atau gunakan default
      const baseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8080',
      );

      final fullUrl =
          gambarUrl!.startsWith('http') ? gambarUrl! : '$baseUrl$gambarUrl';

      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Jika gagal load gambar, tampilkan emoji
          return Center(
            child: Text(
              _getEmoji(nama, kategori),
              style: TextStyle(fontSize: size * 0.48),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2E7D32),
                ),
              ),
            ),
          );
        },
      );
    }

    // Fallback ke emoji jika tidak ada gambar
    return Center(
      child: Text(
        _getEmoji(nama, kategori),
        style: TextStyle(fontSize: size * 0.48),
      ),
    );
  }

  String _getEmoji(String nama, String kategori) {
    final n = nama.toLowerCase();
    if (n.contains('beras')) return '🌾';
    if (n.contains('jagung')) return '🌽';
    if (n.contains('kedelai')) return '🫘';
    if (n.contains('kacang')) return '🥜';
    if (n.contains('cabai') || n.contains('cabe')) return '🌶️';
    if (n.contains('bawang')) return '🧅';
    if (n.contains('telur')) return '🥚';
    if (n.contains('daging')) return '🥩';
    if (n.contains('ayam')) return '🍗';
    if (n.contains('ikan')) return '🐟';
    if (n.contains('gula')) return '🍬';
    if (n.contains('minyak')) return '🫙';

    // Fallback berdasarkan kategori
    switch (kategori.toLowerCase()) {
      case 'padi-padian':
        return '🌾';
      case 'kacang-kacangan':
        return '🥜';
      case 'sayuran':
        return '🥬';
      case 'hewani':
      case 'protein':
        return '🥩';
      case 'gula':
        return '🍬';
      case 'minyak':
        return '🫙';
      default:
        return '🛒';
    }
  }
}
