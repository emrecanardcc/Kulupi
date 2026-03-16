import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/utils/glass_components.dart';

class AdminMembersTab extends StatefulWidget {
  final String kulupId;
  final String currentUserRole;
  final bool isSuperAdmin;
  final Color primaryColor;

  const AdminMembersTab({
    super.key,
    required this.kulupId,
    required this.currentUserRole,
    required this.primaryColor,
    this.isSuperAdmin = false,
  });

  @override
  State<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends State<AdminMembersTab> {
  int _getRolePriority(String? role) {
    switch (role) {
      case 'baskan':
        return 0;
      case 'baskan_yardimcisi':
        return 1;
      case 'koordinator':
        return 2;
      default:
        return 3;
    }
  }

  Map<String, dynamic> _getRoleStyle(BuildContext context, String role) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    switch (role) {
      case 'baskan':
        return {
          'color': Colors.amberAccent,
          'icon': Icons.emoji_events,
          'label': 'Başkan',
        };
      case 'baskan_yardimcisi':
        return {
          'color': Colors.cyanAccent,
          'icon': Icons.star,
          'label': 'Başkan Yrd.',
        };
      case 'koordinator':
        return {
          'color': Colors.orangeAccent,
          'icon': Icons.bolt,
          'label': 'Koordinatör',
        };
      default:
        return {
          'color': onSurface,
          'icon': Icons.person,
          'label': 'Üye',
        };
    }
  }

  Future<void> _changeMemberRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('club_members')
          .update({'role': newRole})
          .eq('club_id', widget.kulupId)
          .eq('user_id', userId);
          
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- YENİ: SÜPER ADMIN İÇİN BAŞKAN ATAMA ---
  Future<void> _forceAssignPresidency(
    String targetUserId,
    String targetUserName,
  ) async {
    bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final Color onSurface = Theme.of(context).colorScheme.onSurface;
        final Color muted = onSurface.withValues(alpha: 0.7);
        return AuraGlassCard(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          accentColor: Colors.redAccent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                "KRALİYET DEĞİŞİMİ",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "'$targetUserName' adlı üyeyi KULÜP BAŞKANI yapmak üzeresiniz.\n\n"
                "Bu işlem sonucunda mevcut başkan üye statüsüne düşürülecektir.",
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("İPTAL", style: TextStyle(color: muted, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("ONAYLA", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        // 1. Mevcut başkanı bul ve üye yap
        await Supabase.instance.client
            .from('club_members')
            .update({'role': 'uye'})
            .eq('club_id', widget.kulupId)
            .eq('role', 'baskan');

        // 2. Yeni başkanı ata
        await Supabase.instance.client
            .from('club_members')
            .update({'role': 'baskan'})
            .eq('club_id', widget.kulupId)
            .eq('user_id', targetUserId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$targetUserName artık Kulüp Başkanı!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // --- ESKİ: BAŞKANIN KENDİ YETKİSİNİ DEVRETMESİ ---
  Future<void> _transferPresidency(
    String targetUserId,
    String targetUserName,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    
    bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final Color onSurface = Theme.of(context).colorScheme.onSurface;
        final Color muted = onSurface.withValues(alpha: 0.7);
        return AuraGlassCard(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          accentColor: Colors.orangeAccent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                "BAŞKANLIĞI DEVRET",
                style: TextStyle(
                  color: onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Başkanlık yetkilerini '$targetUserName' adlı üyeye devretmek istediğinize emin misiniz?",
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text("İPTAL", style: TextStyle(color: muted, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("DEVRET", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        // 1. Yeni başkanı ata
        await Supabase.instance.client
            .from('club_members')
            .update({'role': 'baskan'})
            .eq('club_id', widget.kulupId)
            .eq('user_id', targetUserId);
            
        // 2. Kendini üye yap
        await Supabase.instance.client
            .from('club_members')
            .update({'role': 'uye'})
            .eq('club_id', widget.kulupId)
            .eq('user_id', currentUser.id);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Başkanlık devredildi."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showRoleDialog(String userId, String userName, String currentRole) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == currentUserId && !widget.isSuperAdmin) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          final Color muted = onSurface.withValues(alpha: 0.7);
          return AuraGlassCard(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person_rounded, color: Colors.amberAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  "İşlem Engellendi",
                  style: TextStyle(color: onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Kendi rolünüzü değiştiremezsiniz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      foregroundColor: onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Tamam"),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final Color onSurface = Theme.of(context).colorScheme.onSurface;
        final Color muted = onSurface.withValues(alpha: 0.6);
        return AuraGlassCard(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          accentColor: widget.primaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.manage_accounts_rounded, color: widget.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rolü Düzenle",
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildRoleOption('uye', 'Üye', Icons.person_rounded, onSurface, currentRole == 'uye', userId),
              const SizedBox(height: 12),
              _buildRoleOption('koordinator', 'Koordinatör', Icons.bolt_rounded, Colors.orangeAccent, currentRole == 'koordinator', userId),
              const SizedBox(height: 12),
              _buildRoleOption('baskan_yardimcisi', 'Başkan Yardımcısı', Icons.star_rounded, Colors.cyanAccent, currentRole == 'baskan_yardimcisi', userId),

              if (widget.isSuperAdmin || widget.currentUserRole == 'baskan') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: onSurface.withValues(alpha: 0.12)),
                ),
                _buildRoleOption(
                  'baskan',
                  widget.isSuperAdmin ? "Başkan Yap (Zorla)" : "Başkanlığı Devret",
                  Icons.emoji_events_rounded,
                  Colors.redAccent,
                  currentRole == 'baskan',
                  userId,
                  isDangerous: true,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(String role, String label, IconData icon, Color color, bool isSelected, String userId, {bool isDangerous = false}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    return InkWell(
      onTap: () {
        if (role == 'baskan') {
          Navigator.pop(context);
          if (widget.isSuperAdmin) {
            _forceAssignPresidency(userId, label);
          } else {
            _transferPresidency(userId, label);
          }
        } else {
          _changeMemberRole(userId, role);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : color.withValues(alpha: 0.4), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? onSurface : onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('club_members')
          .stream(primaryKey: ['id'])
          .eq('club_id', widget.kulupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!;
        docs.sort((a, b) {
          var roleA = a['role'];
          var roleB = b['role'];
          return _getRolePriority(roleA).compareTo(_getRolePriority(roleB));
        });

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            var data = docs[index];
            String role = data['role'] ?? 'uye';
            String userId = data['user_id'];
            final Color onSurface = Theme.of(context).colorScheme.onSurface;
            var style = _getRoleStyle(context, role);
            final roleColor = style['color'] as Color;

            return FutureBuilder<Map<String, dynamic>>(
              future: Supabase.instance.client
                  .from('profiles')
                  .select('full_name, first_name, last_name, email, display_name')
                  .eq('id', userId)
                  .single(),
              builder: (context, snap) {
                final profile = snap.data;
                final String name = () {
                  if (profile == null) return userId;
                  return profile['full_name'] ??
                      ((profile['first_name'] != null || profile['last_name'] != null)
                          ? "${(profile['first_name'] ?? '').toString().trim()} ${(profile['last_name'] ?? '').toString().trim()}".trim()
                          : (profile['display_name'] ?? profile['email'] ?? userId));
                }();
                return GestureDetector(
                  onTap: () => _showRoleDialog(userId, name, role),
                  child: AuraGlassCard(
                    accentColor: roleColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: roleColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(style['icon'], color: roleColor, size: 24),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          style['label'].toString().toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: onSurface.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
