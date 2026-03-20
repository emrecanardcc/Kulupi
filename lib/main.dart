import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kulupi/login.dart'; 
import 'package:kulupi/main_hub.dart';
import 'package:kulupi/web_admin/web_admin_dashboard.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'utils/modern_theme.dart';
import 'utils/theme_provider.dart';

const String supabaseUrl = 'https://kalkeswsmpjlodhwxcfy.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImthbGtlc3dzbXBqbG9kaHd4Y2Z5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4NDIxNzksImV4cCI6MjA4NjQxODE3OX0.RwbhRHTr612tCY16fzgvA0bQ3RWjHCSWukC_GVfMoRo';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint("Supabase başarıyla başlatıldı.");
  } catch (e) {
    debugPrint("Supabase başlatma hatası: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kulüpi',
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('tr', 'TR'),
          themeMode: themeProvider.themeMode,
          theme: ModernTheme.lightTheme,
          darkTheme: ModernTheme.darkTheme,
          // EĞER WEB İSE DİREKT ADMİN PANELİNE GİT, MOBİL İSE ÖNCE BAKIM KONTROLÜ YAP
          home: kIsWeb ? const WebAdminDashboard() : const MaintenanceWrapper(),
        );
      },
    );
  }
}

// --------------------------------------------------------------------------
// YENİ EKLENDİ: BAKIM MODU KONTROLCÜSÜ (Canlı Veri Dinler)
// --------------------------------------------------------------------------
class MaintenanceWrapper extends StatelessWidget {
  const MaintenanceWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Veritabanındaki app_config tablosunu canlı olarak dinler
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('app_config').stream(primaryKey: ['id']).eq('id', 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F2027),
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }

        final data = snapshot.data;
        bool isMaintenance = false;
        
        // Veritabanından gelen maintenance_mode değerini al
        if (data != null && data.isNotEmpty) {
          isMaintenance = data.first['maintenance_mode'] ?? false;
        }

        // Eğer bakım modundaysa, şık bakım ekranını göster
        if (isMaintenance) {
          return const MaintenanceScreen();
        }

        // Bakım modu KAPALIYSA normal uygulamanın akışına (Giriş veya Ana Sayfa) devam et
        return const AuthWrapper();
      },
    );
  }
}

// --------------------------------------------------------------------------
// YENİ EKLENDİ: BAKIMDAYIZ EKRANI TASARIMI
// --------------------------------------------------------------------------
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027), // Aura Glass konseptine uygun derin renk
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon ve Glow Efekti
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.handyman_rounded, // Bakım ikonu
                  size: 80,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "SİSTEM BAKIMDA",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Kulüpi'yi senin için daha iyi ve hızlı hale getiriyoruz.\nLütfen kısa bir süre sonra tekrar dene.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.cyanAccent,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// MEVCUT KOD: KULLANICI GİRİŞ KONTROLCÜSÜ
// --------------------------------------------------------------------------
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F2027),
            body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const MainHub();
        } else {
          return const GirisEkrani();
        }
      },
    );
  }
}