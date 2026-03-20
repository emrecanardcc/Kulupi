import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/models/faculty.dart';
import 'package:kulupi/models/department.dart';
import 'package:kulupi/utils/glass_components.dart';

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('universities').select().order('name');
      if (mounted) {
        setState(() {
          _universities = (data as List).map((json) => University.fromJson(json)).toList();
          if (_universities.isNotEmpty) {
            _selectedUniversity = _universities.first;
            _loadFaculties(_selectedUniversity!.id);
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Üniversiteler yüklenemedi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFaculties(int universityId) async {
    try {
      final data = await _supabase.from('faculties').select().eq('university_id', universityId).order('name');
      if (mounted) {
        setState(() {
          _faculties = (data as List).map((json) => Faculty.fromJson(json)).toList();
          _selectedFaculty = null;
          _departments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fakülteler yüklenemedi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDepartments(int facultyId) async {
    try {
      final data = await _supabase.from('departments').select().eq('faculty_id', facultyId).order('name');
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
          decoration: const InputDecoration(hintText: "Fakülte Adı", hintStyle: TextStyle(color: Colors.white54), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("İptal", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _supabase.from('faculties').insert({'university_id': _selectedUniversity!.id, 'name': controller.text.trim()});
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
          decoration: const InputDecoration(hintText: "Bölüm Adı", hintStyle: TextStyle(color: Colors.white54), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("İptal", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _supabase.from('departments').insert({'faculty_id': _selectedFaculty!.id, 'name': controller.text.trim()});
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
    try {
      await _supabase.from('faculties').delete().eq('id', id);
      if (_selectedUniversity != null) _loadFaculties(_selectedUniversity!.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Önce bu fakülteye bağlı bölümleri silmelisiniz."), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteDepartment(int id) async {
    await _supabase.from('departments').delete().eq('id', id);
    if (_selectedFaculty != null) _loadDepartments(_selectedFaculty!.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Akademik Yapı Yöneticisi",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ÜNİVERSİTELER
                Expanded(
                  child: AuraGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                          child: const Text("1. Üniversiteler", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _universities.length,
                            itemBuilder: (context, index) {
                              final uni = _universities[index];
                              final isSelected = _selectedUniversity?.id == uni.id;
                              return ListTile(
                                leading: const Icon(Icons.school, color: Colors.white54, size: 20),
                                title: Text(uni.name, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                selected: isSelected,
                                selectedTileColor: Colors.cyanAccent.withValues(alpha: 0.1),
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
                ),
                const SizedBox(width: 20),
                
                // 2. FAKÜLTELER
                Expanded(
                  child: AuraGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("2. Fakülteler", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyanAccent), onPressed: _selectedUniversity == null ? null : _addFaculty),
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
                                    leading: const Icon(Icons.domain, color: Colors.white54, size: 20),
                                    title: Text(faculty.name, style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteFaculty(faculty.id)),
                                    selected: isSelected,
                                    selectedTileColor: Colors.cyanAccent.withValues(alpha: 0.1),
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
                const SizedBox(width: 20),

                // 3. BÖLÜMLER
                Expanded(
                  child: AuraGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("3. Bölümler", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyanAccent), onPressed: _selectedFaculty == null ? null : _addDepartment),
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
                                    leading: const Icon(Icons.class_, color: Colors.white54, size: 20),
                                    title: Text(dept.name, style: const TextStyle(color: Colors.white)),
                                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _deleteDepartment(dept.id)),
                                  );
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}