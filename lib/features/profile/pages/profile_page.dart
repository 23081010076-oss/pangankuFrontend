import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_event.dart';
import '../../profile/bloc/profile_state.dart';
import '../../../core/network/dio_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (ctx, state) {
        if (state is ProfileSaved) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF2E7D32),
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      },
      builder: (ctx, state) {
        final profile = state is ProfileLoaded
            ? state.profile
            : state is ProfileSaving
                ? state.profile
                : state is ProfileSaved
                    ? state.profile
                    : state is ProfileError
                        ? state.profile
                        : null;

        final authState = ctx.read<AuthBloc>().state;
        final role = authState is AuthAuthenticated ? authState.role : 'publik';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: RefreshIndicator(
            color: const Color(0xFF2E7D32),
            onRefresh: () async => ctx.read<ProfileBloc>().add(LoadProfile()),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(ctx, profile, role),
                ),
                if (state is ProfileLoading) ...[
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ] else ...[
                  SliverToBoxAdapter(
                    child: _buildBody(ctx, profile, role),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext ctx, dynamic profile, String role) {
    final name = profile?.name ??
        (ctx.read<AuthBloc>().state is AuthAuthenticated
            ? (ctx.read<AuthBloc>().state as AuthAuthenticated).name
            : 'Pengguna');
    final email = profile?.email ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : 'U';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleLabel(role),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, dynamic profile, String role) {
    final isAdmin = role == 'admin';
    final isAdminOrPetugas = role == 'admin' || role == 'petugas';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _menuCard([
            _MenuItem(
              icon: Icons.person_outline,
              label: 'Edit Profil',
              onTap: () => _showEditProfil(ctx, profile),
            ),
            _MenuItem(
              icon: Icons.lock_outline,
              label: 'Ubah Kata Sandi',
              onTap: () => _showChangePassword(ctx),
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifikasi',
              onTap: () => ctx.push('/notifikasi'),
            ),
          ]),
          const SizedBox(height: 16),
          if (profile != null) ...[
            _infoCard(profile, role),
            const SizedBox(height: 16),
          ],
          if (isAdminOrPetugas) ...[
            _sectionLabel('Analitik & Laporan'),
            const SizedBox(height: 8),
            _menuCard([
              _MenuItem(
                icon: Icons.bar_chart_outlined,
                label: 'Analitik Pangan',
                onTap: () => ctx.push('/analytics'),
              ),
              _MenuItem(
                icon: Icons.auto_graph_outlined,
                label: 'Prediksi Harga',
                onTap: () => ctx.push('/harga/forecast'),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (isAdmin) ...[
            _sectionLabel('Manajemen Data'),
            const SizedBox(height: 8),
            _menuCard([
              _MenuItem(
                icon: Icons.inventory_2_outlined,
                label: 'Kelola Komoditas',
                onTap: () => ctx.push('/admin/komoditas'),
              ),
              _MenuItem(
                icon: Icons.location_city_outlined,
                label: 'Kelola Kecamatan',
                onTap: () => ctx.push('/admin/kecamatan'),
              ),
              _MenuItem(
                icon: Icons.manage_accounts_outlined,
                label: 'Kelola Pengguna',
                onTap: () => ctx.push('/admin/users'),
              ),
              _MenuItem(
                icon: Icons.warehouse_outlined,
                label: 'Kelola Stok',
                onTap: () => ctx.push('/admin/stok'),
              ),
              _MenuItem(
                icon: Icons.price_change_outlined,
                label: 'Kelola Harga',
                onTap: () => ctx.push('/admin/harga'),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          _menuCard([
            _MenuItem(
              icon: Icons.info_outline,
              label: 'Tentang Aplikasi',
              onTap: () => _showAbout(ctx),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _logout(ctx),
              icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC62828)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'PanganKu v1.0.0',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF757575),
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _menuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey,
                ),
                onTap: item.onTap,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 64,
                  color: Color(0xFFF0F0F0),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoCard(dynamic profile, String role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Akun',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.email_outlined, 'Email', profile.email),
          if ((profile.phone ?? '').isNotEmpty)
            _infoRow(Icons.phone_outlined, 'Telepon', profile.phone),
          _infoRow(Icons.badge_outlined, 'Peran', _roleLabel(role)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfil(BuildContext ctx, dynamic profile) {
    if (profile == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ProfileBloc>(),
        child: _EditProfilSheet(profile: profile),
      ),
    );
  }

  void _showChangePassword(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<ProfileBloc>(),
        child: const _ChangePasswordSheet(),
      ),
    );
  }

  void _showAbout(BuildContext ctx) {
    showAboutDialog(
      context: ctx,
      applicationName: 'PanganKu',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Sistem Informasi Ketahanan Pangan\nKabupaten Lamongan',
    );
  }

  void _logout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'petugas':
        return 'Petugas';
      case 'petani':
        return 'Petani';
      default:
        return 'Publik';
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ── Edit Profil Sheet ────────────────────────────────────
class _EditProfilSheet extends StatefulWidget {
  final dynamic profile;
  const _EditProfilSheet({required this.profile});

  @override
  State<_EditProfilSheet> createState() => _EditProfilSheetState();
}

class _EditProfilSheetState extends State<_EditProfilSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _kecList = [];
  String? _selKecamatan;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _selKecamatan = widget.profile.kecamatanId;
    _loadKecamatan();
  }

  Future<void> _loadKecamatan() async {
    try {
      final res = await DioClient().dio.get('/kecamatan');
      if (mounted) {
        setState(() {
          _kecList = List<Map<String, dynamic>>.from(
            res.data is Map ? (res.data['data'] ?? res.data) : res.data,
          );
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
              'Edit Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Masukkan nama' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_kecList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selKecamatan,
                      decoration: InputDecoration(
                        labelText: 'Kecamatan',
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
                      onChanged: (v) => setState(() => _selKecamatan = v),
                    ),
                  ],
                  const SizedBox(height: 20),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (ctx, bstate) => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            bstate is ProfileSaving ? null : () => _submit(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: bstate is ProfileSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Simpan',
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
    );
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<ProfileBloc>().add(
          UpdateProfile(
            name: _nameCtrl.text.trim(),
            phone:
                _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
            kecamatanId: _selKecamatan,
          ),
        );
    Navigator.of(ctx).pop();
  }
}

// ── Change Password Sheet ─────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
              'Ubah Kata Sandi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _oldCtrl,
                    obscureText: _obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Lama',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOld ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Masukkan kata sandi lama' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Masukkan kata sandi baru';
                      }
                      if (v.length < 8) {
                        return 'Minimal 8 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (ctx, bstate) => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            bstate is ProfileSaving ? null : () => _submit(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: bstate is ProfileSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ganti Kata Sandi',
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
    );
  }

  void _submit(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) return;
    ctx.read<ProfileBloc>().add(
          ChangePassword(
            oldPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
          ),
        );
    Navigator.of(ctx).pop();
  }
}
