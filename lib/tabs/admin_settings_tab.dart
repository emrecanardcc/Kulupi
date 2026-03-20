import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/utils/hex_color.dart';
import 'package:kulupi/utils/glass_components.dart';

class AdminSettingsTab extends StatefulWidget {
  final String kulupId;
  final Color primaryColor;
  final String? currentUserRole; // YENİ EKLENDİ
  final bool isSuperAdmin;       // YENİ EKLENDİ

  const AdminSettingsTab({
    super.key,
    required this.kulupId,
    required this.primaryColor,
    this.currentUserRole,        // YENİ EKLENDİ
    this.isSuperAdmin = false,   // YENİ EKLENDİ
  });

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _clubNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _clubDescController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();

  Color _pickerColor = Colors.cyan;
  Color _currentColor = Colors.cyan;
  String? _logoPath;
  String? _bannerPath;
  Uint8List? _logoBytes;
  Uint8List? _bannerBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClubSettings();
  }

  void _loadClubSettings() async {
    try {
      final data = await Supabase.instance.client
          .from('clubs')
          .select()
          .eq('id', widget.kulupId)
          .single();
      if (mounted) {
        setState(() {
          _clubNameController.text = data['name'] ?? '';
          _shortNameController.text = data['short_name'] ?? '';
          _categoryController.text = data['category'] ?? '';
          _clubDescController.text = data['description'] ?? '';
          _logoPath = data['logo_path'];
          _bannerPath = data['banner_path'];
          if (data['main_color'] != null) {
            _currentColor = hexToColor(data['main_color']);
            _pickerColor = _currentColor;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kulüp ayarları yüklenemedi: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickLogo() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final bytes = await result.readAsBytes();
      if (mounted) {
        setState(() {
          _logoBytes = bytes;
        });
      }
    }
  }

  Future<void> _pickBanner() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      final bytes = await result.readAsBytes();
      if (mounted) {
        setState(() {
          _bannerBytes = bytes;
        });
      }
    }
  }

  Future<String?> _uploadImage(Uint8List bytes, String folder) async {
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
    final path = "$folder/$fileName";
    await Supabase.instance.client.storage.from('clubs').uploadBinary(path, bytes);
    return path;
  }

  // BURASI DEĞİŞTİ: SUPER ADMIN KONTROLÜ EKLENDİ
  Future<bool> _ensurePresident() async {
    // Eğer Super Admin isen (Web'den giriyorsan) veritabanına sormadan direkt TRUE dön (İzin ver)
    if (widget.isSuperAdmin) {
      return true;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      final data = await Supabase.instance.client
          .from('club_members')
          .select('role')
          .eq('club_id', widget.kulupId)
          .eq('user_id', user.id)
          .limit(1)
          .single();
      return data['role'] == 'baskan';
    } catch (_) {
      return false;
    }
  }

  bool _validateForm() {
    final name = _clubNameController.text.trim();
    final shortName = _shortNameController.text.trim();
    final category = _categoryController.text.trim();
    final desc = _clubDescController.text.trim();

    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kulüp adı en az 3 karakter olmalı"), backgroundColor: Colors.orange),
      );
      return false;
    }
    if (shortName.isEmpty || shortName.length < 2 || shortName.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kısaltma 2-8 karakter olmalı"), backgroundColor: Colors.orange),
      );
      return false;
    }
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kategori boş olamaz"), backgroundColor: Colors.orange),
      );
      return false;
    }
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Açıklama boş olamaz"), backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final isPresident = await _ensurePresident();
      if (!isPresident) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Yalnızca kulüp başkanı ayarları değiştirebilir"), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }
      if (!_validateForm()) {
        return;
      }
      String? logoPath = _logoPath;
      String? bannerPath = _bannerPath;
      if (_logoBytes != null) {
        logoPath = await _uploadImage(_logoBytes!, 'logos');
      }
      if (_bannerBytes != null) {
        bannerPath = await _uploadImage(_bannerBytes!, 'banners');
      }

      await Supabase.instance.client
          .from('clubs')
          .update({
            'name': _clubNameController.text.trim(),
            'short_name': _shortNameController.text.trim().toUpperCase(),
            'category': _categoryController.text.trim(),
            'description': _clubDescController.text.trim(),
            'main_color': _colorToHex(_currentColor),
            'logo_path': logoPath,
            'banner_path': bannerPath,
          })
          .eq('id', widget.kulupId);

      if (mounted) {
        setState(() {
          _logoPath = logoPath;
          _bannerPath = bannerPath;
          _logoBytes = null;
          _bannerBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ayarlar güncellendi!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }

  void _showColorPickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AuraGlassCard(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        borderRadius: 32,
        accentColor: _pickerColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "TEMA RENGİ SEÇ",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            ColorPicker(
              pickerColor: _pickerColor,
              onColorChanged: (color) => setState(() => _pickerColor = color),
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaHeightPercent: 0.5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentColor = _pickerColor);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pickerColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "RENGİ UYGULA",
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = _dbService.getPublicUrl('clubs', _logoPath);
    final bannerUrl = _dbService.getPublicUrl('clubs', _bannerPath);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color onSurface = colorScheme.onSurface;
    final Color muted = onSurface.withValues(alpha: 0.6);
    final Color subtle = onSurface.withValues(alpha: 0.4);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Kulüp Kimliği", true),
          const SizedBox(height: 16),
          AuraGlassCard(
            accentColor: widget.primaryColor,
            child: Column(
              children: [
                AuraGlassTextField(
                  controller: _clubNameController,
                  hintText: "Kulüp Adı",
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AuraGlassTextField(
                        controller: _shortNameController,
                        hintText: "Kısaltma",
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AuraGlassTextField(
                        controller: _categoryController,
                        hintText: "Kategori",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AuraGlassTextField(
                  controller: _clubDescController,
                  hintText: "Açıklama",
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("Görsel Kimlik", false),
          const SizedBox(height: 16),
          AuraGlassCard(
            accentColor: widget.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "KULÜP LOGOSU",
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface.withValues(alpha: 0.9),
                        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                        image: _logoBytes != null
                            ? DecorationImage(image: MemoryImage(_logoBytes!), fit: BoxFit.cover)
                            : (logoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover) : null),
                      ),
                      child: logoUrl.isEmpty && _logoBytes == null
                          ? Icon(Icons.add_photo_alternate_rounded, color: onSurface.withValues(alpha: 0.3), size: 32)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text("LOGO SEÇ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
                          foregroundColor: onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "KULÜP BANNER",
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    border: Border.all(color: onSurface.withValues(alpha: 0.12)),
                    image: _bannerBytes != null
                        ? DecorationImage(image: MemoryImage(_bannerBytes!), fit: BoxFit.cover)
                        : (bannerUrl.isNotEmpty
                            ? DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover)
                            : null),
                  ),
                  child: bannerUrl.isEmpty && _bannerBytes == null
                      ? Center(child: Icon(Icons.landscape_rounded, color: onSurface.withValues(alpha: 0.3), size: 48))
                      : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickBanner,
                    icon: const Icon(Icons.image_search_rounded, size: 18),
                    label: const Text("BANNER SEÇ"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
                      foregroundColor: onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: onSurface.withValues(alpha: 0.12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: onSurface.withValues(alpha: 0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TEMA RENGİ",
                            style: TextStyle(
                              color: onSurface,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _colorToHex(_currentColor),
                            style: TextStyle(
                              color: subtle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showColorPickerDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("DEĞİŞTİR"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isSaving ? "KAYDEDİLİYOR..." : "AYARLARI KAYDET",
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 60),
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
}