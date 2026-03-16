import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/university.dart';
import '../models/club.dart';
import '../models/club_member.dart';
import '../models/profile.dart';
import '../models/app_enums.dart';
import '../models/sponsor.dart';
import '../models/faculty.dart';
import '../models/department.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache for frequently accessed data
  final Map<String, dynamic> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  DateTime _lastCacheClear = DateTime.now();

  void _clearExpiredCache() {
    if (DateTime.now().difference(_lastCacheClear) > _cacheDuration) {
      _cache.clear();
      _lastCacheClear = DateTime.now();
    }
  }

  // --- Faculties & Departments ---
  Future<List<Faculty>> getFaculties(int universityId) async {
    try {
      final cacheKey = 'faculties_$universityId';
      _clearExpiredCache();
      
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as List<Faculty>;
      }

      final data = await _supabase
          .from('faculties')
          .select()
          .eq('university_id', universityId)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));
      
      final faculties = (data as List).map((json) => Faculty.fromJson(json)).toList();
      _cache[cacheKey] = faculties;
      return faculties;
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

  // --- OPTIMIZED: Get user clubs with profiles ---
  Future<List<Map<String, dynamic>>> getUserClubsWithProfiles(String userId) async {
    final data = await _supabase
        .from('club_members')
        .select('*, clubs!inner(*), profiles!inner(*)')
        .eq('user_id', userId)
        .eq('status', MemberStatus.approved.toJson())
        .order('joined_at', ascending: false)
        .timeout(const Duration(seconds: 15));
    return List<Map<String, dynamic>>.from(data);
  }

  // --- Existing methods for compatibility ---
  Future<List<Map<String, dynamic>>> getUserClubs(String userId) async {
    return getUserClubsWithProfiles(userId);
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

    // 2) Her etkinlik için speakers'ları ayrı sorgu ile çek
    for (var event in events) {
      final speakersData = await _supabase
          .from('event_speakers')
          .select()
          .eq('event_id', event['id'])
          .timeout(const Duration(seconds: 10));
      event['speakers'] = speakersData;
    }

    return events;
  }

  Future<void> createEvent({
    required int clubId,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime? endTime,
    String? location,
    String? imagePath,
    List<Map<String, dynamic>> speakers = const [],
  }) async {
    // 1) Etkinlik oluştur
    final eventData = await _supabase.from('events').insert({
      'club_id': clubId,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location': location,
      'image_path': imagePath,
    }).select().single().timeout(const Duration(seconds: 15));

    final eventId = eventData['id'] as int;

    // 2) Konuşmacıları ekle
    if (speakers.isNotEmpty) {
      final speakersToInsert = speakers.map((s) => {
        'event_id': eventId,
        'full_name': s['full_name'],
        'linkedin_url': s['linkedin_url'],
        'bio': s['bio'],
      }).toList();

      await _supabase.from('event_speakers').insert(speakersToInsert).timeout(const Duration(seconds: 15));
    }
  }

  // --- Profile ---
  Future<Profile> getProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single()
        .timeout(const Duration(seconds: 10));
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(Profile profile) async {
    await _supabase
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .timeout(const Duration(seconds: 15));
  }

  // --- Club Management ---
  Future<void> updateClub(Club club) async {
    await _supabase
        .from('clubs')
        .update({
          'name': club.name,
          'short_name': club.shortName,
          'description': club.description,
          'category': club.category,
          'main_color': club.mainColor,
          'logo_path': club.logoPath,
          'banner_path': club.bannerPath,
        })
        .eq('id', club.id)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> updateMemberRole(int clubId, String userId, AppRole role) async {
    await _supabase
        .from('club_members')
        .update({'role': role.toJson()})
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> deleteMember(int clubId, String userId) async {
    await _supabase
        .from('club_members')
        .delete()
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> approveMember(int clubId, String userId) async {
    await _supabase
        .from('club_members')
        .update({'status': MemberStatus.approved.toJson()})
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .timeout(const Duration(seconds: 15));
  }

  Future<void> rejectMember(int clubId, String userId) async {
    await _supabase
        .from('club_members')
        .delete()
        .eq('club_id', clubId)
        .eq('user_id', userId)
        .eq('status', MemberStatus.pending.toJson())
        .timeout(const Duration(seconds: 15));
  }
}