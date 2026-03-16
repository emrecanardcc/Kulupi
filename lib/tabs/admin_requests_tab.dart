import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/utils/glass_components.dart';

class AdminRequestsTab extends StatefulWidget {
  final String kulupId;
  final Color primaryColor;

  const AdminRequestsTab({
    super.key,
    required this.kulupId,
    required this.primaryColor,
  });

  @override
  State<AdminRequestsTab> createState() => _AdminRequestsTabState();
}

class _AdminRequestsTabState extends State<AdminRequestsTab> {
  bool _isLoading = false;

  Future<void> _uyeIslemi(
    String userId,
    bool onayla,
  ) async {
    setState(() => _isLoading = true);
    try {
      if (onayla) {
        // İsteği onayla: status'ü 'approved' yap
        await Supabase.instance.client
            .from('club_members')
            .update({'status': 'approved'})
            .eq('club_id', int.parse(widget.kulupId))
            .eq('user_id', userId);
      } else {
        // İsteği reddet: kaydı sil
        await Supabase.instance.client
            .from('club_members')
            .delete()
            .eq('club_id', int.parse(widget.kulupId))
            .eq('user_id', userId)
            .eq('status', 'pending');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(onayla ? "İstek onaylandı!" : "İstek reddedildi."),
            backgroundColor: onayla ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('club_members')
          .stream(primaryKey: ['club_id', 'user_id'])
          .eq('club_id', int.parse(widget.kulupId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allData = snapshot.data ?? [];
        final pendingData = allData.where((d) => d['status'] == 'pending').toList();

        if (pendingData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_disabled_rounded,
                  size: 64,
                  color: onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  "Bekleyen üyelik isteği yok.",
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: pendingData.length,
          itemBuilder: (context, index) {
            final data = pendingData[index];
            final String userId = data['user_id'];
            
            // Not: StreamBuilder join desteklemediği için user bilgilerini 
            // FutureBuilder veya başka bir yöntemle çekmek gerekebilir.
            // Ancak mevcut yapıda display_name club_members içinde yoksa 
            // profil tablosundan çekilmeli.
            
            return FutureBuilder<Map<String, dynamic>>(
              future: Supabase.instance.client
                  .from('profiles')
                  .select('full_name, first_name, last_name, email, display_name')
                  .eq('id', userId)
                  .single(),
              builder: (context, profileSnapshot) {
                final profile = profileSnapshot.data;
                final String name = () {
                  if (profile == null) return "Yükleniyor...";
                  return profile['full_name'] ??
                      ((profile['first_name'] != null || profile['last_name'] != null)
                          ? "${(profile['first_name'] ?? '').toString().trim()} ${(profile['last_name'] ?? '').toString().trim()}".trim()
                          : (profile['display_name'] ?? profile['email'] ?? "Kullanıcı"));
                }();
                final String email = profile?['email'] ?? "";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AuraGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 24,
                    accentColor: widget.primaryColor,
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: widget.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(Icons.person, color: widget.primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  color: onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.close_rounded,
                              color: Colors.redAccent,
                              onTap: () => _uyeIslemi(userId, false),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.check_rounded,
                              color: Colors.greenAccent,
                              onTap: () => _uyeIslemi(userId, true),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
