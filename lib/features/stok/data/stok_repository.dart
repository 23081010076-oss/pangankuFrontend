// Penjelasan file:
// Feature: stok
// Layer: api
// File: stok_repository
// Fungsi utama: File ini mengatur komunikasi data dengan backend atau sumber data aplikasi.
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

// Repository ini bertugas sebagai penghubung antara fitur stok
// dengan API backend. Jadi halaman atau bloc tidak perlu tahu detail request HTTP.
// Repository ini menjadi jembatan antara fitur dan sumber data/backend.
class StokRepository {
  // DioClient adalah pembungkus koneksi HTTP utama aplikasi.
  final DioClient _client;

  // Repository menerima DioClient dari luar agar lebih mudah dipakai ulang.
  StokRepository(this._client);

  // Mengambil daftar stok dari backend.
  // Filter komoditas dan kecamatan bersifat opsional.
// Method ini mengambil data dari backend lalu mengubahnya ke bentuk yang aman dipakai di aplikasi.
  Future<List<Map<String, dynamic>>> fetchStokList({
    String? komoditasId,
    String? kecamatanId,
  }) async {
    // Default ambil sampai 200 data agar halaman stok punya cukup data.
    final params = <String, dynamic>{'limit': 200};

    // Tambahkan filter komoditas jika dipilih user.
    if (komoditasId != null) {
      params['komoditas_id'] = komoditasId;
    }

    // Tambahkan filter kecamatan jika dipilih user.
    if (kecamatanId != null) {
      params['kecamatan_id'] = kecamatanId;
    }

    // Kirim request GET ke endpoint /stok dengan query parameter di atas.
    final response = await _client.dio.get('/stok', queryParameters: params);

    // Ambil payload utama dari response.
    final data = response.data;

    // Backend bisa mengirim data dalam bentuk { data: [...] }
    // atau langsung list, jadi kita amankan keduanya.
    final list = data['data'] ?? (data is List ? data : []);

    // Jika hasil akhirnya bukan list, kembalikan list kosong agar aman.
    if (list is! List) {
      return [];
    }

    // Pastikan semua item benar-benar map lalu ubah ke Map<String, dynamic>
    // supaya nyaman dipakai di bagian aplikasi lain.
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Menyimpan data stok baru atau update stok ke backend.
// Method ini menyimpan data ke backend, baik sebagai data baru maupun update.
  Future<void> saveStok({
    required String komoditasId,
    required String kecamatanId,
    required double stokKg,
    required double kapasitasKg,
  }) async {
    // Kirim data stok dalam body request POST.
    await _client.dio.post(
      '/stok',
      data: {
        'komoditas_id': komoditasId,
        'kecamatan_id': kecamatanId,
        'stok_kg': stokKg,
        'kapasitas_kg': kapasitasKg,
      },
    );
  }

  // Menghapus data stok berdasarkan id.
// Method ini menghapus data berdasarkan id atau identitas tertentu.
  Future<void> deleteStok(String id) async {
    await _client.dio.delete('/stok/$id');
  }

  // Mengubah error dari Dio menjadi pesan yang lebih mudah ditampilkan ke user.
  String getErrorMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;

    // Jika backend mengirim field error, pakai pesan itu.
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    // Jika tidak ada pesan spesifik, pakai fallback bawaan.
    return fallback;
  }
}
