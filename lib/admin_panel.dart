import 'package:flutter/material.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/tabs/admin_requests_tab.dart';
import 'package:kulupi/tabs/admin_events_tab.dart';
import 'package:kulupi/tabs/admin_members_tab.dart';
import 'package:kulupi/tabs/admin_settings_tab.dart';

class AdminPanel extends StatefulWidget {
  final String kulupId;
  final String kulupismi;
  final Color primaryColor;
  final String currentUserRole;
  final bool isSuperAdmin; // YENİ

  const AdminPanel({
    super.key,
    required this.kulupId,
    required this.kulupismi,
    required this.primaryColor,
    required this.currentUserRole,
    this.isSuperAdmin = false, // Varsayılan false
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _setupTabsByRole();
  }

  void _setupTabsByRole() {
    List<Widget> tabs = [
      const Tab(icon: Icon(Icons.person_add), text: "İstekler"),
    ];

    if (widget.currentUserRole != 'uye') {
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
    }

    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
    }

    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return AuraScaffold(
      auraColor: widget.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: onSurface, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.kulupismi} Yönetimi",
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(4),
              borderRadius: 20,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: onSurface.withValues(alpha: 0.6),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: _getTabs(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _getTabViews(),
      ),
    );
  }

  List<Widget> _getTabs() {
    List<Widget> tabs = [
      const Tab(icon: Icon(Icons.person_add), text: "İstekler"),
    ];
    if (widget.currentUserRole != 'uye') {
      tabs.add(const Tab(icon: Icon(Icons.event), text: "Etkinlikler"));
    }
    if (widget.currentUserRole == 'baskan') {
      tabs.add(const Tab(icon: Icon(Icons.people), text: "Üyeler"));
      tabs.add(const Tab(icon: Icon(Icons.settings), text: "Ayarlar"));
    }
    return tabs;
  }

  List<Widget> _getTabViews() {
    List<Widget> views = [
      AdminRequestsTab(
        kulupId: widget.kulupId,
        primaryColor: widget.primaryColor,
      )
    ];

    if (widget.currentUserRole != 'uye') {
      views.add(AdminEventsTab(
        kulupId: widget.kulupId,
        primaryColor: widget.primaryColor,
      ));
    }

    if (widget.currentUserRole == 'baskan') {
      // isSuperAdmin bilgisini buraya iletiyoruz 👇
      views.add(
        AdminMembersTab(
          kulupId: widget.kulupId,
          currentUserRole: widget.currentUserRole,
          isSuperAdmin: widget.isSuperAdmin,
          primaryColor: widget.primaryColor,
          
        ),
      );
      views.add(
        AdminSettingsTab(
          kulupId: widget.kulupId,
          primaryColor: widget.primaryColor,
          currentUserRole :widget.currentUserRole,
          isSuperAdmin : widget.isSuperAdmin,
        ),
      );
    }
    return views;
  }
}
