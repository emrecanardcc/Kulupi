import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin_panel.dart';
import 'club_about_tab.dart';
import 'club_events_tab.dart';
import 'club_profile_tab.dart';
import '../models/club.dart';
// import '../models/app_enums.dart';
import '../utils/hex_color.dart';
import '../services/database_service.dart';
import '../utils/glass_components.dart';

class ClubDetailPage extends StatefulWidget {
  final Club club;

  const ClubDetailPage({
    super.key,
    required this.club,
  });

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // AppRole? _userRole;
  String? _roleName;
  bool _hasPendingRequest = false;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkMembershipStatus();
  }

  Future<void> _checkMembershipStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('club_members')
          .select('role, status')
          .eq('club_id', widget.club.id)
          .eq('user_id', user.id)
          .order('status', ascending: true) // approved(a) < pending(p) < rejected(r)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          setState(() {
            _isMember = data['status'] == 'approved';
            _hasPendingRequest = data['status'] == 'pending';
            _roleName = data['role'];
            // _userRole = AppRole.fromString(data['role']);
          });
        } else {
          setState(() {
            _isMember = false;
            _hasPendingRequest = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Üyelik kontrol hatası: $e");
    }
  }

  Future<void> _sendMembershipRequest() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('club_members').insert({
        'club_id': widget.club.id,
        'user_id': user.id,
        'role': 'member',
        'status': 'pending',
        'joined_at': DateTime.now().toIso8601String(),
      });
      _checkMembershipStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = hexToColor(widget.club.mainColor);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final db = DatabaseService();
    String normalizedRole = (() {
      final r = _roleName?.toLowerCase();
      if (r == 'president') return 'baskan';
      if (r == 'admin') return 'baskan_yardimcisi';
      if (r == 'member') return 'uye';
      return r ?? 'uye';
    })();
    bool isAdmin = normalizedRole == 'baskan';

    return AuraScaffold(
      auraColor: themeColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: onSurface, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Icon(Icons.admin_panel_settings_rounded, color: themeColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminPanel(
                        kulupId: widget.club.id.toString(),
                        kulupismi: widget.club.name,
                        primaryColor: themeColor,
                        currentUserRole: normalizedRole,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('clubs')
                        .stream(primaryKey: ['id'])
                        .eq('id', widget.club.id),
                    builder: (context, snap) {
                      final row = (snap.data != null && snap.data!.isNotEmpty) ? snap.data!.first : null;
                      final String name = row?['name'] ?? widget.club.name;
                      final String shortName = row?['short_name'] ?? widget.club.shortName;
                      final String category = row?['category'] ?? widget.club.category;
                      final String mainColorHex = row?['main_color'] ?? widget.club.mainColor;
                      final Color liveThemeColor = hexToColor(mainColorHex);
                      final String liveBannerPath = row?['banner_path'] ?? widget.club.bannerPath;
                      final String liveLogoPath = row?['logo_path'] ?? widget.club.logoPath;
                      final String liveBannerUrl = db.getPublicUrl('clubs', liveBannerPath);
                      final String liveLogoUrl = db.getPublicUrl('clubs', liveLogoPath);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          children: [
                        // Radical Header
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                image: liveBannerUrl.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(liveBannerUrl), fit: BoxFit.cover)
                                    : null,
                                color: AuraTheme.kGlassBase,
                              ),
                            ),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, AuraTheme.kMidnightBlack.withValues(alpha: 0.8)],
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, 40),
                              child: AuraGlassCard(
                                padding: const EdgeInsets.all(4),
                                borderRadius: 40,
                                accentColor: liveThemeColor,
                                showGlow: true,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(shape: BoxShape.circle),
                                  child: ClipOval(
                                    child: liveLogoUrl.isNotEmpty
                                        ? Image.network(liveLogoUrl, fit: BoxFit.cover)
                                        : Center(
                                            child: Text(
                                              shortName,
                                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: liveThemeColor),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            if (!_isMember)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: AuraGlassCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  borderRadius: 16,
                                  accentColor: _hasPendingRequest ? Colors.orange : liveThemeColor,
                                  onTap: () async {
                                      // Capture context before async operations
                                      final scaffoldContext = context;
                                      if (_hasPendingRequest) {
                                        try {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          if (user == null) return;
                                          await Supabase.instance.client
                                              .from('club_members')
                                              .delete()
                                              .eq('club_id', widget.club.id)
                                              .eq('user_id', user.id)
                                              .eq('status', 'pending');
                                          // Check mounted before calling setState or using context
                                          if (mounted) {
                                            _checkMembershipStatus();
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                              SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      } else {
                                        await _sendMembershipRequest();
                                      }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _hasPendingRequest ? Icons.hourglass_empty_rounded : Icons.person_add_alt_1_rounded,
                                        color: _hasPendingRequest ? Colors.orange : liveThemeColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _hasPendingRequest ? "İSTEĞİ GERİ ÇEK" : "İSTEK GÖNDER",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 60),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: (Theme.of(context).textTheme.displaySmall ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))
                              .copyWith(fontSize: 28, fontWeight: FontWeight.w900, color: onSurface),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: liveThemeColor.withValues(alpha: 0.5)),
                            color: liveThemeColor.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(color: liveThemeColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Tab Bar
                        AuraGlassCard(
                          padding: const EdgeInsets.all(6),
                          borderRadius: 20,
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: liveThemeColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: onSurface.withValues(alpha: 0.6),
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: const [
                              Tab(text: "Hikaye"),
                              Tab(text: "Sahne"),
                              Tab(text: "Ekip"),
                            ],
                          ),
                        ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                ClubAboutTab(description: widget.club.description),
                ClubEventsTab(kulupId: widget.club.id.toString(), primaryColor: themeColor),
                ClubProfileTab(
                  kulupId: widget.club.id.toString(),
                  kulupIsmi: widget.club.name,
                  primaryColor: themeColor,
                  onTabChanged: (index) => _tabController.animateTo(index),
                ),
              ],
            ),
          ),
          
          
        ],
      ),
    );
  }
}
