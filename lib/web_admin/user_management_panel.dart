import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/utils/glass_components.dart';

class UserManagementPanel extends StatefulWidget {
  const UserManagementPanel({super.key});

  @override
  State<UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final String _searchQuery = '';
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      
      // Kullanıcıları profiles tablosundan getir (auth.users join'i kaldırıldı)
      final response = await client
          .from('profiles')
          .select('*')
          .ilike('email', '%$_searchQuery%')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kullanıcılar yüklenirken hata: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kullanıcıyı Sil", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Bu kullanıcıyı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Önce auth'dan sil
        await Supabase.instance.client.auth.admin.deleteUser(userId);
        
        // Sonra profili sil
        await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Kullanıcı silindi"),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(); // Listeyi yenile
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Kullanıcı silinirken hata: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleUserBan(String userId, bool isBanned) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'is_banned': !isBanned})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBanned ? "Kullanıcının engeli kaldırıldı" : "Kullanıcı engellendi"),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("İşlem sırasında hata: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.cyan.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kullanıcı Yönetimi",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Yenile"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Arama ve Filtreleme
              Row(
                children: [
                  Expanded(
                    child: AuraGlassTextField(
                      controller: TextEditingController(text: _searchQuery),
                      hintText: "Kullanıcı ara...",
                      // prefixIcon is not supported directly in AuraGlassTextField as a property named prefixIcon?
                      // Checking AuraGlassTextField definition in glass_components.dart
                      // It has `icon` property for prefix icon.
                      icon: Icons.search,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.cyanAccent),
                    onPressed: _loadUsers,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      dropdownColor: const Color(0xFF203A43),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tüm Roller')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'user', child: Text('Kullanıcı')),
                        DropdownMenuItem(value: 'club_admin', child: Text('Kulüp Admin')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                          _loadUsers();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // İstatistikler
        Container(
          margin: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: AuraGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.people, color: Colors.cyanAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _users.length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Toplam Kullanıcı",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AuraGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.greenAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _users.where((u) => u['role'] == 'admin').length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Admin Kullanıcı",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AuraGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.block, color: Colors.redAccent, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _users.where((u) => u['is_banned'] == true).length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Engellenmiş Kullanıcı",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Kullanıcı Listesi
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        "Kullanıcı bulunamadı",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isBanned = user['is_banned'] == true;
    final userEmail = user['email'] ?? 'Bilinmeyen Email';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AuraGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.cyan.withValues(alpha: 0.3),
                    Colors.blue.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: isBanned ? Colors.redAccent : Colors.cyanAccent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  userEmail.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Kullanıcı Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user['role']).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(user['role']),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getRoleName(user['role']),
                          style: TextStyle(
                            color: _getRoleColor(user['role']),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isBanned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "ENGELLENDİ",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user['created_at'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Katılma: ${_formatDate(user['created_at'])}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // İşlem Butonları
            Row(
              children: [
                // Engelle/Kaldır
                IconButton(
                  icon: Icon(
                    isBanned ? Icons.lock_open : Icons.block,
                  color: isBanned ? Colors.greenAccent : Colors.redAccent,
                  ),
                  onPressed: () => _toggleUserBan(user['id'], isBanned),
                ),
                // Sil
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteUser(user['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.redAccent;
      case 'club_admin':
        return Colors.orangeAccent;
      case 'user':
      default:
        return Colors.cyanAccent;
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'club_admin':
        return 'Kulüp Admin';
      case 'user':
      default:
        return 'Kullanıcı';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }
}
