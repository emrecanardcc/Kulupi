import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/models/event.dart';
import 'package:kulupi/utils/glass_components.dart';

class AdminEventsTab extends StatefulWidget {
  final String kulupId;
  final Color primaryColor;

  const AdminEventsTab({
    super.key,
    required this.kulupId,
    required this.primaryColor,
  });

  @override
  State<AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends State<AdminEventsTab> {
  final _eventNameController = TextEditingController();
  final _eventDescController = TextEditingController();
  final _eventLocationController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isSubmitting = false;
  Future<List<Map<String, dynamic>>>? _eventsFuture;
  final List<_SpeakerFormData> _speakers = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    setState(() {
      _eventsFuture = Supabase.instance.client
          .from('events')
          .select('*, event_speakers(*)')
          .eq('club_id', widget.kulupId)
          .order('start_time', ascending: true)
          .timeout(const Duration(seconds: 15));
    });
  }

  Future<void> _createEvent() async {
    if (_eventNameController.text.trim().isEmpty ||
        _eventDescController.text.trim().isEmpty ||
        _eventLocationController.text.trim().isEmpty ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedDateTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçmiş tarihli etkinlik oluşturulamaz"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final eventResponse = await Supabase.instance.client.from('events').insert({
        'club_id': int.parse(widget.kulupId),
        'title': _eventNameController.text.trim(),
        'description': _eventDescController.text.trim(),
        'location': _eventLocationController.text.trim(),
        'start_time': _selectedDateTime!.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final eventId = eventResponse['id'] as int;
      final speakerRows = _speakers
          .where((speaker) => speaker.fullNameController.text.trim().isNotEmpty)
          .map((speaker) {
        return {
          'event_id': eventId,
          'full_name': speaker.fullNameController.text.trim(),
          'linkedin_url': speaker.linkedinController.text.trim().isEmpty ? null : speaker.linkedinController.text.trim(),
          'bio': speaker.bioController.text.trim().isEmpty ? null : speaker.bioController.text.trim(),
        };
      }).toList();

      if (speakerRows.isNotEmpty) {
        await Supabase.instance.client.from('event_speakers').insert(speakerRows);
      }

      _eventNameController.clear();
      _eventDescController.clear();
      _eventLocationController.clear();
      setState(() {
        _selectedDateTime = null;
        _speakers.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Etkinlik yayınlandı!"), backgroundColor: Colors.green),
        );
      }
      _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      await Supabase.instance.client.from('event_speakers').delete().eq('event_id', eventId);
      await Supabase.instance.client.from('events').delete().eq('id', eventId);
      _loadEvents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Etkinlik silinemedi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDateTime() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.cyanAccent,
                    onPrimary: Colors.black,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: widget.primaryColor,
                    onPrimary: Colors.white,
                    surface: colorScheme.surface,
                    onSurface: colorScheme.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    if (!mounted) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addSpeaker() {
    setState(() {
      _speakers.add(_SpeakerFormData());
    });
  }

  void _removeSpeaker(int index) {
    setState(() {
      _speakers[index].dispose();
      _speakers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescController.dispose();
    _eventLocationController.dispose();
    for (final speaker in _speakers) {
      speaker.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.7);
    final Color subtle = onSurface.withValues(alpha: 0.5);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          AuraGlassCard(
            accentColor: widget.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Yeni Etkinlik Oluştur",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuraGlassTextField(controller: _eventNameController, hintText: "Etkinlik Adı"),
                  const SizedBox(height: 12),
                  AuraGlassTextField(controller: _eventDescController, hintText: "Açıklama", maxLines: 3),
                  const SizedBox(height: 12),
                  AuraGlassTextField(controller: _eventLocationController, hintText: "Konum"),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateTime == null
                                ? "Tarih ve Saat Seçin"
                                : DateFormat('d MMMM yyyy HH:mm', 'tr_TR').format(_selectedDateTime!),
                            style: TextStyle(
                              color: _selectedDateTime == null ? subtle : onSurface,
                              fontSize: 16,
                            ),
                          ),
                          Icon(Icons.calendar_today_rounded, color: widget.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Konuşmacılar",
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSpeaker,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        label: const Text("Ekle"),
                        style: TextButton.styleFrom(foregroundColor: widget.primaryColor),
                      ),
                    ],
                  ),
                  if (_speakers.isEmpty)
                    Text(
                      "Konuşmacı eklemek isteğe bağlıdır.",
                      style: TextStyle(color: subtle, fontSize: 13),
                    ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_speakers.length, (index) {
                      final speaker = _speakers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AuraGlassCard(
                          accentColor: onSurface.withValues(alpha: 0.2),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Konuşmacı ${index + 1}",
                                      style: TextStyle(
                                        color: muted,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeSpeaker(index),
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AuraGlassTextField(
                                  controller: speaker.fullNameController,
                                  hintText: "Ad Soyad",
                                ),
                                const SizedBox(height: 10),
                                AuraGlassTextField(
                                  controller: speaker.linkedinController,
                                  hintText: "LinkedIn URL (opsiyonel)",
                                ),
                                const SizedBox(height: 10),
                                AuraGlassTextField(
                                  controller: speaker.bioController,
                                  hintText: "Kısa Biyografi (opsiyonel)",
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(Colors.black12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
                            )
                          : const Text(
                              "ETKİNLİĞİ YAYINLA",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _eventsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: widget.primaryColor));
              }

              if (snapshot.hasError) {
                return Text("Etkinlikler yüklenemedi: ${snapshot.error}", style: const TextStyle(color: Colors.red));
              }

              final eventsData = snapshot.data ?? [];
              if (eventsData.isEmpty) {
                return Text(
                  "Henüz etkinlik yok.",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                );
              }

              final now = DateTime.now();
              final events = eventsData.map((item) => EventModel.fromJson(item)).toList();
              final upcoming = events.where((event) => event.startTime.isAfter(now)).toList();
              final past = events.where((event) => event.startTime.isBefore(now)).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Yaklaşan Etkinlikler", upcoming.isNotEmpty),
                  const SizedBox(height: 16),
                  if (upcoming.isEmpty)
                    _buildEmptyState("Yaklaşan etkinlik yok."),
                  ...upcoming.map((event) => _buildEventCard(event, false)),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Geçmiş Etkinlikler", false),
                  const SizedBox(height: 16),
                  if (past.isEmpty)
                    _buildEmptyState("Geçmiş etkinlik yok."),
                  ...past.map((event) => _buildEventCard(event, true)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isActive) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? widget.primaryColor : onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isActive ? onSurface : onSurface.withValues(alpha: 0.6),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: onSurface.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isPast) {
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);
    final Color subtle = onSurface.withValues(alpha: 0.4);
    final dateText = DateFormat('d MMM yyyy', 'tr_TR').format(event.startTime);
    final timeText = DateFormat('HH:mm').format(event.startTime);
    final cardColor = isPast ? onSurface.withValues(alpha: 0.2) : widget.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AuraGlassCard(
        accentColor: cardColor,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor.withValues(alpha: 0.1),
              border: Border.all(color: cardColor.withValues(alpha: 0.2)),
            ),
            child: Icon(
              isPast ? Icons.history_rounded : Icons.event_available_rounded,
              color: cardColor,
              size: 24,
            ),
          ),
          title: Text(
            event.title,
            style: TextStyle(
              color: isPast ? subtle : onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: -0.5,
              decoration: isPast ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$dateText • $timeText",
              style: TextStyle(
                color: isPast ? subtle : muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _deleteEvent(event.id),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeakerFormData {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  void dispose() {
    fullNameController.dispose();
    linkedinController.dispose();
    bioController.dispose();
  }
}
