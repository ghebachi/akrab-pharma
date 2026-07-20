import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_colors.dart';
import 'providers/pharmacy_provider.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'services/settings_service.dart';
import 'views/admin_dashboard_screen.dart';
import 'views/home_screen.dart';
import 'views/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load .env file (graceful: skip if missing on Vercel)
  try {
    await dotenv.load();
  } catch (_) {
    if (kDebugMode) print('.env not found, falling back to --dart-define');
  }

  // Support both .env (local) and --dart-define (Vercel)
  final supabaseUrl = dotenv.env['SUPABASE_URL']
          ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']
          ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const _ErrorApp(message: 'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env'));
    return;
  }

  // 2. Init SharedPreferences-backed settings
  final settings = SettingsService();

  try {
    await settings.init();
  } catch (e) {
    if (kDebugMode) print('Settings init failed: $e');
  }

  // 3. Init Supabase with error boundary
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } catch (e) {
    runApp(_ErrorApp(message: 'Failed to connect to Supabase:\n$e'));
    return;
  }

  if (kDebugMode) {
    print('Supabase initialized: ${Supabase.instance.client.runtimeType}');
  }

  // 4. Verify connectivity
  final connectionResult = await ConnectionService().check();
  if (!connectionResult.isConnected) {
    runApp(_ErrorApp(
      message: 'Cannot reach Supabase.\n${connectionResult.errorMessage}',
    ));
    return;
  }

  // 5. Run with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => PharmacyProvider(settings)..load(),
        ),
      ],
      child: const AkrabPharmaApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Error fallback widget shown when init fails
// ---------------------------------------------------------------------------
class _ErrorApp extends StatelessWidget {
  final String message;
  const _ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Startup Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
class AkrabPharmaApp extends StatelessWidget {
  const AkrabPharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akrab Pharma',
      debugShowCheckedModeBanner: false,
      theme: AppColors.lightTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primary),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Akrab Pharma',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              if (auth.isSignedIn) ...[
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Admin Dashboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await auth.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    }
                  },
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Pharmacist Login'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Welcome back!')),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
      body: const HomeScreen(),
    );
  }
}
