import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/models/event.dart';
import 'package:kulupi/models/club.dart';
import 'package:kulupi/models/profile.dart';
import 'package:intl/intl.dart';
import 'event_detail_page.dart';
import 'package:kulupi/utils/hex_color.dart';
import 'package:kulupi/widgets/aura_pull_to_refresh.dart';

class EventsDiscoveryTab extends StatefulWidget {
  const EventsDiscoveryTab({super.key});

  @override
  State<EventsDiscoveryTab> createState() => _EventsDiscoveryTabState();
}

class _EventsDiscoveryTabState extends State<EventsDiscoveryTab> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allEventsData = [];
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
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
    
    // Sort by date - already sorted by start_time from DB but double check
    upcoming.sort((a, b) {
      final dateA = DateTime.tryParse(a['start_time'].toString()) ?? DateTime.now();
      final dateB = DateTime.tryParse(b['start_time'].toString()) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
    
    return upcoming.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color subtle = onSurface.withValues(alpha: 0.35);
    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      body: AuraPullToRefresh(
        onRefresh: _loadEvents,
        child: CustomScrollView(
          slivers: [
            // 2. Calendar Section
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
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w500),
                      weekendTextStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
                      outsideTextStyle: TextStyle(color: subtle),
                      selectedDecoration: const BoxDecoration(
                        color: AuraTheme.kAccentCyan,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AuraTheme.kAccentCyan,
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      todayDecoration: BoxDecoration(
                        color: AuraTheme.kAccentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AuraTheme.kAccentCyan.withValues(alpha: 0.3)),
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AuraTheme.kAccentCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded, color: onSurface.withValues(alpha: 0.7)),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.7)),
                      headerPadding: const EdgeInsets.only(bottom: 12),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Selected Day Title
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
                        color: onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Events List for Selected Day
            if (_isLoading)
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
                              Icon(Icons.event_note_rounded, color: onSurface.withValues(alpha: 0.1), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                "Bugün için planlanmış etkinlik yok.",
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.45),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailPage(
                                event: event,
                                clubName: club.name,
                                accentColor: clubColor,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            // Time Box
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
                            // Event Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: TextStyle(
                                      color: onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                   Text(
                                     club.name,
                                     style: TextStyle(
                                       color: onSurface.withValues(alpha: 0.6),
                                       fontSize: 13,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: onSurface.withValues(alpha: 0.35)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _getEventsForDay(_selectedDay!).isEmpty ? 1 : _getEventsForDay(_selectedDay!).length,
                ),
              ),

            // 5. Featured/Upcoming Section
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
                        color: onSurface,
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
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AuraTheme.kAccentCyan))
                  : _getUpcomingEvents().isEmpty
                    ? Center(child: Text(
                        "Yaklaşan etkinlik yok",
                        style: TextStyle(color: onSurface.withValues(alpha: 0.4)),
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
                            child: _buildFeaturedCard(
                              event,
                              club,
                              clubColor,
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
    );
  }

  Widget _buildFeaturedCard(EventModel event, Club club, Color color) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);
    return AuraGlassCard(
      width: 280,
      padding: EdgeInsets.zero,
      borderRadius: 32,
      accentColor: color,
      showGlow: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(
              event: event,
              clubName: club.name,
              accentColor: color,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    DateFormat('d MMMM', 'tr_TR').format(event.startTime),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: color, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        club.name,
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
