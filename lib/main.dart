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
// Yeni Projenin DOĞRU Anon Key'i
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
          home: kIsWeb ? const WebAdminDashboard() : const AuthWrapper(),
        );
      },
    );
  }
}

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