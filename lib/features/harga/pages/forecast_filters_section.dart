// Doc:
// Tujuan: Menyimpan builder filter dan layout konten utama untuk halaman forecast harga.
// Dipakai oleh: ForecastPage melalui part of forecast_page.dart.
// Dependensi utama: State lokal _ForecastPageState, Flutter form widgets.
// Fungsi public/utama: _buildContent, _buildFilterCard, _inputDecoration.
// Side effect penting: Mengubah state pilihan filter dan memicu _loadForecast saat tombol ditekan.
part of 'forecast_page.dart';

extension _ForecastFilterSection on _ForecastPageState {
  Widget _buildContent() {
    if (_loadingForecast) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(56),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorCard();
    }

    if (_predictions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(),
        const SizedBox(height: 16),
        _buildStatsGrid(),
        const SizedBox(height: 16),
        _buildChart(),
        const SizedBox(height: 16),
        _buildPredictionTable(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterCard({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF2E7D32), size: 18),
              SizedBox(width: 8),
              Text(
                'Filter Prediksi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih komoditas dan wilayah untuk melihat estimasi harga 7 hari ke depan.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedKomoditasId,
            isExpanded: true,
            decoration: _inputDecoration(
              'Komoditas *',
              Icons.inventory_2_outlined,
            ),
            hint: const Text('Pilih komoditas'),
            items: _komoditasList
                .map(
                  (k) => DropdownMenuItem<String>(
                    value: k['id'] as String,
                    child: Text(
                      k['nama'] as String? ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _selectedKomoditasId = v;
                _predictions = [];
                _error = null;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedKecamatanId,
            isExpanded: true,
            decoration: _inputDecoration(
              'Kecamatan (opsional)',
              Icons.location_on_outlined,
            ),
            hint: const Text('Semua kecamatan'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua kecamatan'),
              ),
              ..._kecamatanList.map(
                (k) => DropdownMenuItem<String>(
                  value: k['id'] as String,
                  child: Text(
                    k['nama'] as String? ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) {
              // ignore: invalid_use_of_protected_member
              setState(() {
                _selectedKecamatanId = v;
                _predictions = [];
                _error = null;
              });
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadForecast,
              icon: const Icon(Icons.auto_graph),
              label: Text(isWide ? 'Lihat Prediksi Harga' : 'Lihat Prediksi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor: const Color(0xFFF9FBFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
