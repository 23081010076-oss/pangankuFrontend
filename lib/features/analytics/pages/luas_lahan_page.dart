// Doc:
// Tujuan: Menampilkan ringkasan luas lahan komoditas, fallback ringkasan, dan dropdown detail luas lahan per kecamatan.
// Dipakai oleh: AnalyticsPage melalui tombol "Lihat Luas Lahan".
// Dependensi utama: DashboardStats, KomoditasTrend, LuasLahanKecamatan.
// Fungsi public/utama: LuasLahanPage, _buildKomoditasDropdown, _buildKecamatanRow, _buildSummaryFallback, _formatHa.
// Side effect penting: Tidak ada I/O langsung; hanya render data analytics yang sudah dimuat.
import 'package:flutter/material.dart';

import '../bloc/analytics_state.dart';

class LuasLahanPage extends StatelessWidget {
  const LuasLahanPage({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [...stats.komoditasTrend]
      ..sort((a, b) => b.luasLahan.compareTo(a.luasLahan));
    final maxLahan = items.isEmpty || items.first.luasLahan <= 0
        ? 1.0
        : items.first.luasLahan;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Luas Lahan Komoditas'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Data luas lahan belum tersedia.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _buildKomoditasDropdown(items[i], maxLahan),
            ),
    );
  }

  Widget _buildKomoditasDropdown(KomoditasTrend k, double maxLahan) {
    final progress = (k.luasLahan / maxLahan).clamp(0.0, 1.0);
    final detail = [...k.luasLahanByKecamatan]
      ..sort((a, b) => b.luasHa.compareTo(a.luasHa));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: const Color(0xFF2E7D32),
        collapsedIconColor: const Color(0xFF78909C),
        title: Row(
          children: [
            Expanded(
              child: Text(
                k.nama,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Text(
              '${_formatHa(k.luasLahan)} Ha',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: const Color(0xFFE8F5E9),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF43A047)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail.isEmpty
                    ? 'Detail kecamatan belum diterima dari server'
                    : '${detail.length} kecamatan tersedia. Ketuk untuk lihat detail.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
              ),
            ],
          ),
        ),
        children: [
          if (detail.isEmpty)
            _buildSummaryFallback(k)
          else
            ...detail.map((item) => _buildKecamatanRow(item, k.luasLahan)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                'Rata-rata harga: Rp ${k.avgHarga.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
              ),
              Text(
                'Total stok: ${k.totalStok.toStringAsFixed(0)} kg',
                style: const TextStyle(fontSize: 11, color: Color(0xFF616161)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryFallback(KomoditasTrend k) {
    final hasTotal = k.luasLahan > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEFD8)),
      ),
      child: Text(
        hasTotal
            ? 'Total luas lahan ${k.nama} sudah tersedia (${_formatHa(k.luasLahan)} Ha). Restart backend / refresh data agar rincian per kecamatan ikut tampil.'
            : 'Data luas lahan per kecamatan belum tersedia.',
        style: const TextStyle(
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF4F6F52),
        ),
      ),
    );
  }

  Widget _buildKecamatanRow(LuasLahanKecamatan item, double totalLahan) {
    final progress =
        totalLahan <= 0 ? 0.0 : (item.luasHa / totalLahan).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.kecamatanNama,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    backgroundColor: const Color(0xFFF1F8E9),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatHa(item.luasHa)} Ha',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHa(double value) {
    final fixed = value >= 100 ? 0 : 1;
    return value.toStringAsFixed(fixed);
  }
}
