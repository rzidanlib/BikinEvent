import 'package:bikinevent/pages/organizer/organizer_dashboard_page.dart';
import 'package:bikinevent/pages/organizer/organizer_shell.dart';
import 'package:bikinevent/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/auth/login_page.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // Inisialisasi koneksi ke Supabase
  await Supabase.initialize(
    url: 'https://lansqkdazqluzsvqsiup.supabase.co',
    publishableKey: 'sb_publishable_96fg09Mf1BNlciQGZFO3yw_P4EMtiJZ',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticketing Event App',
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        // Session ada -> lanjut cek role sebelum menentukan halaman
        return const RoleBasedRouter();
      },
    );
  }
}

/// Widget ini mengambil data profile user yang login,
/// lalu mengarahkan ke halaman yang sesuai berdasarkan role.
class RoleBasedRouter extends StatelessWidget {
  const RoleBasedRouter({super.key});

  Future<String?> _getRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();

    return response['role'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          // Gagal ambil profile (misal koneksi bermasalah) -> fallback ke Home
          // supaya user tidak stuck di layar loading kosong
          return const HomePage();
        }

        final role = snapshot.data;
        if (role == 'organizer') {
          return const OrganizerShell();
        }
        return const HomePage();
      },
    );
  }
}
