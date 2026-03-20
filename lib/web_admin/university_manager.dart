import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/utils/glass_components.dart';

class UniversityManager extends StatefulWidget {
  const UniversityManager({super.key});

  @override
  State<UniversityManager> createState() => _UniversityManagerState();
}

class _UniversityManagerState extends State<UniversityManager> {
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _domainController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  int? _editingUniversityId;

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _saveUniversity() async {
    if (_nameController.text.isEmpty || _shortNameController.text.isEmpty || _domainController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final domain = _domainController.text.trim().startsWith('@') 
          ? _domainController.text.trim() 
          : '@${_domainController.text.trim()}';

      if (_isEditing && _editingUniversityId != null) {
        await Supabase.instance.client.from('universities')
            .update({
              'name': _nameController.text.trim(),
              'short_name': _shortNameController.text.trim(),
              'domain': domain,
            })
            .eq('id', _editingUniversityId!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üniversite başarıyla güncellendi!")));
        }
      } else {
        await Supabase.instance.client.from('universities').insert({
          'name': _nameController.text.trim(),
          'short_name': _shortNameController.text.trim(),
          'domain': domain,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üniversite başarıyla eklendi!")));
        }
      }

      _cancelEdit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editUniversity(Map<String, dynamic> university) {
    setState(() {
      _nameController.text = university['name'] ?? '';
      _shortNameController.text = university['short_name'] ?? '';
      _domainController.text = university['domain'] ?? '';
      _isEditing = true;
      _editingUniversityId = university['id'];
    });
  }

  void _cancelEdit() {
    setState(() {
      _nameController.clear();
      _shortNameController.clear();
      _domainController.clear();
      _isEditing = false;
      _editingUniversityId = null;
    });
  }

  Future<void> _deleteUniversity(int id) async {
    try {
      await Supabase.instance.client.from('universities').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Üniversite başarıyla silindi!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silinemedi: Bu üniversiteye bağlı fakülteler olabilir."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> university) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF203A43),
        title: const Text("Üniversite Silme Onayı", style: TextStyle(color: Colors.white)),
        content: Text(
          "'${university['name']}' üniversitesini silmek istediğinize emin misiniz?\n\n"
          "Bu işlem geri alınamaz.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("İptal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteUniversity(university['id']);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Üniversite Yönetimi",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOL PANEL: FORMLAR
                Expanded(
                  flex: 1,
                  child: AuraGlassCard(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isEditing ? "Üniversite Düzenle" : "Üniversite Ekle",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                            ),
                            if (_isEditing)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: _cancelEdit,
                                tooltip: "İptal",
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_nameController, "Üniversite Tam Adı"),
                        const SizedBox(height: 15),
                        _buildTextField(_shortNameController, "Kısa Ad (Örn: İTÜ)"),
                        const SizedBox(height: 15),
                        _buildTextField(_domainController, "E-posta Uzantısı (Örn: @itu.edu.tr)"),
                        const SizedBox(height: 30),
                        
                        if (_isLoading)
                          const CircularProgressIndicator(color: Colors.cyanAccent)
                        else
                          ElevatedButton.icon(
                            onPressed: _saveUniversity,
                            icon: Icon(_isEditing ? Icons.save : Icons.add_business),
                            label: Text(_isEditing ? "Değişiklikleri Kaydet" : "Üniversiteyi Kaydet"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditing ? Colors.orangeAccent : Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                
                // SAĞ PANEL: LİSTE (StreamBuilder ile Canlı)
                Expanded(
                  flex: 2,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('universities')
                        .stream(primaryKey: ['id'])
                        .order('name', ascending: true),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Hata:\n${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
                      }
                      
                      final unis = snapshot.data ?? [];
                      if (unis.isEmpty) {
                        return const Center(child: Text("Henüz üniversite eklenmemiş.", style: TextStyle(color: Colors.white70)));
                      }

                      return AuraGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Mevcut Üniversiteler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.separated(
                                itemCount: unis.length,
                                separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                                itemBuilder: (context, index) {
                                  final uni = unis[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.cyanAccent,
                                      child: Icon(Icons.school, color: Colors.black),
                                    ),
                                    title: Text(uni['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Text("${uni['short_name']} | ${uni['domain']}", style: const TextStyle(color: Colors.white70)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                                          onPressed: () => _editUniversity(uni),
                                          tooltip: "Düzenle",
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _showDeleteConfirmation(uni),
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
          ),
        ],
      ),
    );
  }
}