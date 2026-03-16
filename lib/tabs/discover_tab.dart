import 'package:flutter/material.dart';
import 'package:kulupi/utils/hex_color.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/tabs/club_detail_page.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/models/club.dart';
import 'package:kulupi/models/profile.dart';
import 'package:kulupi/widgets/aura_pull_to_refresh.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:kulupi/models/event.dart';

class DiscoverClubsTab extends StatefulWidget {
  const DiscoverClubsTab({super.key});

  @override
  State<DiscoverClubsTab> createState() => _DiscoverClubsTabState();
}

class _DiscoverClubsTabState extends State<DiscoverClubsTab> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchText = "";
  List<Club> _allClubs = [];
  List<Club> _filteredClubs = [];
  bool _isLoading = true;
  Profile? _profile;
  int _selected = 0; // 0: Kulüpler, 1: Etkinlikler
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoadingEvents = true;
  List<Map<String, dynamic>> _allEventsData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _profile = await _authService.getCurrentProfile();
      if (_profile != null && _profile!.universityId != null) {
        _allClubs = await _dbService.getDiscoverableClubs(
          _profile!.id,
          _profile!.universityId!,
        );
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kulüpler yüklenemedi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchText.isEmpty) {
      _filteredClubs = _allClubs;
    } else {
      final searchLower = _searchText.toLowerCase();
      _filteredClubs = _allClubs.where((club) {
        return club.name.toLowerCase().contains(searchLower) ||
            club.description.toLowerCase().contains(searchLower) ||
            club.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoadingEvents = true);
    try {
      _profile = await _authService.getCurrentProfile();
      List<Map<String, dynamic>> data = [];
      if (_profile != null && _profile!.universityId != null) {
        data = await _dbService.getEventsByUniversity(_profile!.universityId!);
      }
      if (data.isEmpty) {
        final user = _authService.currentUser;
        if (user != null) {
          final memberships = await _dbService.getUserClubs(user.id);
          final clubIds = memberships.map((m) => m['club_id'] as int).toList();
          data = await _dbService.getEventsForClubs(clubIds);
        }
      }
      if (mounted) {
        setState(() {
          _allEventsData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Etkinlikler yüklenemedi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _allEventsData.where((item) {
      final event = EventModel.fromJson(item);
      return isSameDay(event.startTime, day);
    }).toList();
  }

  List<Map<String, dynamic>> _getUpcomingEvents() {
    final now = DateTime.now();
    final upcoming = _allEventsData.where((item) {
      final event = EventModel.fromJson(item);
      return event.startTime.isAfter(now);
    }).toList();
    upcoming.sort((a, b) {
      final dateA = DateTime.tryParse(a['start_time'].toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b['start_time'].toString()) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    return upcoming.take(5).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: AuraGlassCard(
              padding: const EdgeInsets.all(6),
              borderRadius: 16,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selected == 0 ? AuraTheme.kAccentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Kulüpler",
                          style: TextStyle(
                            color: _selected == 0 ? Colors.black : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selected == 1 ? AuraTheme.kAccentCyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Etkinlikler",
                          style: TextStyle(
                            color: _selected == 1 ? Colors.black : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- SEARCH BAR ---
          if (_selected == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: AuraSearchField(
                controller: _searchController,
                hintText: "İlgi alanına göre ara...",
                onChanged: (_) => _onSearchChanged(),
              ),
            ),

          // --- CLUB LIST ---
          Expanded(
            child: _selected == 0
                ? (_isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredClubs.isEmpty
                        ? _buildEmptyState(_searchText.isNotEmpty
                            ? "Sonuç bulunamadı."
                            : "Okulundaki tüm kulüplere üyesin! 🎉")
                        : AuraPullToRefresh(
                            onRefresh: _loadInitialData,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
                              itemCount: _filteredClubs.length,
                              itemBuilder: (context, index) {
                                final club = _filteredClubs[index];
                                return _buildAuraClubCard(context, club);
                              },
                            ),
                          ))
                : AuraPullToRefresh(
                    onRefresh: _loadEvents,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                            child: AuraGlassCard(
                              padding: const EdgeInsets.all(12),
                              borderRadius: 28,
                              child: TableCalendar(
                                firstDay: DateTime.utc(2024, 1, 1),
                                lastDay: DateTime.utc(2026, 12, 31),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                locale: 'tr_TR',
                                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                                onFormatChanged: (format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 20, 24, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AuraTheme.kAccentCyan,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDay == null 
                                      ? "Etkinlikler" 
                                      : "${DateFormat('d MMMM', 'tr_TR').format(_selectedDay!)} Etkinlikleri",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isLoadingEvents)
                          const SliverToBoxAdapter(
                            child: Center(child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AuraTheme.kAccentCyan),
                            )),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final dayEvents = _getEventsForDay(_selectedDay!);
                                if (dayEvents.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.all(60.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.event_note_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), size: 64),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Bugün için planlanmış etkinlik yok.",
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final item = dayEvents[index];
                                final event = EventModel.fromJson(item);
                                final club = Club.fromJson(item['clubs']);
                                final Color clubColor = hexToColor(club.mainColor);
                                
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                                  child: AuraGlassCard(
                                    padding: const EdgeInsets.all(16),
                                    borderRadius: 24,
                                    accentColor: clubColor,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: clubColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: clubColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            DateFormat('HH:mm').format(event.startTime),
                                            style: TextStyle(
                                              color: clubColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event.title,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                club.name,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _getEventsForDay(_selectedDay!).isEmpty ? 1 : _getEventsForDay(_selectedDay!).length,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 24, 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AuraTheme.kAccentCyan,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Yaklaşan Etkinlikler",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: _isLoadingEvents 
                              ? const Center(child: CircularProgressIndicator(color: AuraTheme.kAccentCyan))
                              : _getUpcomingEvents().isEmpty
                                ? Center(child: Text(
                                    "Yaklaşan etkinlik yok",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                                  ))
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    itemCount: _getUpcomingEvents().length,
                                    itemBuilder: (context, index) {
                                      final item = _getUpcomingEvents()[index];
                                      final event = EventModel.fromJson(item);
                                      final club = Club.fromJson(item['clubs']);
                                      final Color clubColor = hexToColor(club.mainColor);
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: AuraGlassCard(
                                          width: 280,
                                          borderRadius: 32,
                                          accentColor: clubColor,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  DateFormat('d MMMM', 'tr_TR').format(event.startTime),
                                                  style: TextStyle(color: clubColor, fontWeight: FontWeight.w900),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  event.title,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  club.name,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuraClubCard(BuildContext context, Club club) {
    final Color clubColor = hexToColor(club.mainColor);
    final String logoUrl = _dbService.getPublicUrl('clubs', club.logoPath);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);
    final Color subtle = onSurface.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AuraGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 32,
        accentColor: clubColor,
        showGlow: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClubDetailPage(club: club),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Gradient Overlay
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        clubColor.withValues(alpha: 0.25),
                        clubColor.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: clubColor.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: clubColor.withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: logoUrl.isNotEmpty
                              ? Image.network(logoUrl, fit: BoxFit.cover)
                              : Center(
                                  child: Text(
                                    club.shortName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: clubColor,
                                      fontSize: 20,
                                    ),
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
                              club.name,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: clubColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: clubColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                club.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: clubColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Description & Tags
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    club.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: club.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                        ),
                        child: Text(
                          "#$tag",
                          style: TextStyle(
                            color: subtle,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
