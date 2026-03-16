import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kulupi/login.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/utils/theme_provider.dart';
import 'package:kulupi/services/auth_service.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/models/profile.dart';

class ModernUserProfileTab extends StatefulWidget {
  const ModernUserProfileTab({super.key});

  @override
  State<ModernUserProfileTab> createState() => _ModernUserProfileTabState();
}

class _ModernUserProfileTabState extends State<ModernUserProfileTab> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  
  Profile? _profile;
  bool _isLoading = false;
  String? _universityName;
  String? _facultyName;
  String? _departmentName;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getCurrentProfile();
      String? universityName;
      String? facultyName;
      String? departmentName;
      if (profile?.universityId != null) {
        universityName = await _dbService.getUniversityName(profile!.universityId!);
      }
      if (profile?.facultyId != null) {
        facultyName = await _dbService.getFacultyName(profile!.facultyId!);
      }
      if (profile?.departmentId != null) {
        departmentName = await _dbService.getDepartmentName(profile!.departmentId!);
      }
      if (mounted) {
        setState(() {
          _profile = profile;
          _universityName = universityName;
          _facultyName = facultyName;
          _departmentName = departmentName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil yüklenemedi: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPasswordChangeDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final Color onSurface = Theme.of(context).colorScheme.onSurface;
        final Color muted = onSurface.withValues(alpha: 0.7);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: AuraGlassCard(
            padding: const EdgeInsets.all(24),
            accentColor: AuraTheme.kAccentCyan,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: AuraTheme.kAccentCyan, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "Şifre Değiştir",
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text("Mevcut Şifre", style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                AuraGlassTextField(
                  controller: currentPasswordController,
                  hintText: "Mevcut şifrenizi girin",
                  obscureText: true,
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 16),

                Text("Yeni Şifre", style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                AuraGlassTextField(
                  controller: newPasswordController,
                  hintText: "Yeni şifrenizi girin",
                  obscureText: true,
                  icon: Icons.lock_rounded,
                ),
                const SizedBox(height: 16),

                Text("Yeni Şifre (Tekrar)", style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                AuraGlassTextField(
                  controller: confirmPasswordController,
                  hintText: "Yeni şifrenizi tekrar girin",
                  obscureText: true,
                  icon: Icons.lock_reset_rounded,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("İptal", style: TextStyle(color: muted)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Şifreler uyuşmuyor")),
                        );
                        return;
                      }
                      
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Şifre en az 6 karakter olmalı")),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      await _changePassword(
                        currentPasswordController.text,
                        newPasswordController.text,
                      );
                    },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuraTheme.kAccentCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Şifreyi Değiştir", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      setState(() => _isLoading = true);
      
      // Mevcut şifre ile giriş yaparak doğrulama
      await _authService.signIn(
        email: _profile!.email,
        password: currentPassword,
      );

      // Şifreyi güncelle
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Şifreniz başarıyla değiştirildi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Şifre değiştirme hatası: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GirisEkrani()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AuraScaffold(
        auraColor: AuraTheme.kAccentCyan,
        body: Center(child: CircularProgressIndicator(color: AuraTheme.kAccentCyan)),
      );
    }

    if (_profile == null) {
      return AuraScaffold(
        auraColor: AuraTheme.kAccentCyan,
        body: Center(child: Text("Profil yüklenemedi", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    return AuraScaffold(
      auraColor: AuraTheme.kAccentCyan,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PROFILE IDENTITY CARD ---
            AuraGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 32,
              accentColor: AuraTheme.kAccentCyan,
              showGlow: true,
              child: Column(
                children: [
                  // Top Banner with Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AuraTheme.kAccentCyan.withValues(alpha: 0.3),
                              AuraTheme.kAccentCyan.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AuraTheme.kAccentCyan, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AuraTheme.kAccentCyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            child: Text(
                              (_profile?.firstName?.isNotEmpty == true)
                                  ? _profile!.firstName!.substring(0, 1).toUpperCase()
                                  : "U",
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AuraTheme.kAccentCyan,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),
                  // Name & Email
                  Text(
                    "${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}".toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _profile?.email ?? "",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: "Şifre",
                            icon: Icons.lock_rounded,
                            color: AuraTheme.kAccentCyan,
                            onTap: _showPasswordChangeDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: "Çıkış",
                            icon: Icons.logout_rounded,
                            color: Colors.redAccent,
                            onTap: _logout,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- ACADEMIC INFO ---
            _buildSectionHeader("Akademik Bilgiler"),
            const SizedBox(height: 16),
            AuraGlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                children: [
                  _buildDetailRow("Üniversite", _universityName ?? "Belirtilmemiş", Icons.school_rounded),
                  _buildDivider(),
                  _buildDetailRow("Fakülte", _facultyName ?? "Belirtilmemiş", Icons.account_balance_rounded),
                  _buildDivider(),
                  _buildDetailRow("Bölüm", _departmentName ?? "Belirtilmemiş", Icons.book_rounded),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- PERSONAL INFO ---
            _buildSectionHeader("Kişisel Bilgiler"),
            const SizedBox(height: 16),
            AuraGlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 24,
              child: Column(
                children: [
                  _buildDetailRow("Doğum Tarihi", _formatDate(_profile?.birthDate), Icons.cake_rounded),
                  _buildDivider(),
                  _buildDetailRow("İletişim", _profile?.personalEmail ?? "Belirtilmemiş", Icons.alternate_email_rounded),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- APP SETTINGS ---
            _buildSectionHeader("Uygulama Ayarları"),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final isDark = themeProvider.isDarkMode;
                return AuraGlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Karanlık Mod",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: isDark,
                            activeThumbColor: AuraTheme.kAccentCyan,
                            activeTrackColor: AuraTheme.kAccentCyan.withValues(alpha: 0.5),
                            onChanged: (value) {
                              themeProvider.toggleTheme(value);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: onSurface.withValues(alpha: 0.4), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), height: 1),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Belirtilmemiş";
    return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
  }
}
