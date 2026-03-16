import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/university.dart';
import '../models/club.dart';
import '../models/club_member.dart';
import '../models/event.dart';
import '../models/profile.dart';
import '../models/app_enums.dart';
import '../models/sponsor.dart';

import '../models/faculty.dart';
import '../models/department.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Faculties & Departments ---
  Future<List<Faculty>> getFaculties(int universityId) async {
    try {
      final data = await _supabase
          .from('faculties')
          .select()
          .eq('university_id', universityId)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));
      return (data as List).map((json) => Faculty.fromJson(json)).toList();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Fakülteler yüklenirken zaman aşımı oluştu.');
      }
      rethrow;
    }
  }

  Future<List<Department>> getDepartments(int facultyId) async {
    try {
      final data = await _supabase
          .from('departments')
          .select()
          .eq('faculty_id', facultyId)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));
      return (data as List).map((json) => Department.fromJson(json)).toList();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Bölümler yüklenirken zaman aşımı oluştu.');
      }
      rethrow;
    }
  }

  // --- Storage Helpers ---
  String getPublicUrl(String bucket, String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path; // Already a URL
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  // --- Sponsors ---
  Future<List<Sponsor>> getSponsors() async {
    final data = await _supabase
        .from('app_sponsors')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((json) => Sponsor.fromJson(json)).toList();
  }

  // --- Universities ---
  Future<List<University>> getUniversities() async {
    try {
      final data = await _supabase
          .from('universities')
          .select('id, name, short_name, domain')
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));
      return (data as List).map((json) => University.fromJson(json)).toList();
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Bağlantı zaman aşımına uğradı. Lütfen internetinizi kontrol edin.');
      }
      final message = e.toString();
      if (message.contains('Failed host lookup') || message.contains('SocketException')) {
        throw Exception('Supabase adresine ulaşılamıyor. SUPABASE_URL ve internet bağlantısını kontrol edin.');
      }
      rethrow;
    }
  }

  // --- Clubs ---
  Future<List<Club>> getClubsByUniversity(int universityId) async {
    final data = await _supabase
        .from('clubs')
        .select()
        .eq('university_id', universityId)
        .timeout(const Duration(seconds: 15));
    return (data as List).map((json) => Club.fromJson(json)).toList();
  }

  Future<Club> getClubById(int clubId) async {
    final data = await _supabase
        .from('clubs')
        .select()
        .eq('id', clubId)
        .single()
        .timeout(const Duration(seconds: 10));
    return Club.fromJson(data);
  }

  // --- Memberships ---
  Future<void> joinClub(int clubId, String userId) async {
    // 1. Get user profile
    final profileData = await _supabase.from('profiles').select().eq('id', userId).single().timeout(const Duration(seconds: 10));
    final profile = Profile.fromJson(profileData);

    // 2. Get club university
    final clubData = await _supabase.from('clubs').select('university_id').eq('id', clubId).single().timeout(const Duration(seconds: 10));
    final clubUniId = clubData['university_id'] as int;

    // 3. Verify university match
    if (profile.universityId != clubUniId) {
      throw Exception("Sadece kendi üniversitenizdeki kulüplere katılabilirsiniz.");
    }

    // 4. Insert membership
    await _supabase.from('club_members').insert({
      'club_id': clubId,
      'user_id': userId,
      'role': AppRole.member.toJson(),
      'status': MemberStatus.pending.toJson(),
      'joined_at': DateTime.now().toIso8601String(),
    }).timeout(const Duration(seconds: 15));
  }

  Future<List<ClubMember>> getUserMemberships(String userId) async {
    final data = await _supabase
        .from('club_members')
        .select()
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 15));
    return (data as List).map((json) => ClubMember.fromJson(json)).toList();
  }

  Future<String?> getUniversityName(int id) async {
    final data = await _supabase.from('universities').select('name').eq('id', id).single().timeout(const Duration(seconds: 10));
    return data['name'] as String?;
  }

  Future<String?> getFacultyName(int id) async {
    final data = await _supabase.from('faculties').select('name').eq('id', id).single().timeout(const Duration(seconds: 10));
    return data['name'] as String?;
  }

  Future<String?> getDepartmentName(int id) async {
    final data = await _supabase.from('departments').select('name').eq('id', id).single().timeout(const Duration(seconds: 10));
    return data['name'] as String?;
  }

  // --- OPTIMIZED: Get club members with profiles in single query ---
  Future<List<Map<String, dynamic>>> getClubMembersWithProfiles(int clubId) async {
    final data = await _supabase
        .from('club_members')
        .select('*, profiles!inner(*)')
        .eq('club_id', clubId)
        .order('role', ascending: true)
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(data);
  }

  // --- OPTIMIZED: Get pending requests with profiles in single query ---
  Future<List<Map<String, dynamic>>> getPendingRequestsWithProfiles(int clubId) async {
    final data = await _supabase
        .from('club_members')
        .select('*, profiles!inner(*)')
        .eq('club_id', clubId)
        .eq('status', MemberStatus.pending.toJson())
        .order('joined_at', ascending: true)
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getUserClubs(String userId) async {
    final data = await _supabase
        .from('club_members')
        .select('*, clubs(*)')
        .eq('user_id', userId)
        .eq('status', MemberStatus.approved.toJson())
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getUserPendingRequests(String userId) async {
    final data = await _supabase
        .from('club_members')
        .select('*, clubs(*)')
        .eq('user_id', userId)
        .eq('status', MemberStatus.pending.toJson())
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Club>> getDiscoverableClubs(String userId, int universityId) async {
    // 1) Tüm kulüpleri getir
    final allClubsData = await _supabase
        .from('clubs')
        .select()
        .eq('university_id', universityId)
        .timeout(const Duration(seconds: 15));
    final allClubs = (allClubsData as List).map((json) => Club.fromJson(json)).toList();

    // 2) Üye olunan kulüplerin ID'lerini getir
    final memberships = await _supabase
        .from('club_members')
        .select('club_id')
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 10));
    final memberClubIds = (memberships as List).map((m) => m['club_id'] as int).toSet();

    // 3) Üye olmadıklarını filtrele (client-side)
    final discoverable = allClubs.where((c) => !memberClubIds.contains(c.id)).toList();
    return discoverable;
  }

  // --- Events ---
  Future<List<Map<String, dynamic>>> getEventsByUniversity(int universityId) async {
    // 1) Etkinlikleri kulüp join ile çek (speakers olmadan)
    final eventsData = await _supabase
        .from('events')
        .select('*, clubs!inner(*)')
        .eq('clubs.university_id', universityId)
        .order('start_time', ascending: true)
        .timeout(const Duration(seconds: 15));
    final List<Map<String, dynamic>> events = List<Map<String, dynamic>>.from(eventsData);

    // 2) Konuşmacıları her etkinlik için ayrı çek ve göm
    for (final event in events) {
      final int eventId = event['id'] as int;
      try {
        final speakersData = await _supabase
            .from('event_speakers')
            .select()
            .eq('event_id', eventId)
            .timeout(const Duration(seconds: 10));
        event['event_speakers'] = List<Map<String, dynamic>>.from(speakersData);
      } catch (_) {
        event['event_speakers'] = <Map<String, dynamic>>[];
      }
    }
    return events;
  }

  Future<List<Map<String, dynamic>>> getEventsForClubs(List<int> clubIds) async {
    if (clubIds.isEmpty) return [];
    final List<Map<String, dynamic>> combined = [];
    for (final id in clubIds) {
      // Etkinlikleri çek
      final eventsData = await _supabase
          .from('events')
          .select('*, clubs!inner(*)')
          .eq('club_id', id)
          .order('start_time', ascending: true)
          .timeout(const Duration(seconds: 15));
      final List<Map<String, dynamic>> events = List<Map<String, dynamic>>.from(eventsData);
      // Konuşmacıları göm
      for (final event in events) {
        final int eventId = event['id'] as int;
        try {
          final speakersData = await _supabase
              .from('event_speakers')
              .select()
              .eq('event_id', eventId)
              .timeout(const Duration(seconds: 10));
          event['event_speakers'] = List<Map<String, dynamic>>.from(speakersData);
        } catch (_) {
          event['event_speakers'] = <Map<String, dynamic>>[];
        }
      }
      combined.addAll(events);
    }
    combined.sort((a, b) => DateTime.parse(a['start_time']).compareTo(DateTime.parse(b['start_time'])));
    return combined;
  }

  Future<List<EventModel>> getClubEvents(int clubId) async {
    // 1) Etkinlikleri çek (speakers olmadan)
    final eventsData = await _supabase
        .from('events')
        .select()
        .eq('club_id', clubId)
        .order('start_time', ascending: true)
        .timeout(const Duration(seconds: 15));
    final List<Map<String, dynamic>> events = List<Map<String, dynamic>>.from(eventsData);

    // 2) Konuşmacıları her etkinlik için ayrı çek ve modelle
    final List<EventModel> result = [];
    for (final e in events) {
      final int eventId = e['id'] as int;
      try {
        final speakersData = await _supabase
            .from('event_speakers')
            .select()
            .eq('event_id', eventId)
            .order('id', ascending: true)
            .timeout(const Duration(seconds: 10));
        e['event_speakers'] = List<Map<String, dynamic>>.from(speakersData);
      } catch (_) {
        e['event_speakers'] = <Map<String, dynamic>>[];
      }
      result.add(EventModel.fromJson(e));
    }
    return result;
  }

  Future<int> createEvent({
    required int clubId,
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
  }) async {
    final data = await _supabase.from('events').insert({
      'club_id': clubId,
      'title': title,
      'description': description,
      'location': location,
      'start_time': startTime.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();
    return data['id'] as int;
  }
}
