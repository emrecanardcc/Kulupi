import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/main.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/tabs/events_discovery_tab.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/models/faculty.dart';
import 'package:kulupi/models/department.dart';
import 'package:intl/intl.dart';

class WebLandingPage extends StatefulWidget {
  final bool isLoggedIn;
  const WebLandingPage({super.key, this.isLoggedIn = false});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8), 
      builder: (BuildContext context) => const Dialog(backgroundColor: Colors.transparent, child: _LoginModalForm()),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8), 
      builder: (BuildContext context) => const Dialog(backgroundColor: Colors.transparent, child: _RegisterModalForm()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFF071013),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(isMobile),
                _buildEventsShowcase(isMobile, screenWidth), 
                const SizedBox(height: 100),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text("© 2026 Kulüpi - Kampüsün Dijital Kalbi", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
          ),

          // 2. SABİT ÜST MENÜ (NAVBAR) - LOGO BURADA DEĞİŞTİ
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isMobile ? 70 : 80,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
              decoration: BoxDecoration(
                color: _isScrolled ? const Color(0xFF0F2027).withValues(alpha: 0.95) : Colors.transparent,
                border: Border(bottom: BorderSide(color: _isScrolled ? Colors.white.withValues(alpha: 0.1) : Colors.transparent)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // LOGO EKLENDİ (İkon kaldırıldı)
                      Image.asset(
                        'assets/logo.png', 
                        width: isMobile ? 32 : 40, 
                        height: isMobile ? 32 : 40, 
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Kulüpi",
                        style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                      ),
                    ],
                  ),
                  
                  if (!widget.isLoggedIn)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _showRegisterDialog(context),
                          child: Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16)),
                        ),
                        SizedBox(width: isMobile ? 8 : 24),
                        ElevatedButton(
                          onPressed: () => _showLoginDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuraTheme.kAccentCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 16),
                          ),
                          child: Text("GİRİŞ YAP", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: isMobile ? 12 : 14)),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthWrapper()));
                      },
                      icon: Icon(Icons.logout, size: isMobile ? 16 : 18),
                      label: Text(isMobile ? "ÇIKIŞ" : "ÇIKIŞ YAP", style: TextStyle(fontSize: isMobile ? 12 : 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.0,
          colors: [Color(0xFF1E3C4B), Color(0xFF071013)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: isMobile ? 300 : 600,
            height: isMobile ? 300 : 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraTheme.kAccentCyan.withValues(alpha: 0.05),
              boxShadow: [BoxShadow(color: AuraTheme.kAccentCyan.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AuraTheme.kAccentCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AuraTheme.kAccentCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text("🚀 KULÜPİ ARTIK YAYINDA", style: TextStyle(color: AuraTheme.kAccentCyan, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: isMobile ? 10 : 14)),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                Text(
                  "Kampüsün Dijital\nKalbi Atıyor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 48 : 80, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -2),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  "Tüm etkinlikler, kulüpler ve duyurular cebinde.\nÜniversite hayatını kaçırma, hemen uygulamamızı indir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isMobile ? 16 : 20, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                SizedBox(height: isMobile ? 32 : 40),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStoreButton(Icons.apple, "App Store'dan", "İndir"),
                    _buildStoreButton(Icons.android, "Google Play'den", "İndir"),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            bottom: isMobile ? 20 : 40,
            child: Column(
              children: [
                const Text("Keşfet", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 8),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.5), size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreButton(IconData icon, String subtitle, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEventsShowcase(bool isMobile, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: isMobile ? 40 : 80),
      color: const Color(0xFF0B171C),
      child: Column(
        children: [
          Text(
            "Yaklaşan Etkinlikler",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 32 : 40, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            "Kampüste neler olup bittiğini gör. Etkileşime geçmek için aşağı kaydır!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 14 : 18, color: Colors.white.withValues(alpha: 0.5)),
          ),
          SizedBox(height: isMobile ? 32 : 60),
          Container(
            height: isMobile ? 600 : 800, 
            width: isMobile ? screenWidth * 0.95 : 1200, 
            decoration: BoxDecoration(
              color: const Color(0xFF0F2027),
              borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(isMobile ? 24 : 32)),
              child: const EventsDiscoveryTab(), 
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GİRİŞ YAP MODALI
// ============================================================================
class _LoginModalForm extends StatefulWidget {
  const _LoginModalForm();

  @override
  State<_LoginModalForm> createState() => _LoginModalFormState();
}

class _LoginModalFormState extends State<_LoginModalForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _girisYap() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(email: _emailController.text.trim(), password: _passwordController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthWrapper()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Giriş başarısız, bilgileri kontrol edin."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: AuraGlassCard(
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        accentColor: AuraTheme.kAccentCyan,
        showGlow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), 
                const Text("GİRİŞ YAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 32),
            AuraGlassTextField(controller: _emailController, hintText: "E-posta Adresi", icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            AuraGlassTextField(controller: _passwordController, hintText: "Şifre", obscureText: true, icon: Icons.lock_outline_rounded),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: AuraTheme.kAccentCyan)
                : SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _girisYap,
                      style: ElevatedButton.styleFrom(backgroundColor: AuraTheme.kAccentCyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text("BAŞLAT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2 AŞAMALI YENİ KAYIT OL MODALI
// ============================================================================
class _RegisterModalForm extends StatefulWidget {
  const _RegisterModalForm();

  @override
  State<_RegisterModalForm> createState() => _RegisterModalFormState();
}

class _RegisterModalFormState extends State<_RegisterModalForm> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  int _currentStep = 0;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  List<University> _universities = [];
  University? _selectedUniversity;
  List<Faculty> _faculties = [];
  Faculty? _selectedFaculty;
  List<Department> _departments = [];
  Department? _selectedDepartment;

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
      if (mounted) setState(() => _universities = universities);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Üniversiteler yüklenemedi: $e")));
    }
  }

  Future<void> _loadFaculties() async {
    if (_selectedUniversity == null) return;
    setState(() { _faculties = []; _selectedFaculty = null; _departments = []; _selectedDepartment = null; });
    try {
      final faculties = await _dbService.getFaculties(_selectedUniversity!.id);
      if (mounted) setState(() => _faculties = faculties);
    } catch (e) {
      debugPrint("Fakülteler yüklenemedi: $e");
    }
  }

  Future<void> _loadDepartments() async {
    if (_selectedFaculty == null) return;
    setState(() { _departments = []; _selectedDepartment = null; });
    try {
      final departments = await _dbService.getDepartments(_selectedFaculty!.id);
      if (mounted) setState(() => _departments = departments);
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
            colorScheme: const ColorScheme.dark(primary: AuraTheme.kAccentCyan, onPrimary: Colors.black, surface: Color(0xFF2C5364), onSurface: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _kayitOl() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _emailController.text.isEmpty ||
        _passwordController.text.isEmpty || _selectedUniversity == null || _selectedFaculty == null ||
        _selectedDepartment == null || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun")));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor")));
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre en az 6 karakter olmalı")));
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
      Navigator.of(context).pop(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarılı! Lütfen giriş yapın."), backgroundColor: Colors.green));
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.message}"), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450, maxHeight: 800), 
      child: AuraGlassCard(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        accentColor: AuraTheme.kAccentCyan,
        showGlow: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), 
                const Text("KAYIT OL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) => Container(
                  width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: index <= _currentStep ? AuraTheme.kAccentCyan : Colors.white.withValues(alpha: 0.3)),
                )),
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentStep == 0) ...[
                      if (isMobile) ...[
                        AuraGlassTextField(controller: _firstNameController, hintText: "İsim", icon: Icons.person_outline),
                        const SizedBox(height: 12),
                        AuraGlassTextField(controller: _lastNameController, hintText: "Soyisim", icon: Icons.badge_outlined),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(child: AuraGlassTextField(controller: _firstNameController, hintText: "İsim", icon: Icons.person_outline)),
                            const SizedBox(width: 12),
                            Expanded(child: AuraGlassTextField(controller: _lastNameController, hintText: "Soyisim", icon: Icons.badge_outlined)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      AuraGlassTextField(controller: _emailController, hintText: "Email Adresi", keyboardType: TextInputType.emailAddress, icon: Icons.alternate_email),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: AuraGlassTextField(controller: _passwordController, hintText: "Şifre", obscureText: _obscurePassword, icon: Icons.lock_outline)),
                          const SizedBox(width: 12),
                          AuraGlassCard(
                            padding: const EdgeInsets.all(4),
                            child: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(child: AuraGlassTextField(controller: _confirmPasswordController, hintText: "Şifre (Tekrar)", obscureText: _obscureConfirmPassword, icon: Icons.lock_outline)),
                          const SizedBox(width: 12),
                          AuraGlassCard(
                            padding: const EdgeInsets.all(4),
                            child: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: _selectBirthDate,
                        child: AuraGlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text(
                                _birthDate == null ? "Doğum Tarihinizi Seçin" : DateFormat('d MMMM yyyy', 'tr_TR').format(_birthDate!),
                                style: TextStyle(color: _birthDate == null ? Colors.white54 : Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      _buildDropdown<University>(
                        value: _selectedUniversity, hint: "Üniversite seçin", items: _universities, itemLabel: (item) => item.name,
                        onChanged: (value) => setState(() { _selectedUniversity = value; _loadFaculties(); }),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Faculty>(
                        value: _selectedFaculty, hint: "Fakülte seçin", items: _faculties, itemLabel: (item) => item.name, isDisabled: _selectedUniversity == null,
                        onChanged: (value) => setState(() { _selectedFaculty = value; _loadDepartments(); }),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<Department>(
                        value: _selectedDepartment, hint: "Bölüm seçin", items: _departments, itemLabel: (item) => item.name, isDisabled: _selectedFaculty == null,
                        onChanged: (value) => setState(() => _selectedDepartment = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Geri"),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _currentStep == 0 ? () => setState(() => _currentStep++) : (_isLoading ? null : _kayitOl),
                    style: ElevatedButton.styleFrom(backgroundColor: AuraTheme.kAccentCyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_currentStep == 0 ? "DEVAM ET" : "KAYIT OL", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({required T? value, required String hint, required List<T> items, required String Function(T) itemLabel, required void Function(T?) onChanged, bool isDisabled = false}) {
    return AuraGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          dropdownColor: const Color(0xFF2C5364).withValues(alpha: 0.95),
          icon: Icon(Icons.arrow_drop_down, color: isDisabled ? Colors.grey : Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isExpanded: true,
          onChanged: isDisabled ? null : onChanged,
          items: items.map<DropdownMenuItem<T>>((T item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item), style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
      ),
    );
  }
}