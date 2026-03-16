import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/models/faculty.dart';
import 'package:kulupi/models/department.dart';
import 'package:kulupi/web_admin/university_manager.dart';

class AcademicManager extends StatefulWidget {
  const AcademicManager({super.key});

  @override
  State<AcademicManager> createState() => _AcademicManagerState();
}

class _AcademicManagerState extends State<AcademicManager> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<University> _universities = [];
  University? _selectedUniversity;
  
  List<Faculty> _faculties = [];
  Faculty? _selectedFaculty;
  
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final data = await _supabase.from('universities').select().order('name').timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _universities = (data as List).map((json) => University.fromJson(json)).toList();
          if (_universities.isNotEmpty) {
            _selectedUniversity = _universities.first;
            _loadFaculties(_selectedUniversity!.id);
          }
        });
      }
    } catch (e) {
      debugPrint("Üniversiteler yüklenemedi: $e");
    }
  }

  Future<void> _loadFaculties(int universityId) async {
    try {
      final data = await _supabase
          .from('faculties')
          .select()
          .eq('university_id', universityId)
          .order('name')
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _faculties = (data as List).map((json) => Faculty.fromJson(json)).toList();
          _selectedFaculty = null;
          _departments = [];
        });
      }
    } catch (e) {
      debugPrint("Fakülteler yüklenemedi: $e");
    }
  }

  Future<void> _loadDepartments(int facultyId) async {
    try {
      final data = await _supabase
          .from('departments')
          .select()
          .eq('faculty_id', facultyId)
          .order('name')
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _departments = (data as List).map((json) => Department.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint("Bölümler yüklenemedi: $e");
    }
  }

  Future<void> _addFaculty() async {
    if (_selectedUniversity == null) return;
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: const Text("Yeni Fakülte Ekle", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Fakülte Adı",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _supabase.from('faculties').insert({
                  'university_id': _selectedUniversity!.id,
                  'name': controller.text.trim(),
                });
                if (dialogContext.mounted) {
                  _loadFaculties(_selectedUniversity!.id);
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text("Ekle", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _addDepartment() async {
    if (_selectedFaculty == null) return;
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: const Text("Yeni Bölüm Ekle", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Bölüm Adı",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _supabase.from('departments').insert({
                  'faculty_id': _selectedFaculty!.id,
                  'name': controller.text.trim(),
                });
                if (dialogContext.mounted) {
                  _loadDepartments(_selectedFaculty!.id);
                  Navigator.pop(dialogContext);
                }
              }
            },
            child: const Text("Ekle", style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFaculty(int id) async {
    await _supabase.from('faculties').delete().eq('id', id);
    if (_selectedUniversity != null) _loadFaculties(_selectedUniversity!.id);
  }

  Future<void> _deleteDepartment(int id) async {
    await _supabase.from('departments').delete().eq('id', id);
    if (_selectedFaculty != null) _loadDepartments(_selectedFaculty!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Üst navigasyon butonları
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UniversityManager(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: const Text("Üniversiteler"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.account_tree),
                  label: const Text("Akademik Yapı"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Sol Panel: Üniversiteler
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black26,
                      child: const Text("1. Üniversite Seç", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _universities.length,
                        itemBuilder: (context, index) {
                          final uni = _universities[index];
                          final isSelected = _selectedUniversity?.id == uni.id;
                          return ListTile(
                            title: Text(uni.name, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white)),
                            selected: isSelected,
                            selectedTileColor: Colors.white10,
                            onTap: () {
                              setState(() {
                                _selectedUniversity = uni;
                                _loadFaculties(uni.id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        
              // Orta Panel: Fakülteler
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.white10))),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black26,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("2. Fakülteler", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.cyanAccent),
                              onPressed: _selectedUniversity == null ? null : _addFaculty,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedUniversity == null 
                          ? const Center(child: Text("Önce Üniversite Seçin", style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: _faculties.length,
                              itemBuilder: (context, index) {
                                final faculty = _faculties[index];
                                final isSelected = _selectedFaculty?.id == faculty.id;
                                return ListTile(
                                  title: Text(faculty.name, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteFaculty(faculty.id),
                                  ),
                                  selected: isSelected,
                                  selectedTileColor: Colors.white10,
                                  onTap: () {
                                    setState(() {
                                      _selectedFaculty = faculty;
                                      _loadDepartments(faculty.id);
                                    });
                                  },
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sağ Panel: Bölümler
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("3. Bölümler", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.cyanAccent),
                            onPressed: _selectedFaculty == null ? null : _addDepartment,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedFaculty == null 
                        ? const Center(child: Text("Önce Fakülte Seçin", style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final dept = _departments[index];
                              return ListTile(
                                title: Text(dept.name, style: const TextStyle(color: Colors.white)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteDepartment(dept.id),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
