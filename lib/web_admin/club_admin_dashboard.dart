import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/models/club.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/services/database_service_optimized.dart';

class ClubAdminDashboard extends StatefulWidget {
  final Club club;
  const ClubAdminDashboard({super.key, required this.club});

  @override
  State<ClubAdminDashboard> createState() => _ClubAdminDashboardState();
}

class _ClubAdminDashboardState extends State<ClubAdminDashboard> {
  int _selectedIndex = 0;
  final DatabaseService _databaseService = DatabaseService();

  String _getMemberNameFromProfile(Map<String, dynamic>? profile, String userId) {
    if (profile == null) return userId;
    
    final fullName = profile['full_name']?.toString();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    
    final firstName = profile['first_name']?.toString() ?? '';
    final lastName = profile['last_name']?.toString() ?? '';
    final nameConcat = '$firstName $lastName'.trim();
    if (nameConcat.isNotEmpty) return nameConcat;
    
    return profile['display_name']?.toString() ??
           profile['email']?.toString() ??
           userId;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: Colors.black26,
      child: Column(
        children: [
          const SizedBox(height: 40),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('clubs')
                .stream(primaryKey: ['id'])
                .eq('id', widget.club.id),
            builder: (context, snapshot) {
              final row = (snapshot.data != null && snapshot.data!.isNotEmpty) ? snapshot.data!.first : null;
              final shortName = row?['short_name'] ?? widget.club.shortName;
              final name = row?['name'] ?? widget.club.name;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white10,
                    child: Text(
                      shortName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          _buildMenuItem(0, Icons.person_add, "İstekler"),
          _buildMenuItem(1, Icons.people, "Üyeler"),
          _buildMenuItem(2, Icons.event, "Etkinlikler"),
          _buildMenuItem(3, Icons.info, "Kulüp Bilgileri"),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.white70),
            title: const Text("Geri", style: TextStyle(color: Colors.white70)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white70),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildRequestsView();
      case 1:
        return _buildMembersView();
      case 2:
        return _buildEventsView();
      case 3:
        return _buildInfoView();
      default:
        return Container();
    }
  }

  Widget _buildRequestsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseService.getPendingRequestsWithProfiles(widget.club.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pending = snapshot.data ?? [];
        if (pending.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.person_add_disabled, color: Colors.white54, size: 48),
                SizedBox(height: 12),
                Text("Bekleyen üyelik isteği yok.", style: TextStyle(color: Colors.white70)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: pending.length,
          itemBuilder: (context, index) {
            final m = pending[index];
            final profile = m['profiles'] as Map<String, dynamic>?;
            final String name = _getMemberNameFromProfile(profile, m['user_id']);
            final String email = profile?['email'] ?? "";
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AuraGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 20,
                accentColor: Colors.cyanAccent,
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () async {
                        await Supabase.instance.client
                            .from('club_members')
                            .delete()
                            .eq('club_id', widget.club.id)
                            .eq('user_id', m['user_id'])
                            .eq('status', 'pending');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.greenAccent),
                      onPressed: () async {
                        await Supabase.instance.client
                            .from('club_members')
                            .update({'status': 'approved'})
                            .eq('club_id', widget.club.id)
                            .eq('user_id', m['user_id']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMembersView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Üye Yönetimi", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _databaseService.getClubMembersWithProfiles(widget.club.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final membersWithProfiles = snapshot.data!;
                
                return AuraGlassCard(
                  child: ListView.separated(
                    itemCount: membersWithProfiles.length,
                    separatorBuilder: (c, i) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final member = membersWithProfiles[index];
                      final profile = member['profiles'] as Map<String, dynamic>?;
                      final String name = _getMemberNameFromProfile(profile, member['user_id']);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyan.withValues(alpha: 0.3),
                          child: Text(member['role'].substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(member['role'], style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                              onPressed: () => _showRoleChangeDialog(member),
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                              onPressed: () => _removeMember(member['user_id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRoleChangeDialog(Map<String, dynamic> member) async {
    String? newRole = member['role'];
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203A43).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rol Değiştir", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Kullanıcı: ${_getMemberNameFromProfile(member['profiles'] as Map<String, dynamic>?, member['user_id'])}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            const Text("Yeni Rol Seçin:", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) {
                void handleRoleChange(String? value) {
                  setState(() => newRole = value);
                }
                
                return Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text("Başkan", style: TextStyle(color: Colors.white)),
                      value: "baskan",
                      groupValue: newRole,
                      onChanged: handleRoleChange,
                      activeColor: Colors.cyanAccent,
                      fillColor: WidgetStateProperty.resolveWith((states) => Colors.cyanAccent),
                    ),
                    RadioListTile<String>(
                      title: const Text("Başkan Yrd.", style: TextStyle(color: Colors.white)),
                      value: "baskan_yardimcisi",
                      groupValue: newRole,
                      onChanged: handleRoleChange,
                      activeColor: Colors.cyanAccent,
                      fillColor: WidgetStateProperty.resolveWith((states) => Colors.cyanAccent),
                    ),
                    RadioListTile<String>(
                      title: const Text("Koordinatör", style: TextStyle(color: Colors.white)),
                      value: "koordinator",
                      groupValue: newRole,
                      onChanged: handleRoleChange,
                      activeColor: Colors.cyanAccent,
                      fillColor: WidgetStateProperty.resolveWith((states) => Colors.cyanAccent),
                    ),
                    RadioListTile<String>(
                      title: const Text("Üye", style: TextStyle(color: Colors.white)),
                      value: "uye",
                      groupValue: newRole,
                      onChanged: handleRoleChange,
                      activeColor: Colors.cyanAccent,
                      fillColor: WidgetStateProperty.resolveWith((states) => Colors.cyanAccent),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              if (newRole != null) {
                await _updateMemberRole(member['user_id'], newRole!);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('club_members')
          .update({'role': newRole})
          .eq('user_id', userId)
          .eq('club_id', widget.club.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rol başarıyla güncellendi")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rol güncellenirken hata: $e")),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      await Supabase.instance.client
          .from('club_members')
          .delete()
          .eq('user_id', userId)
          .eq('club_id', widget.club.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Üye kulüpten çıkarıldı")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Üye çıkarılırken hata: $e")),
        );
      }
    }
  }

  Widget _buildEventsView() {
    return const Center(
      child: Text("Etkinlikler yakında...", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildInfoView() {
    return ClubInfoEditView(
      club: widget.club,
      onUpdate: (updatedClub) {
        // Handle club update
      },
    );
  }
}

class ClubInfoEditView extends StatefulWidget {
  final Club club;
  final Function(Club) onUpdate;
  
  const ClubInfoEditView({
    super.key, 
    required this.club, 
    required this.onUpdate,
  });

  @override
  State<ClubInfoEditView> createState() => _ClubInfoEditViewState();
}

class _ClubInfoEditViewState extends State<ClubInfoEditView> {
  late TextEditingController _nameController;
  late TextEditingController _shortNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _mainColorController;
  
  String? _logoPath;
  String? _bannerPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club.name);
    _shortNameController = TextEditingController(text: widget.club.shortName);
    _descriptionController = TextEditingController(text: widget.club.description);
    _categoryController = TextEditingController(text: widget.club.category);
    _mainColorController = TextEditingController(text: widget.club.mainColor);
    _logoPath = widget.club.logoPath;
    _bannerPath = widget.club.bannerPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _mainColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kulüp Bilgileri", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AuraGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Kulüp Adı",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shortNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Kısa Ad",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Açıklama",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _mainColorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Ana Renk",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _isLoading ? null : () async {
                            setState(() => _isLoading = true);
                            try {
                              final updatedClub = Club(
                                id: widget.club.id,
                                universityId: widget.club.universityId,
                                name: _nameController.text,
                                shortName: _shortNameController.text,
                                description: _descriptionController.text,
                                category: _categoryController.text,
                                mainColor: _mainColorController.text,
                                logoPath: _logoPath,
                                bannerPath: _bannerPath,
                                tags: widget.club.tags,
                                status: widget.club.status,
                              );
                              
                              await Supabase.instance.client
                                  .from('clubs')
                                  .update(updatedClub.toJson())
                                  .eq('id', widget.club.id);
                              
                              widget.onUpdate(updatedClub);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Kulüp bilgileri güncellendi")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Güncelleme hatası: $e")),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text("Kaydet"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}