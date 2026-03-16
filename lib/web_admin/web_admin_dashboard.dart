import 'package:flutter/material.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/web_admin/web_admin_panel.dart'; 
import 'package:kulupi/web_admin/academic_manager.dart';
import 'package:kulupi/web_admin/university_manager.dart';
import 'package:kulupi/web_admin/user_management_panel.dart';
import 'package:kulupi/web_admin/statistics_panel.dart';
import 'package:kulupi/web_admin/system_settings_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _connectionStatus = "Test ediliyor...";
    });
    
    try {
      // En basit sorgu: Herhangi bir tablodan veri çekmeyi dene
      await Supabase.instance.client
          .from('universities')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _connectionStatus = "BAŞARILI! ✅";
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = "HATA: ${e.toString()}";
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _fetchStats() async {
    try {
      final client = Supabase.instance.client;
      
      // Zaman aşımı ekleyelim (10 saniye)
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
      debugPrint("İstatistikler yüklenemedi: $e");
      if (mounted) {
        setState(() {
          _statsLoading = false;
          // Eğer veriler gelmediyse varsayılan 0 değerlerini göster
          _clubCount = 0;
          _memberCount = 0;
          _eventCount = 0;
          _sponsorCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bağlantı hatası: Veriler çekilemedi. Supabase projenizin aktif olduğundan emin olun."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          
          // Main Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: RefreshIndicator(
                onRefresh: _fetchStats,
                child: _buildMainContent(),
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
          // Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.rocket_launch, color: Colors.cyanAccent, size: 32),
              const SizedBox(width: 10),
              const Text(
                "Kulüpi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Yönetim Paneli",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
          const SizedBox(height: 50),
          
          // Menu Items
          _buildSidebarItem(0, Icons.dashboard, "Genel Bakış"),
          _buildSidebarItem(1, Icons.people, "Kullanıcılar"),
          _buildSidebarItem(2, Icons.groups, "Kulüp Yönetimi"),
          _buildSidebarItem(3, Icons.event, "Etkinlikler"),
          _buildSidebarItem(4, Icons.store, "Sponsorlar"),
          _buildSidebarItem(5, Icons.school, "Üniversiteler"),
          _buildSidebarItem(6, Icons.account_tree, "Akademik Yapı"),
          _buildSidebarItem(7, Icons.analytics, "İstatistikler"),
          _buildSidebarItem(8, Icons.settings, "Ayarlar"),
          
          const Spacer(),
          
          // Connection Test Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Supabase Bağlantısı",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _connectionStatus,
                    style: TextStyle(
                      color: _connectionStatus.contains("BAŞARILI") ? Colors.greenAccent : 
                             _connectionStatus.contains("HATA") ? Colors.redAccent : Colors.white70,
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTesting ? null : _testConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                      ),
                      child: _isTesting 
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Bağlantıyı Test Et"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.cyanAccent,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Admin",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Super Admin",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
                    onPressed: () {},
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
      case 0:
        return _buildOverview();
      case 1:
        return const UserManagementPanel();
      case 2:
        return const ClubManagementView();
      case 3:
        return const GlobalEventManagement();
      case 4:
        return const SponsorManager();
      case 5:
        return const UniversityManager();
      case 6:
        return const AcademicManager();
      case 7:
        return const StatisticsPanel();
      case 8:
        return const SystemSettingsPanel();
      default:
        return const Center(child: Text("İçerik Bulunamadı", style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildOverview() {
    if (_statsLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Genel Bakış",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildStatCard("Toplam Kulüp", _clubCount.toString(), Icons.groups, Colors.cyanAccent),
              const SizedBox(width: 20),
              _buildStatCard("Aktif Üye", _memberCount.toString(), Icons.person, Colors.orangeAccent),
              const SizedBox(width: 20),
              _buildStatCard("Etkinlikler", _eventCount.toString(), Icons.event, Colors.purpleAccent),
              const SizedBox(width: 20),
              _buildStatCard("Sponsorlar", _sponsorCount.toString(), Icons.store, Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            "Son Aktiviteler",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: AuraGlassCard(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Supabase.instance.client
                    .from('events')
                    .select('*')
                    .order('start_time', ascending: false)
                    .limit(5),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Aktiviteler yüklenemedi: ${snapshot.error}",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final activities = snapshot.data ?? [];
                  
                  if (activities.isEmpty) {
                    return const Center(
                      child: Text("Henüz bir aktivite yok.", style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.separated(
                    itemCount: activities.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.notifications_none, color: Colors.cyanAccent),
                        ),
                        title: Text(
                          activity['title'] ?? "Yeni Etkinlik",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "${activity['location']} - ${activity['start_time'].toString().substring(0, 10)}",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
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
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
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
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white70, size: 22),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClubManagementView extends StatefulWidget {
  const ClubManagementView({super.key});

  @override
  State<ClubManagementView> createState() => _ClubManagementViewState();
}

class _ClubManagementViewState extends State<ClubManagementView> {
  bool _showCreator = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showCreator ? "Yeni Kulüp" : "Kulüp Yönetimi",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showCreator = !_showCreator),
                icon: Icon(_showCreator ? Icons.list : Icons.add),
                label: Text(_showCreator ? "Listeye Dön" : "Yeni Kulüp Ekle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ],
          ),
        ),
        //Expanded(
          //child: _showCreator ? const ClubCreator() : const AllClubsManager(),
        //),
      ],
    );
  }
}
