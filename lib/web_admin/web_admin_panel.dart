import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kulupi/utils/hex_color.dart';
import 'package:kulupi/utils/glass_components.dart';
import 'package:kulupi/services/database_service.dart';
import 'package:kulupi/models/university.dart';
import 'package:kulupi/models/club.dart';
import 'package:kulupi/models/app_enums.dart';
import 'package:kulupi/web_admin/club_admin_dashboard.dart';
import 'package:kulupi/web_admin/academic_manager.dart';
import 'package:kulupi/web_admin/university_manager.dart';

// --- 1. SPONSOR YÖNETİCİSİ ---
class SponsorManager extends StatefulWidget {
  const SponsorManager({super.key});
  @override
  State<SponsorManager> createState() => _SponsorManagerState();
}

class _SponsorManagerState extends State<SponsorManager> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  PlatformFile? _logoFile;
  PlatformFile? _bannerFile;
  bool _isUploading = false;

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _logoFile = result.files.first);
    }
  }

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _bannerFile = result.files.first);
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String folder) async {
    try {
      debugPrint("Dosya yükleniyor: ${file.name}, Boyut: ${file.bytes?.length ?? 0} bytes");
      
      if (file.bytes == null) {
        throw Exception("Dosya içeriği boş.");
      }
      
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      final path = "$folder/$fileName";
      
      // Dosya türünü kontrol et
      if (!file.name.toLowerCase().endsWith('.jpg') && 
          !file.name.toLowerCase().endsWith('.jpeg') && 
          !file.name.toLowerCase().endsWith('.png') && 
          !file.name.toLowerCase().endsWith('.gif')) {
        throw Exception("Sadece JPG, PNG ve GIF dosyaları yükleyebilirsiniz.");
      }
      
      // Dosya boyutu kontrolü (5MB)
      if (file.bytes!.length > 5 * 1024 * 1024) {
        throw Exception("Dosya boyutu 5MB'den küçük olmalıdır.");
      }
      
      debugPrint("Yükleme yolu: $path");
      
      await Supabase.instance.client.storage
          .from('sponsors')
          .uploadBinary(path, file.bytes!);
      
      debugPrint("Dosya başarıyla yüklendi: $path");
      return path;
    } on StorageException catch (e) {
      debugPrint("Storage hatası: ${e.message} - ${e.statusCode}");
      if (e.message.contains('Bucket not found')) {
        throw Exception("Storage bucket bulunamadı. Lütfen Supabase dashboard'dan 'sponsors' bucket'ını oluşturun.");
      } else if (e.message.contains('Unauthorized')) {
        throw Exception("Yükleme yetkiniz yok. Lütfen giriş yaptığınızdan emin olun.");
      } else if (e.message.contains('Payload too large')) {
        throw Exception("Dosya çok büyük. Lütfen 5MB'den küçük bir dosya seçin.");
      }
      rethrow;
    } catch (e) {
      debugPrint("Yükleme hatası ($folder): $e");
      throw Exception("Dosya yüklenirken bir hata oluştu: $e");
    }
  }

  Future<void> _addSponsor() async {
    if (_nameController.text.isEmpty || _logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen en az bir isim ve logo seçiniz.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? logoPath;
      String? bannerPath;

      // Logo yükle
      if (_logoFile != null) {
        logoPath = await _uploadFile(_logoFile!, 'sponsors/logos');
      }

      // Banner yükle
      if (_bannerFile != null) {
        bannerPath = await _uploadFile(_bannerFile!, 'sponsors/banners');
      }

      // Sponsor verisini veritabanına ekle
      await Supabase.instance.client.from('app_sponsors').insert({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'logo_path': logoPath,
        'banner_path': bannerPath,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Formu temizle
      _nameController.clear();
      _descController.clear();
      setState(() {
        _logoFile = null;
        _bannerFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sponsor başarıyla eklendi!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sponsor Yönetimi",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: AuraGlassCard(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Yeni Sponsor Ekle",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Sponsor Adı",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Açıklama",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFilePicker("Logo", _logoFile, _pickLogo),
                      const SizedBox(height: 15),
                      _buildFilePicker("Banner (Opsiyonel)", _bannerFile, _pickBanner),
                      const SizedBox(height: 30),
                      if (_isUploading)
                        const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                      else
                        ElevatedButton.icon(
                          onPressed: _addSponsor,
                          icon: const Icon(Icons.add_business),
                          label: const Text("Sponsor Ekle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client
                      .from('app_sponsors')
                      .select('*')
                      .order('created_at', ascending: false)
                      .limit(50),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              "Sponsorlar yüklenemedi:\n${snapshot.error}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () => setState(() {}),
                              child: const Text("Tekrar Dene", style: TextStyle(color: Colors.cyanAccent)),
                            )
                          ],
                        ),
                      );
                    }
                    
                    final sponsors = snapshot.data ?? [];
                    
                    if (sponsors.isEmpty) {
                      return const Center(
                        child: Text(
                          "Henüz sponsor eklenmemiş.",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return AuraGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Mevcut Sponsorlar",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.separated(
                              itemCount: sponsors.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                              itemBuilder: (context, index) {
                                final sponsor = sponsors[index];
                                return ListTile(
                                  leading: sponsor['logo_path'] != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            Supabase.instance.client.storage
                                                .from('sponsors')
                                                .getPublicUrl(sponsor['logo_path']),
                                          ),
                                          radius: 20,
                                        )
                                      : const CircleAvatar(
                                          backgroundColor: Colors.cyanAccent,
                                          child: Icon(Icons.business, color: Colors.black),
                                          radius: 20,
                                        ),
                                  title: Text(sponsor['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(sponsor['description'] ?? "", style: const TextStyle(color: Colors.white70)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: sponsor['is_active'] ?? false,
                                        onChanged: (value) async {
                                          try {
                                            await Supabase.instance.client
                                                .from('app_sponsors')
                                                .update({'is_active': value})
                                                .eq('id', sponsor['id']);
                                            if (mounted) setState(() {});
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Durum güncellenemedi: $e"), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                        activeColor: Colors.cyanAccent,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () async {
                                          try {
                                            await Supabase.instance.client
                                                .from('app_sponsors')
                                                .delete()
                                                .eq('id', sponsor['id']);
                                            if (mounted) setState(() {});
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text("Silinemedi: $e"), backgroundColor: Colors.red),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 2. GLOBAL ETKİNLİK YÖNETİMİ ---
class GlobalEventManagement extends StatefulWidget {
  const GlobalEventManagement({super.key});
  @override
  State<GlobalEventManagement> createState() => _GlobalEventManagementState();
}

class _GlobalEventManagementState extends State<GlobalEventManagement> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('events')
          .select('*')
          .order('start_time', ascending: false)
          .limit(100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Etkinlikler yüklenemedi: ${snapshot.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];
        
        if (events.isEmpty) {
          return const Center(
            child: Text(
              "Henüz bir etkinlik planlanmamış.",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tüm Etkinlikler",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AuraGlassCard(
                  child: ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final eventData = events[index];
                      return ListTile(
                        leading: const Icon(Icons.event, color: Colors.cyanAccent),
                        title: Text(eventData['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${eventData['location']} - ${DateTime.parse(eventData['start_time']).toString().substring(0, 16)}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await Supabase.instance.client.from('events').delete().eq('id', eventData['id']);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Shared Helpers ---
Widget _buildFilePicker(String label, PlatformFile? file, VoidCallback onPick) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 5),
      InkWell(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Icon(file == null ? Icons.image_outlined : Icons.check_circle, 
                   color: file == null ? Colors.white54 : Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file?.name ?? "Dosya Seç...",
                  style: TextStyle(color: file == null ? Colors.white38 : Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}