import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/glass_components.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});
  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  String _searchQuery = "";

  // KULLANICI DÜZENLEME PENCERESİ
  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final aboutCtrl = TextEditingController(text: user['about'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? ''); 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Kullanıcıyı Düzenle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Ad Soyad", labelStyle: TextStyle(color: Colors.cyanAccent)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "İletişim E-postası", labelStyle: TextStyle(color: Colors.cyanAccent)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aboutCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Hakkında", labelStyle: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.from('profiles').update({
                  'full_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'about': aboutCtrl.text.trim(),
                }).eq('id', user['id']);
                
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı güncellendi."), backgroundColor: Colors.green));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  // TEK TIKLA ŞİFRE SIFIRLAMA MAİLİ GÖNDERME
  Future<void> _sendPasswordReset(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$email adresine sıfırlama linki gönderildi!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Mail gönderilemedi: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Kullanıcı Destek & Yönetim", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 24),
          
          // ARAMA ÇUBUĞU
          AuraGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Colors.cyanAccent),
                hintText: "İsim veya E-posta ile ara...",
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          const SizedBox(height: 24),

          // KULLANICI LİSTESİ (SADECE PROFİLLER)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('profiles').stream(primaryKey: ['id']).order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }
                
                var users = snapshot.data ?? [];
                
                // Arama Filtresi
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) {
                    final name = (u['full_name'] ?? '').toString().toLowerCase();
                    final email = (u['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) return const Center(child: Text("Kullanıcı bulunamadı.", style: TextStyle(color: Colors.white70)));

                return AuraGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isBanned = user['is_banned'] == true;
                      final isManuallyVerified = user['is_manually_verified'] == true;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBanned ? Colors.redAccent.withValues(alpha: 0.2) : Colors.cyanAccent.withValues(alpha: 0.2),
                          child: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? Colors.redAccent : Colors.cyanAccent),
                        ),
                        title: Text(user['full_name'] ?? 'İsimsiz Kullanıcı', style: TextStyle(color: isBanned ? Colors.white54 : Colors.white, fontWeight: FontWeight.bold, decoration: isBanned ? TextDecoration.lineThrough : null)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email'] ?? 'E-posta yok', style: const TextStyle(color: Colors.white70)),
                            if (isManuallyVerified)
                              const Text("✓ Manuel Onaylı", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. MANUEL ONAY BUTONU
                            Tooltip(
                              message: isManuallyVerified ? "Manuel Onayı Kaldır" : "Manuel Onay Ver (Mail kodunu atlar)",
                              child: IconButton(
                                icon: Icon(isManuallyVerified ? Icons.verified : Icons.verified_outlined, color: isManuallyVerified ? Colors.greenAccent : Colors.white38),
                                onPressed: () async {
                                  await Supabase.instance.client.from('profiles').update({'is_manually_verified': !isManuallyVerified}).eq('id', user['id']);
                                },
                              ),
                            ),
                            // 2. ŞİFRE SIFIRLAMA BUTONU
                            Tooltip(
                              message: "Şifre Sıfırlama Maili Gönder",
                              child: IconButton(
                                icon: const Icon(Icons.lock_reset, color: Colors.orangeAccent),
                                onPressed: () => _sendPasswordReset(user['email']),
                              ),
                            ),
                            // 3. DÜZENLE BUTONU
                            Tooltip(
                              message: "Profili Düzenle",
                              child: IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.cyanAccent),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                            ),
                            // 4. HESABI ASKIYA AL (BANLA) BUTONU
                            Tooltip(
                              message: isBanned ? "Banı Kaldır" : "Hesabı Askıya Al",
                              child: IconButton(
                                icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: Colors.redAccent),
                                onPressed: () async {
                                  await Supabase.instance.client.from('profiles').update({'is_banned': !isBanned}).eq('id', user['id']);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}