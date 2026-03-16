import 'package:flutter/material.dart';
import 'package:kulupi/tabs/discover_tab.dart';
import 'package:kulupi/tabs/my_clubs_tab.dart';
import 'package:kulupi/tabs/modern_user_profile_tab.dart';
import 'package:kulupi/tabs/coming_soon_tab.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/widget/notification_bell.dart';

class MainHub extends StatefulWidget {
  const MainHub({super.key});

  @override
  State<MainHub> createState() => _MainHubState();
}

class _MainHubState extends State<MainHub> {
  int _pageIndex = 1; // Start at "My Clubs"
  
  // Page List
  final List<Widget> _pages = [
    const DiscoverClubsTab(),   // 0: Keşfet (Kulüpler)
    const ComingSoonTab(),      // 1: Yakında
    const MyClubsTab(),         // 2: Kulüplerim (Ana Sayfa)
    const ModernUserProfileTab(),     // 3: Profil
  ];

  /* void _openAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatSheet(),
    );
  } */

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black; // Tam siyah
    final Color subTextColor = isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black; // Tam siyah

    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan, // Default neutral aura
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Kulüpi',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _pageIndex == 0
                        ? "Keşfet"
                        : _pageIndex == 1
                            ? "Yakında"
                            : _pageIndex == 2
                                ? "Kulüplerim"
                                : "Profil",
                    key: ValueKey<int>(_pageIndex),
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.w900, // Kalınlaştırıldı
                      fontSize: 18, // Biraz büyütüldü (15 -> 18)
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: NotificationBell(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20),
        child: AuraGlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 8),
          borderRadius: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.explore_rounded, "Keşfet"),
              _buildNavItem(1, Icons.upcoming_rounded, "Yakında"),
              _buildNavItem(2, Icons.home_rounded, "Kulüplerim"),
              _buildNavItem(3, Icons.person_rounded, "Profil"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _pageIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Premium Colors (Brand Cyan)
    final Color activeColor = AuraTheme.kAccentCyan; 
    final Color unselectedColor = isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF94A3B8); // Slate 400

    return GestureDetector(
      onTap: () => setState(() => _pageIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected && !isDark ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : unselectedColor,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
