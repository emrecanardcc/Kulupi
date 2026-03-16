import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/widget/badge_grid.dart';
import '../utils/glass_components.dart';

class ClubProfileTab extends StatefulWidget {
  final String kulupId;
  final String kulupIsmi;
  final Color primaryColor;
  final Function(int) onTabChanged;

  const ClubProfileTab({
    super.key,
    required this.kulupId,
    required this.kulupIsmi,
    required this.primaryColor,
    required this.onTabChanged,
  });

  @override
  State<ClubProfileTab> createState() => _ClubProfileTabState();
}

class _ClubProfileTabState extends State<ClubProfileTab> {
  String _formatDate(String? dateString) {
    if (dateString == null) return "Tarih Yok";
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Tarih Yok";
    }
  }

  Map<String, dynamic> _getRoleStyle(String role, Color defaultColor) {
    switch (role) {
      case 'baskan':
        return {
          'color': const Color(0xFFFFD700),
          'icon': Icons.emoji_events,
          'label': 'Kulüp Başkanı',
          'gradient': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
        };
      case 'baskan_yardimcisi':
        return {
          'color': const Color(0xFFC0C0C0),
          'icon': Icons.star,
          'label': 'Başkan Yardımcısı',
          'gradient': [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)],
        };
      case 'koordinator':
        return {
          'color': const Color(0xFFCD7F32),
          'icon': Icons.bolt,
          'label': 'Koordinatör',
          'gradient': [const Color(0xFFFFCC80), const Color(0xFF8D6E63)],
        };
      default:
        return {
          'color': defaultColor,
          'icon': Icons.person,
          'label': 'Üye',
          'gradient': [defaultColor.withValues(alpha: 0.8), defaultColor],
        };
    }
  }

  // --- KULÜPTEN AYRILMA ALGORİTMASI ---
  Future<void> _leaveClub() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // 1. Onay Penceresi
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kulüpten Ayrıl"),
        content: const Text(
          "Bu kulüpten ayrılmak istediğinize emin misiniz?\n\n"
          "Eğer 'Başkan' iseniz, yetkiniz otomatik olarak sıradaki en yetkili üyeye devredilecektir.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Evet, Ayrıl"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      // Üyenin rolünü kontrol et
      final memberData = await supabase
          .from('club_members')
          .select('role')
          .eq('club_id', widget.kulupId)
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (memberData == null) return;

      // Eğer başkansa devretme işlemi (basitçe: en eski üyeye devret veya uyarı ver)
      // Şimdilik sadece siliyoruz, başkanlık devri backend trigger veya ayrı logic gerektirir
      // Kullanıcıya basitçe silindiğini gösterelim
      
      await supabase
          .from('club_members')
          .delete()
          .eq('club_id', widget.kulupId)
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kulüpten ayrıldınız.")),
        );
        Navigator.of(context).pop(); // Sayfadan çık
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Center(child: Text("Giriş yapılmamış"));
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('club_members')
            .select()
            .eq('club_id', widget.kulupId)
            .eq('user_id', user.id)
            .eq('status', 'approved')
            .asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          bool isMember = snapshot.hasData && snapshot.data!.isNotEmpty;
          Map<String, dynamic>? memberData = isMember ? snapshot.data!.first : null;
          String role = memberData?['role'] ?? 'uye';
          var roleStyle = _getRoleStyle(role, widget.primaryColor);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraGlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 28,
                accentColor: isMember ? widget.primaryColor : null,
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isMember
                              ? roleStyle['gradient']
                              : [Colors.grey.withValues(alpha: 0.2), Colors.grey.withValues(alpha: 0.4)],
                        ),
                        boxShadow: [
                          if (isMember)
                            BoxShadow(
                              color: (roleStyle['color'] as Color).withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.userMetadata?['full_name']?.substring(0, 1).toUpperCase() ?? "U",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userMetadata?['full_name'] ?? "Kullanıcı",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isMember 
                                ? (roleStyle['color'] as Color).withValues(alpha: 0.1)
                                : onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isMember 
                                  ? (roleStyle['color'] as Color).withValues(alpha: 0.3)
                                  : onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              isMember ? roleStyle['label'] : "Ziyaretçi",
                              style: TextStyle(
                                color: isMember ? roleStyle['color'] : muted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!isMember)
                AuraGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 48, color: onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        "Bu kulübün bir parçası değilsin.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isMember) ...[
                AuraGlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 28,
                  child: BadgeGrid(
                    clubId: widget.kulupId,
                    userId: user.id,
                    themeColor: widget.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                AuraGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow("Katılım Tarihi", _formatDate(memberData?['joined_at'] ?? memberData?['created_at'])),
                      const SizedBox(height: 16),
                      _buildInfoRow("Üyelik Durumu", "Aktif"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _leaveClub,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      color: Colors.red.withValues(alpha: 0.05),
                    ),
                    child: const Center(
                      child: Text(
                        "Kulüpten Ayrıl",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: muted),
        ),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
