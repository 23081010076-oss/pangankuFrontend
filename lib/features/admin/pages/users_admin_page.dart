import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class UsersAdminPage extends StatefulWidget {
  const UsersAdminPage({super.key});

  @override
  State<UsersAdminPage> createState() => _UsersAdminPageState();
}

class _UsersAdminPageState extends State<UsersAdminPage> {
  final _client = DioClient();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;
  String _selectedRole = 'Semua';
  int _page = 1;
  int _total = 0;
  static const int _limit = 20;

  final _roles = ['Semua', 'admin', 'petugas', 'petani', 'pedagang', 'publik'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'page': _page,
        'limit': _limit,
      };
      if (_selectedRole != 'Semua') queryParams['role'] = _selectedRole;
      if (_searchCtrl.text.trim().isNotEmpty) {
        queryParams['search'] = _searchCtrl.text.trim();
      }

      final res = await _client.dio.get('/users', queryParameters: queryParams);
      final raw = res.data['data'] as List<dynamic>;
      setState(() {
        _users = List<Map<String, dynamic>>.from(raw);
        _total = (res.data['total'] ?? 0) as int;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data['error'] ?? 'Gagal memuat data';
        _loading = false;
      });
    }
  }

  Future<void> _updateRole(String id, String currentRole) async {
    final roles = ['admin', 'petugas', 'petani', 'pedagang', 'publik'];
    String? selected = currentRole;

    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Ubah Peran Pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: roles
                .map((r) => RadioListTile<String>(
                      value: r,
                      groupValue: selected,
                      title: Text(_roleLabel(r)),
                      activeColor: const Color(0xFF2E7D32),
                      onChanged: (v) => setInner(() => selected = v),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (newRole == null || newRole == currentRole) return;

    try {
      await _client.dio.put('/users/$id/role', data: {'role': newRole});
      _showSnack('Peran pengguna berhasil diubah');
      _loadData();
    } on DioException catch (e) {
      _showSnack(e.response?.data['error'] ?? 'Gagal mengubah peran',
          isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Manajemen Pengguna', style: TextStyle(fontSize: 16)),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadData();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _loadData(),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _roles.map((r) {
                        final selected = _selectedRole == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(r == 'Semua' ? 'Semua' : _roleLabel(r)),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectedRole = r);
                              _loadData();
                            },
                            selectedColor: const Color(0xFFE8F5E9),
                            checkmarkColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: selected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[700],
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_users.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Tidak ada pengguna ditemukan',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Total: $_total pengguna',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildUserTile(_users[i]),
                  childCount: _users.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final id = user['id']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'publik';
    final isActive = user['is_active'] as bool? ?? true;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    final roleColor = _roleColor(role);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE8F5E9),
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nonaktif',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _roleLabel(role),
                style: TextStyle(
                  fontSize: 11,
                  color: roleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.manage_accounts_outlined,
              color: Color(0xFF2E7D32)),
          tooltip: 'Ubah Peran',
          onPressed: () => _updateRole(id, role),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_error ?? 'Terjadi kesalahan',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      case 'petani':
        return 'Petani';
      case 'pedagang':
        return 'Pedagang';
      default:
        return 'Publik';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFC62828);
      case 'petugas':
        return const Color(0xFF1565C0);
      case 'petani':
        return const Color(0xFF2E7D32);
      case 'pedagang':
        return const Color(0xFF00897B);
      default:
        return Colors.grey;
    }
  }
}
