import 'package:flutter/material.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/web_admin/web_admin_panel.dart'; 
import 'package:kulupi/web_admin/academic_manager.dart';
import 'package:kulupi/web_admin/university_manager.dart'; // Üniversiteler Geri Geldi!
import 'package:kulupi/web_admin/statistics_panel.dart';
import 'package:kulupi/web_admin/system_settings_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/services/auth_service.dart'; 
import 'package:kulupi/main.dart'; 

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;
  
  // İstatistikler için state
  int _clubCount = 0;
  int _memberCount = 0;
  int _eventCount = 0;
  int _sponsorCount = 0;
  bool _statsLoading = true;

  // Bağlantı testi için state
  String _connectionStatus = "Bilinmiyor";
  bool _isTesting = false;

  // Admin Kullanıcı Bilgileri
  String _adminName = "Yükleniyor...";
  String _adminEmail = "Yükleniyor...";
  String _adminRole = "ADMIN";

  @override
  void initState() {
    super.initState();
    _fetchAdminDetails();
    _fetchStats();
  }

  Future<void> _fetchAdminDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      if (mounted) setState(() => _adminEmail = user.email ?? "Bilinmeyen E-posta");
      
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
            
        if (mounted) {
          setState(() {
            // Artık full_name yerine first_name ve last_name'i birleştiriyoruz (Veritabanı temizliğine uyumlu)
            _adminName = "${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}".trim();
            if (_adminName.isEmpty) _adminName = "Yetkili Kullanıcı";
            _adminRole = profile['role']?.toString().toUpperCase() ?? "ADMIN";
          });
        }
      } catch (e) {
        if (mounted) setState(() => _adminName = "Yetkili Kullanıcı");
      }
    }
  }

  Future<void> _cikisYap() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false, 
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = "Test ediliyor...";
    });
    
    try {
      await Supabase.instance.client.from('universities').select('id').limit(1).timeout(const Duration(seconds: 10));
      if (mounted) setState(() { _connectionStatus = "BAŞARILI! ✅"; _isTesting = false; });
    } catch (e) {
      if (mounted) setState(() { _connectionStatus = "HATA: ${e.toString()}"; _isTesting = false; });
    }
  }

  Future<void> _fetchStats() async {
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('clubs').select('*').count(CountOption.exact).timeout(const Duration(seconds: 10)),
        client.from('profiles').select('*').count(CountOption.exact).timeout(const Duration(seconds: 10)),
        client.from('events').select('*').count(CountOption.exact).timeout(const Duration(seconds: 10)),
        client.from('app_sponsors').select('*').count(CountOption.exact).timeout(const Duration(seconds: 10)),
      ]);

      if (mounted) {
        setState(() {
          _clubCount = results[0].count;
          _memberCount = results[1].count;
          _eventCount = results[2].count;
          _sponsorCount = results[3].count;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _clubCount = 0; _memberCount = 0; _eventCount = 0; _sponsorCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SizedBox.expand(
                child: ClipRRect(
                  child: RefreshIndicator(
                    onRefresh: _fetchStats,
                    child: _buildMainContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', width: 32, height: 32, errorBuilder: (context, error, stackTrace) => const Icon(Icons.rocket_launch, color: Colors.cyanAccent, size: 32)),
              const SizedBox(width: 10),
              const Text("Kulüpi", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 10),
          Text("Yönetim Paneli", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          const SizedBox(height: 50),
          
          _buildSidebarItem(0, Icons.dashboard_rounded, "Genel Bakış"),
          _buildSidebarItem(1, Icons.people_alt_rounded, "Kullanıcı Yönetimi"),
          _buildSidebarItem(2, Icons.groups_rounded, "Kulüp Yönetimi"),
          _buildSidebarItem(3, Icons.event_rounded, "Etkinlikler"),
          _buildSidebarItem(4, Icons.storefront_rounded, "Sponsorlar"),
          _buildSidebarItem(5, Icons.account_balance_rounded, "Üniversiteler"), // Üniversiteler eklendi
          _buildSidebarItem(6, Icons.account_tree_rounded, "Akademik Yapı"),     // Sıralama kaydırıldı
          _buildSidebarItem(7, Icons.analytics_rounded, "İstatistikler"),
          _buildSidebarItem(8, Icons.settings_rounded, "Sistem Ayarları"),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Supabase Bağlantısı", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _connectionStatus.contains("BAŞARILI") ? Colors.greenAccent : _connectionStatus.contains("HATA") ? Colors.redAccent : Colors.white70,
                      fontSize: 10,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTesting ? null : _testConnection,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2), foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 10), padding: EdgeInsets.zero),
                      child: _isTesting ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Bağlantıyı Test Et"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                    child: Text(_adminName.isNotEmpty ? _adminName[0].toUpperCase() : "A", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_adminName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_adminRole, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    tooltip: "Güvenli Çıkış",
                    onPressed: _cikisYap,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildOverview();
      case 1: return _buildUserManagementView(); // Gelişmiş Kullanıcı Yönetimi
      case 2: return const ClubManagementView();
      case 3: return const GlobalEventManagement();
      case 4: return const SponsorManager();
      case 5: return const UniversityManager();  // Üniversiteler Sayfası Bağlandı!
      case 6: return const AcademicManager();
      case 7: return const StatisticsPanel();
      case 8: return const SystemSettingsPanel();
      default: return const Center(child: Text("İçerik Bulunamadı", style: TextStyle(color: Colors.white)));
    }
  }

  // =========================================================================
  // GÜNCELLENMİŞ: KULLANICI YÖNETİMİ PANELİ (DOĞRU SÜTUNLARLA)
  // =========================================================================
  Widget _buildUserManagementView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kullanıcı Yönetimi", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text("Sistemdeki kullanıcıların hesaplarını manuel onaylayın veya engelleyin.", style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16)),
          const SizedBox(height: 32),
          
          Expanded(
            child: AuraGlassCard(
              padding: const EdgeInsets.all(0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client.from('profiles').select().order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Kullanıcılar yüklenemedi: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                  }

                  final users = snapshot.data ?? [];
                  if (users.isEmpty) return const Center(child: Text("Sistemde henüz kullanıcı yok.", style: TextStyle(color: Colors.white70)));

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.3)),
                        dataRowMinHeight: 70,
                        dataRowMaxHeight: 70,
                        columnSpacing: 30,
                        columns: const [
                          DataColumn(label: Text('Profil', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('E-posta', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Rolü', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('E-posta Onayı', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))), // is_verified
                          DataColumn(label: Text('Admin Onayı', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))), // is_manually_verified
                          DataColumn(label: Text('Ban (Engel)', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))), // is_banned
                        ],
                        rows: users.map((user) {
                          // SQL dosyanla birebir uyumlu okumalar:
                          final fullName = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
                          final role = user['role']?.toString().toUpperCase() ?? 'MEMBER';
                          
                          // Supabase bazen string 'true', bazen boolean true dönebilir. Güvenli kontrol:
                          final isVerified = user['is_verified']?.toString() == 'true'; 
                          final isManuallyVerified = user['is_manually_verified']?.toString() == 'true';
                          final isBanned = user['is_banned']?.toString() == 'true';

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                              return isBanned ? Colors.red.withValues(alpha: 0.1) : null; // Banlıysa satırı kızartır
                            }),
                            cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                                    child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(fullName.isNotEmpty ? fullName : "İsimsiz Kullanıcı", style: TextStyle(color: isBanned ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              )),
                              DataCell(Text(user['email'] ?? 'Bulunamadı', style: const TextStyle(color: Colors.white70))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: role == 'ADMIN' ? Colors.purpleAccent.withValues(alpha: 0.2) : Colors.cyanAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: role == 'ADMIN' ? Colors.purpleAccent.withValues(alpha: 0.5) : Colors.cyanAccent.withValues(alpha: 0.3)),
                                ),
                                child: Text(role, style: TextStyle(color: role == 'ADMIN' ? Colors.purpleAccent : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              )),
                              
                              // is_verified (E-posta onaylı mı?) - Sadece gösterim
                              DataCell(Row(
                                children: [
                                  Icon(isVerified ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded, color: isVerified ? Colors.greenAccent : Colors.orangeAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(isVerified ? "Onaylı" : "Bekliyor", style: TextStyle(color: isVerified ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              )),
                              
                              // is_manually_verified (Admin Onayı) - Şalter
                              DataCell(
                                Switch(
                                  value: isManuallyVerified,
                                  activeColor: Colors.greenAccent,
                                  inactiveThumbColor: Colors.grey,
                                  onChanged: (val) async {
                                    try {
                                      await Supabase.instance.client.from('profiles').update({'is_manually_verified': val}).eq('id', user['id']);
                                      setState(() {}); 
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "Kullanıcı sisteme kabul edildi." : "Kullanıcı onayı geri alındı."), backgroundColor: val ? Colors.green : Colors.orange));
                                    } catch(e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red));
                                    }
                                  },
                                )
                              ),

                              // is_banned (Engel/Ban durumu) - Şalter (Kırmızı)
                              DataCell(
                                Switch(
                                  value: isBanned,
                                  activeColor: Colors.redAccent,
                                  inactiveThumbColor: Colors.grey,
                                  onChanged: (val) async {
                                    try {
                                      await Supabase.instance.client.from('profiles').update({'is_banned': val}).eq('id', user['id']);
                                      setState(() {}); 
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "Kullanıcı BANLANDI!" : "Kullanıcının engeli kaldırıldı."), backgroundColor: val ? Colors.red : Colors.green));
                                    } catch(e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e"), backgroundColor: Colors.red));
                                    }
                                  },
                                )
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // GENEL BAKIŞ PANELİ
  // =========================================================================
  Widget _buildOverview() {
    if (_statsLoading) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Genel Bakış", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatCard("Toplam Kulüp", _clubCount.toString(), Icons.groups_rounded, Colors.cyanAccent),
              const SizedBox(width: 20),
              _buildStatCard("Kayıtlı Profil", _memberCount.toString(), Icons.person_rounded, Colors.orangeAccent),
              const SizedBox(width: 20),
              _buildStatCard("Etkinlikler", _eventCount.toString(), Icons.local_fire_department_rounded, Colors.pinkAccent),
              const SizedBox(width: 20),
              _buildStatCard("Sponsorlar", _sponsorCount.toString(), Icons.storefront_rounded, Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Son Aktiviteler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Expanded(
            child: AuraGlassCard(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client.from('events').select('*').order('start_time', ascending: false).limit(5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                  if (snapshot.hasError) return Center(child: Text("Aktiviteler yüklenemedi: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                  final activities = snapshot.data ?? [];
                  if (activities.isEmpty) return const Center(child: Text("Henüz bir aktivite yok.", style: TextStyle(color: Colors.white70)));

                  return ListView.separated(
                    itemCount: activities.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1), child: const Icon(Icons.notifications_active_rounded, color: Colors.cyanAccent)),
                        title: Text(activity['title'] ?? "Yeni Etkinlik", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        subtitle: Text("${activity['location']} - ${activity['start_time'].toString().substring(0, 10)}", style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AuraGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)) : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white54, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}