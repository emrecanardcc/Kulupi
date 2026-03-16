import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/models/faculty.dart';
import 'package:kulupi/models/department.dart';
import 'package:intl/intl.dart';

class ModernRegisterScreen extends StatefulWidget {
  const ModernRegisterScreen({super.key});

  @override
  State<ModernRegisterScreen> createState() => _ModernRegisterScreenState();
}

class _ModernRegisterScreenState extends State<ModernRegisterScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  // Adım kontrolü
  int _currentStep = 0;
  
  // Form kontrolleri
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Üniversite bilgileri
  List<University> _universities = [];
  University? _selectedUniversity;
  List<Faculty> _faculties = [];
  Faculty? _selectedFaculty;
  List<Department> _departments = [];
  Department? _selectedDepartment;

  // Diğer bilgiler
  DateTime? _birthDate;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _loadUniversities() async {
    try {
      final universities = await _dbService.getUniversities();
      if (mounted) {
        setState(() {
          _universities = universities;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Üniversiteler yüklenemedi: $e")),
        );
      }
    }
  }

  Future<void> _loadFaculties() async {
    if (_selectedUniversity == null) return;
    
    setState(() {
      _faculties = [];
      _selectedFaculty = null;
      _departments = [];
      _selectedDepartment = null;
    });
    
    try {
      final faculties = await _dbService.getFaculties(_selectedUniversity!.id);
      if (mounted) {
        setState(() {
          _faculties = faculties;
        });
      }
    } catch (e) {
      debugPrint("Fakülteler yüklenemedi: $e");
    }
  }

  Future<void> _loadDepartments() async {
    if (_selectedFaculty == null) return;
    
    setState(() {
      _departments = [];
      _selectedDepartment = null;
    });
    
    try {
      final departments = await _dbService.getDepartments(_selectedFaculty!.id);
      if (mounted) {
        setState(() {
          _departments = departments;
        });
      }
    } catch (e) {
      debugPrint("Bölümler yüklenemedi: $e");
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF2C5364),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _register() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedUniversity == null ||
        _selectedFaculty == null ||
        _selectedDepartment == null ||
        _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifreler uyuşmuyor")),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalı")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        universityId: _selectedUniversity!.id,
        facultyId: _selectedFaculty!.id,
        departmentId: _selectedDepartment!.id,
        birthDate: _birthDate,
      );

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF203A43).withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Kayıt Başarılı", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Kaydınız oluşturuldu. Lütfen email adresinizi onaylayın.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Tamam", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
        ),
        centerTitle: true,
        title: const Text("Kayıt", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= _currentStep
                        ? AuraTheme.kAccentCyan
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStep == 0 ? "Hadi Tanışalım" : "Üniversite Bilgileri",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0 ? "Kişisel bilgilerini girelim" : "Üniversite bilgilerini tamamla",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_currentStep == 0) ...[
                    const Text("İsim", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    AuraGlassTextField(
                      controller: _firstNameController,
                      hintText: "İsminizi girin",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    const Text("Soyisim", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    AuraGlassTextField(
                      controller: _lastNameController,
                      hintText: "Soyisminizi girin",
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 20),
                    const Text("Email", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    AuraGlassTextField(
                      controller: _emailController,
                      hintText: "Email adresinizi girin",
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.alternate_email,
                    ),
                    const SizedBox(height: 20),
                    const Text("Şifre", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AuraGlassTextField(
                            controller: _passwordController,
                            hintText: "Şifrenizi girin",
                            obscureText: _obscurePassword,
                            icon: Icons.lock_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AuraGlassCard(
                          borderRadius: 12,
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Şifre (Tekrar)", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AuraGlassTextField(
                            controller: _confirmPasswordController,
                            hintText: "Şifrenizi tekrar girin",
                            obscureText: _obscureConfirmPassword,
                            icon: Icons.lock_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AuraGlassCard(
                          borderRadius: 12,
                          padding: const EdgeInsets.all(8),
                          child: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Doğum Tarihi", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectBirthDate,
                      child: AuraGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.white70),
                            const SizedBox(width: 12),
                            Text(
                              _birthDate == null
                                  ? "Doğum tarihinizi seçin"
                                  : DateFormat('d MMMM yyyy', 'tr_TR').format(_birthDate!),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text("Üniversite", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    _buildDropdown<University>(
                      value: _selectedUniversity,
                      hint: "Üniversite seçin",
                      items: _universities,
                      itemLabel: (item) => item.name,
                      onChanged: (value) {
                        setState(() {
                          _selectedUniversity = value;
                          _loadFaculties();
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text("Fakülte", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    _buildDropdown<Faculty>(
                      value: _selectedFaculty,
                      hint: "Fakülte seçin",
                      items: _faculties,
                      itemLabel: (item) => item.name,
                      onChanged: (value) {
                        setState(() {
                          _selectedFaculty = value;
                          _loadDepartments();
                        });
                      },
                      isDisabled: _selectedUniversity == null,
                    ),
                    const SizedBox(height: 20),
                    const Text("Bölüm", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    _buildDropdown<Department>(
                      value: _selectedDepartment,
                      hint: "Bölüm seçin",
                      items: _departments,
                      itemLabel: (item) => item.name,
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      },
                      isDisabled: _selectedFaculty == null,
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentStep--;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Geri"),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentStep == 0
                              ? () {
                                  setState(() {
                                    _currentStep++;
                                  });
                                }
                              : _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuraTheme.kAccentCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_currentStep == 0 ? "Devam" : "Kayıt Ol"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool isDisabled = false,
  }) {
    return AuraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          dropdownColor: const Color(0xFF2C5364).withValues(alpha: 0.95),
          icon: Icon(Icons.arrow_drop_down, color: isDisabled ? Colors.grey : Colors.white),
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          onChanged: isDisabled ? null : onChanged,
          items: items.map<DropdownMenuItem<T>>((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
