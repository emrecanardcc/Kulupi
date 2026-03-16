import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/glass_components.dart';

class SystemSettingsPanel extends StatefulWidget {
  const SystemSettingsPanel({super.key});

  @override
  State<SystemSettingsPanel> createState() => _SystemSettingsPanelState();
}

class _SystemSettingsPanelState extends State<SystemSettingsPanel> {
  final _formKey = GlobalKey<FormState>();
  
  // Auth Settings
  final _maxLoginAttemptsController = TextEditingController();
  final _sessionTimeoutController = TextEditingController();
  final _emailConfirmationExpiryController = TextEditingController();
  
  // Storage Settings
  final _maxFileSizeController = TextEditingController();
  final _allowedFileTypesController = TextEditingController();
  
  // App Settings
  final _appNameController = TextEditingController();
  final _appDescriptionController = TextEditingController();
  
  bool _maintenanceMode = false;
  bool _emailVerificationRequired = true;
  bool _allowRegistration = true;
  
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _maxLoginAttemptsController.dispose();
    _sessionTimeoutController.dispose();
    _emailConfirmationExpiryController.dispose();
    _maxFileSizeController.dispose();
    _allowedFileTypesController.dispose();
    _appNameController.dispose();
    _appDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // Load current settings from app_config table
      final response = await Supabase.instance.client
          .from('app_config')
          .select()
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _maxLoginAttemptsController.text = response['max_login_attempts']?.toString() ?? '5';
          _sessionTimeoutController.text = response['session_timeout_minutes']?.toString() ?? '60';
          _emailConfirmationExpiryController.text = response['email_confirmation_expiry_hours']?.toString() ?? '24';
          _maxFileSizeController.text = response['max_file_size_mb']?.toString() ?? '10';
          _allowedFileTypesController.text = response['allowed_file_types'] ?? 'jpg,jpeg,png,pdf,doc,docx';
          _appNameController.text = response['app_name'] ?? 'Kulüpi';
          _appDescriptionController.text = response['app_description'] ?? 'Üniversite öğrencileri için sosyal platform';
          _maintenanceMode = response['maintenance_mode'] ?? false;
          _emailVerificationRequired = response['email_verification_required'] ?? true;
          _allowRegistration = response['allow_registration'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ayarlar yüklenirken hata: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final settings = {
        'max_login_attempts': int.tryParse(_maxLoginAttemptsController.text) ?? 5,
        'session_timeout_minutes': int.tryParse(_sessionTimeoutController.text) ?? 60,
        'email_confirmation_expiry_hours': int.tryParse(_emailConfirmationExpiryController.text) ?? 24,
        'max_file_size_mb': int.tryParse(_maxFileSizeController.text) ?? 10,
        'allowed_file_types': _allowedFileTypesController.text,
        'app_name': _appNameController.text,
        'app_description': _appDescriptionController.text,
        'maintenance_mode': _maintenanceMode,
        'email_verification_required': _emailVerificationRequired,
        'allow_registration': _allowRegistration,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('app_config')
          .upsert(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ayarlar kaydedilirken hata: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      // Clear Supabase cache
      await Supabase.instance.client.rpc('clear_cache', params: {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önbellek temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Önbellek temizlenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _backupDatabase() async {
    try {
      // Trigger database backup
      await Supabase.instance.client.rpc('create_backup', params: {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veritabanı yedekleme başlatıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme başlatılırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        AuraGlassTextField(
          controller: controller,
          hintText: label,
          keyboardType: keyboardType ?? TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.cyanAccent,
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem Ayarları',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Uygulama Ayarları
              AuraGlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uygulama Ayarları',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Uygulama Adı', _appNameController),
                    const SizedBox(height: 16),
                    _buildTextField('Uygulama Açıklaması', _appDescriptionController),
                    const SizedBox(height: 16),
                    _buildCheckbox('Bakım Modu', _maintenanceMode, (value) => setState(() => _maintenanceMode = value ?? false)),
                    _buildCheckbox('Email Doğrulama Gerekli', _emailVerificationRequired, (value) => setState(() => _emailVerificationRequired = value ?? true)),
                    _buildCheckbox('Kayıt İzin Ver', _allowRegistration, (value) => setState(() => _allowRegistration = value ?? true)),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Güvenlik Ayarları
              AuraGlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Güvenlik Ayarları',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Maksimum Giriş Denemesi', _maxLoginAttemptsController, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Oturum Süresi (Dakika)', _sessionTimeoutController, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Email Onay Süresi (Saat)', _emailConfirmationExpiryController, keyboardType: TextInputType.number),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Dosya Yükleme Ayarları
              AuraGlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dosya Yükleme Ayarları',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Maksimum Dosya Boyutu (MB)', _maxFileSizeController, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('İzin Verilen Dosya Türleri (virgülle ayırın)', _allowedFileTypesController),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bakım İşlemleri
              AuraGlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bakım İşlemleri',
                      style: TextStyle(fontSize: 20, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _clearCache,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Önbelleği Temizle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _backupDatabase,
                          icon: const Icon(Icons.backup),
                          label: const Text('Veritabanını Yedekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Kaydet Butonu
              Center(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _saveSettings,
                  icon: _loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_loading ? 'Kaydediliyor...' : 'Ayarları Kaydet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}