import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/main_hub.dart';
import 'package:kulupi/register_modern.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/main.dart'; // EKLENDİ: AuthWrapper'a ulaşabilmek için

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _sifrekontrol = TextEditingController();
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  List<University> _universities = [];
  bool _isLoading = false;
  final bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _loadUniversities();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AuraGlassCard(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          borderRadius: 32,
          accentColor: AuraTheme.kAccentCyan,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: AuraTheme.kAccentCyan, size: 28),
                  SizedBox(width: 12),
                  Text(
                    "ŞİFRE SIFIRLA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Email adresinize şifre sıfırlama bağlantısı göndereceğiz.",
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              AuraGlassTextField(
                controller: emailController,
                hintText: "Email adresinizi girin",
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("İPTAL", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraTheme.kAccentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _resetPassword(emailController.text.trim());
                      },
                      child: const Text("GÖNDER", style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen email adresinizi girin")),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://kulupi.com/login', // GÜNCELLENDİ: Gerçek domainini yazdık
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Şifre sıfırlama bağlantısı email adresinize gönderildi."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  Future<void> _loadUniversities() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final unis = await _dbService.getUniversities();
      if (mounted) {
        setState(() {
          _universities = unis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Üniversiteler yüklenemedi: $e"),
            action: SnackBarAction(
              label: "Tekrar Dene",
              onPressed: _loadUniversities,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _sifrekontrol.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (_emailController.text.isEmpty || _sifrekontrol.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifrenizi girin")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _sifrekontrol.text.trim(),
      );

      if (!mounted) return;
      // DÜZELTME: Girişten sonra AuthWrapper'a yönlendir ki rolümüzü kontrol edip doğru sayfayı açsın
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    } on AuthException catch (e) {
      String hataMesaji = "Giriş başarısız: ${e.message}";
      if (e.message.contains("Invalid login credentials")) {
        hataMesaji = "E-posta veya şifre hatalı.";
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hataMesaji), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Beklenmedik bir hata: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraTheme.kAccentCyan.withValues(alpha: 0.1),
                  border: Border.all(color: AuraTheme.kAccentCyan.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: AuraTheme.kAccentCyan.withValues(alpha: 0.15),
                      blurRadius: 40,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: AuraTheme.kAccentCyan,
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                "Kulüpi",
                style: AuraTheme.kHeadingDisplay,
              ),
              const SizedBox(height: 8),
              Text(
                "Kampüsün Dijital Kalbi",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 48),

              // --- BİRLEŞTİRİLMİŞ GİRİŞ ALANI ---
              AuraGlassCard(
                padding: const EdgeInsets.all(24),
                accentColor: AuraTheme.kAccentCyan,
                showGlow: true,
                child: Column(
                  children: [
                    const Text(
                      "GİRİŞ YAP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // E-posta
                    AuraGlassTextField(
                      controller: _emailController,
                      hintText: "E-posta Adresi",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    
                    const SizedBox(height: 16),

                    // Şifre
                    AuraGlassTextField(
                      controller: _sifrekontrol,
                      hintText: "Şifre",
                      obscureText: _isObscured,
                      icon: Icons.lock_outline_rounded,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Şifremi Unuttum
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text(
                          "Şifremi Unuttum",
                          style: TextStyle(
                            color: AuraTheme.kAccentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Giriş Butonu
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AuraTheme.kAccentCyan))
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _girisYap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AuraTheme.kAccentCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "BAŞLAT",
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Kayıt Ol Linki
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ModernRegisterScreen()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Hesabın yok mu? ",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    children: const [
                      TextSpan(
                        text: "Kayıt Ol",
                        style: TextStyle(
                          color: AuraTheme.kAccentCyan,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}