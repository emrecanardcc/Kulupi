import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kulupi/utils/glass_components.dart';

// MOBİLDEKİ ADMİN PANELİ VE RENK DÖNÜŞTÜRÜCÜYÜ İÇERİ AKTARIYORUZ
import 'package:kulupi/admin_panel.dart';
import 'package:kulupi/utils/hex_color.dart';

// ==========================================
// 1. KULÜP YÖNETİMİ (CLUB MANAGEMENT)
// ==========================================
class ClubManagementView extends StatefulWidget {
  const ClubManagementView({super.key});

  @override
  State<ClubManagementView> createState() => _ClubManagementViewState();
}

class _ClubManagementViewState extends State<ClubManagementView> {
  bool _showCreator = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showCreator ? "Yeni Kulüp Ekle" : "Kulüp Yönetimi",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showCreator = !_showCreator),
                icon: Icon(_showCreator ? Icons.list : Icons.add),
                label: Text(_showCreator ? "Listeye Dön" : "Yeni Kulüp Ekle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _showCreator ? const ClubCreator() : const AllClubsManager(),
        ),
      ],
    );
  }
}

// --- KULÜP LİSTESİ (ARAMA VE FİLTRELEME EKLENDİ) ---
class AllClubsManager extends StatefulWidget {
  const AllClubsManager({super.key});

  @override
  State<AllClubsManager> createState() => _AllClubsManagerState();
}

class _AllClubsManagerState extends State<AllClubsManager> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('clubs').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
          }
          
          final allClubs = snapshot.data ?? [];
          
          if (allClubs.isEmpty) {
            return const Center(child: Text("Henüz kulüp bulunmamaktadır.", style: TextStyle(color: Colors.white70)));
          }

          // Veritabanındaki mevcut kategorileri dinamik olarak bul
          final categories = {'Tümü'};
          for (var club in allClubs) {
            if (club['category'] != null && club['category'].toString().trim().isNotEmpty) {
              categories.add(club['category'].toString().trim());
            }
          }
          final categoryList = categories.toList()..sort();

          // Arama ve Filtrelemeyi uygula
          final filteredClubs = allClubs.where((club) {
            final name = (club['name'] ?? '').toString().toLowerCase();
            final shortName = (club['short_name'] ?? '').toString().toLowerCase();
            final category = (club['category'] ?? '').toString().trim();
            
            // Arama filtresi
            final matchesSearch = _searchQuery.isEmpty || 
                name.contains(_searchQuery.toLowerCase()) || 
                shortName.contains(_searchQuery.toLowerCase());
                
            // Kategori filtresi
            final matchesCategory = _selectedCategory == 'Tümü' || category == _selectedCategory;
            
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // --- ARAMA VE KATEGORİ ÇUBUĞU ---
              AuraGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Kulüp Ara (İsim veya Kısa Ad)...',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categoryList.contains(_selectedCategory) ? _selectedCategory : 'Tümü',
                          dropdownColor: const Color(0xFF203A43),
                          icon: const Icon(Icons.filter_list, color: Colors.cyanAccent),
                          style: const TextStyle(color: Colors.white),
                          isExpanded: true,
                          items: categoryList.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue ?? 'Tümü';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- FİLTRELENMİŞ KULÜP LİSTESİ ---
              Expanded(
                child: filteredClubs.isEmpty 
                  ? const Center(child: Text("Arama kriterlerine uygun kulüp bulunamadı.", style: TextStyle(color: Colors.white70)))
                  : AuraGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: ListView.separated(
                        itemCount: filteredClubs.length,
                        separatorBuilder: (c, i) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                        itemBuilder: (context, index) {
                          final club = filteredClubs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                              backgroundImage: club['logo_path'] != null 
                                  ? NetworkImage(Supabase.instance.client.storage.from('clubs').getPublicUrl(club['logo_path']))
                                  : null,
                              child: club['logo_path'] == null 
                                  ? Text((club['short_name'] ?? 'K').toString().substring(0,1), style: const TextStyle(color: Colors.cyanAccent)) 
                                  : null,
                            ),
                            title: Text(club['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(club['category'] ?? '', style: const TextStyle(color: Colors.white70)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // KULÜBÜ YÖNET BUTONU
                                IconButton(
                                  tooltip: "Kulübü Yönet (Mobil Arayüz)",
                                  icon: const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminPanel(
                                          kulupId: club['id'].toString(), 
                                          kulupismi: club['name'] ?? 'Bilinmeyen Kulüp',
                                          primaryColor: hexToColor(club['main_color'] ?? '#00FBFF'), 
                                          currentUserRole: 'baskan', 
                                          isSuperAdmin: true, 
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                // SİL BUTONU
                                IconButton(
                                  tooltip: "Kulübü Sil",
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    bool confirm = await showDialog(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: const Color(0xFF203A43),
                                        title: const Text("Sil", style: TextStyle(color: Colors.white)),
                                        content: Text("${club['name']} kulübünü silmek istediğinize emin misiniz?", style: const TextStyle(color: Colors.white70)),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("İptal", style: TextStyle(color: Colors.white70))),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil", style: TextStyle(color: Colors.redAccent))),
                                        ]
                                      )
                                    ) ?? false;

                                    if (confirm) {
                                      try {
                                        await Supabase.instance.client.from('clubs').delete().eq('id', club['id']);
                                        if(context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kulüp silindi.")));
                                        }
                                      } catch(e) {
                                        if(context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
                                        }
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
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- YENİ KULÜP OLUŞTURMA FORMU ---
class ClubCreator extends StatefulWidget {
  const ClubCreator({super.key});
  @override
  State<ClubCreator> createState() => _ClubCreatorState();
}

class _ClubCreatorState extends State<ClubCreator> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _colorController = TextEditingController(text: "#00FBFF");
  
  int? _selectedUniversityId;
  bool _isSaving = false;

  Future<void> _saveClub() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUniversityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir üniversite seçin.")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('clubs').insert({
        'university_id': _selectedUniversityId,
        'name': _nameController.text.trim(),
        'short_name': _shortNameController.text.trim(),
        'description': _descController.text.trim(),
        'category': _categoryController.text.trim(),
        'main_color': _colorController.text.trim(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kulüp başarıyla oluşturuldu!")));
        _nameController.clear();
        _shortNameController.clear();
        _descController.clear();
        _categoryController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AuraGlassCard(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: Supabase.instance.client.from('universities').select('id, name'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.cyanAccent);
                    final unis = snapshot.data!;
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: "Üniversite",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                      ),
                      dropdownColor: const Color(0xFF203A43),
                      style: const TextStyle(color: Colors.white),
                      initialValue: _selectedUniversityId,
                      items: unis.map((u) => DropdownMenuItem<int>(
                        value: u['id'],
                        child: Text(u['name'], style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedUniversityId = val),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Kulüp Tam Adı", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                  validator: (val) => val == null || val.isEmpty ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shortNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Kısa Adı (Örn: YAZKUL)", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                  validator: (val) => val == null || val.isEmpty ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Kategori (Mühendislik, Sanat vb.)", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                  validator: (val) => val == null || val.isEmpty ? "Zorunlu alan" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Açıklama", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Ana Renk (Hex Code: #00FBFF)", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _isSaving ? null : _saveClub,
                    child: _isSaving ? const CircularProgressIndicator(color: Colors.black) : const Text("Kulübü Oluştur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. SPONSOR YÖNETİCİSİ (SPONSOR MANAGER)
// ==========================================
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
      if (file.bytes == null) throw Exception("Dosya içeriği boş.");
      
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      final path = "$folder/$fileName";
      
      if (!file.name.toLowerCase().endsWith('.jpg') && 
          !file.name.toLowerCase().endsWith('.jpeg') && 
          !file.name.toLowerCase().endsWith('.png') && 
          !file.name.toLowerCase().endsWith('.gif')) {
        throw Exception("Sadece JPG, PNG ve GIF dosyaları yükleyebilirsiniz.");
      }
      
      if (file.bytes!.length > 5 * 1024 * 1024) {
        throw Exception("Dosya boyutu 5MB'den küçük olmalıdır.");
      }
      
      await Supabase.instance.client.storage.from('sponsors').uploadBinary(path, file.bytes!);
      return path;
    } catch (e) {
      throw Exception("Dosya yüklenirken bir hata oluştu: $e");
    }
  }

  Future<void> _addSponsor() async {
    if (_nameController.text.isEmpty || _logoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen en az bir isim ve logo seçiniz.")));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? logoPath;
      String? bannerPath;

      if (_logoFile != null) logoPath = await _uploadFile(_logoFile!, 'logos');
      if (_bannerFile != null) bannerPath = await _uploadFile(_bannerFile!, 'banners');

      await Supabase.instance.client.from('app_sponsors').insert({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'logo_path': logoPath,
        'banner_path': bannerPath,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      _nameController.clear();
      _descController.clear();
      setState(() {
        _logoFile = null;
        _bannerFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sponsor başarıyla eklendi!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- YENİ EKLENEN: SİLME ONAY PENCERESİ ---
  void _confirmDelete(BuildContext context, Map<String, dynamic> sponsor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Sponsoru Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("${sponsor['name']} adlı sponsoru silmek istediğinize emin misiniz? Bu işlem geri alınamaz.", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('app_sponsors').delete().eq('id', sponsor['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sponsor başarıyla silindi."), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silinemedi: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }

  // --- YENİ EKLENEN: DÜZENLEME PENCERESİ ---
  void _showEditDialog(BuildContext context, Map<String, dynamic> sponsor) {
    final editNameCtrl = TextEditingController(text: sponsor['name']);
    final editDescCtrl = TextEditingController(text: sponsor['description']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Sponsoru Düzenle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Sponsor Adı", labelStyle: TextStyle(color: Colors.cyanAccent), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editDescCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Açıklama", labelStyle: TextStyle(color: Colors.cyanAccent), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('app_sponsors').update({
                  'name': editNameCtrl.text.trim(),
                  'description': editDescCtrl.text.trim(),
                }).eq('id', sponsor['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sponsor başarıyla güncellendi."), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Güncellenemedi: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
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
                      const Text("Yeni Sponsor Ekle", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Sponsor Adı", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: "Açıklama", labelStyle: TextStyle(color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent))),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client.from('app_sponsors').stream(primaryKey: ['id']).order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Sponsorlar yüklenemedi:\n${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
                    }
                    
                    final sponsors = snapshot.data ?? [];
                    if (sponsors.isEmpty) {
                      return const Center(child: Text("Henüz sponsor eklenmemiş.", style: TextStyle(color: Colors.white70)));
                    }

                    return AuraGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          const Text("Mevcut Sponsorlar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 600), 
                            child: ListView.separated(
                              shrinkWrap: true, 
                              itemCount: sponsors.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                              itemBuilder: (context, index) {
                                final sponsor = sponsors[index];
                                return ListTile(
                                  leading: sponsor['logo_path'] != null
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(Supabase.instance.client.storage.from('sponsors').getPublicUrl(sponsor['logo_path'])),
                                          radius: 20,
                                        )
                                      : const CircleAvatar(backgroundColor: Colors.cyanAccent, radius: 20, child: Icon(Icons.business, color: Colors.black)),
                                  title: Text(sponsor['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(sponsor['description'] ?? "", style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: sponsor['is_active'] == true ? "Sponsor Aktif (Uygulamada Görünüyor)" : "Sponsor Pasif (Gizlendi)",
                                        child: Switch(
                                          value: sponsor['is_active'] ?? false,
                                          onChanged: (value) async {
                                            try {
                                              await Supabase.instance.client.from('app_sponsors').update({'is_active': value}).eq('id', sponsor['id']);
                                            } catch (e) {
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Durum güncellenemedi: $e"), backgroundColor: Colors.red));
                                            }
                                          },
                                          activeColor: Colors.cyanAccent,
                                        ),
                                      ),
                                      // YENİ: DÜZENLE BUTONU
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.amberAccent),
                                        onPressed: () => _showEditDialog(context, sponsor),
                                        tooltip: "Düzenle",
                                      ),
                                      // GÜNCELLENEN: SİL BUTONU (ONAYLI)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _confirmDelete(context, sponsor),
                                        tooltip: "Sil",
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

// ==========================================
// 3. GLOBAL ETKİNLİK YÖNETİMİ
// ==========================================
class GlobalEventManagement extends StatefulWidget {
  const GlobalEventManagement({super.key});
  @override
  State<GlobalEventManagement> createState() => _GlobalEventManagementState();
}

class _GlobalEventManagementState extends State<GlobalEventManagement> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('events').stream(primaryKey: ['id']).order('start_time', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Etkinlikler yüklenemedi: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(child: Text("Henüz bir etkinlik planlanmamış.", style: TextStyle(color: Colors.white70)));
        }

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tüm Etkinlikler", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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

// --- Yardımcı Widget'lar ---
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