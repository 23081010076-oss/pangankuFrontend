part of '../pages/distribusi_page.dart';

class _RuteData {
  final List<_RuteStep> steps;
  final List<LatLng> points;
  final double jarakKm;

  const _RuteData({
    required this.steps,
    required this.points,
    required this.jarakKm,
  });
}

class _RuteStep {
  final String id;
  final String nama;

  const _RuteStep({required this.id, required this.nama});
}

class _CreateDistribusiSheet extends StatefulWidget {
  const _CreateDistribusiSheet();

  @override
  State<_CreateDistribusiSheet> createState() => _CreateDistribusiSheetState();
}

class _CreateDistribusiSheetState extends State<_CreateDistribusiSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selDari;
  String? _selKe;
  String? _selKomoditas;
  final _jumlahCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  final _kendaraanCtrl = TextEditingController();
  DateTime _jadwal = DateTime.now().add(const Duration(days: 1));
  bool _loadingOpts = true;
  List<Map<String, dynamic>> _komList = [];
  List<Map<String, dynamic>> _kecList = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _driverCtrl.dispose();
    _kendaraanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final repository = context.read<MasterDataRepository>();
      final res = await Future.wait([
        repository.fetchKomoditas(),
        repository.fetchKecamatan(),
      ]);
      if (mounted) {
        setState(() {
          _komList = res[0];
          _kecList = res[1];
          _loadingOpts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOpts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Buat Jadwal Distribusi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              if (_loadingOpts)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                )
              else
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selKomoditas,
                        decoration: InputDecoration(
                          labelText: 'Komoditas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _komList
                            .map(
                              (k) => DropdownMenuItem(
                                value: k['id']?.toString(),
                                child: Text(k['nama']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selKomoditas = v),
                        validator: (v) => v == null ? 'Pilih komoditas' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selDari,
                        decoration: InputDecoration(
                          labelText: 'Dari Kecamatan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _kecList
                            .map(
                              (k) => DropdownMenuItem(
                                value: k['id']?.toString(),
                                child: Text(k['nama']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selDari = v),
                        validator: (v) =>
                            v == null ? 'Pilih kecamatan asal' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selKe,
                        decoration: InputDecoration(
                          labelText: 'Ke Kecamatan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _kecList
                            .map(
                              (k) => DropdownMenuItem(
                                value: k['id']?.toString(),
                                child: Text(k['nama']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selKe = v),
                        validator: (v) =>
                            v == null ? 'Pilih kecamatan tujuan' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _jumlahCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Jumlah (kg)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Masukkan jumlah';
                          }
                          if (double.tryParse(v) == null ||
                              double.parse(v) <= 0) {
                            return 'Nilai tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked =
                              await showDateTimePicker(context: context);
                          if (picked != null) {
                            setState(() => _jadwal = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Jadwal Berangkat',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                            ),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy HH:mm', 'id')
                                .format(_jadwal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _driverCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Driver (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kendaraanCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Kendaraan (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<DistribusiBloc, DistribusiState>(
                        builder: (ctx, bstate) => SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: bstate is DistribusiSaving
                                ? null
                                : () => _submit(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: bstate is DistribusiSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Buat Jadwal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker({required BuildContext context}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _jadwal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_jadwal),
    );
    if (time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<DistribusiBloc>().add(
          CreateDistribusi(
            dariKecamatanId: _selDari!,
            keKecamatanId: _selKe!,
            komoditasId: _selKomoditas!,
            jumlahKg: double.parse(_jumlahCtrl.text),
            jadwalBerangkat: _jadwal.toUtc().toIso8601String(),
            namaDriver: _driverCtrl.text.trim().isEmpty
                ? null
                : _driverCtrl.text.trim(),
            namaKendaraan: _kendaraanCtrl.text.trim().isEmpty
                ? null
                : _kendaraanCtrl.text.trim(),
          ),
        );
    Navigator.of(ctx).pop();
  }
}

