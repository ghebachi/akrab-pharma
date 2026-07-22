import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_colors.dart';
import 'providers/pharmacy_provider.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'services/settings_service.dart';
import 'views/admin_dashboard_screen.dart';
import 'views/admin_panel_screen.dart';
import 'views/home_screen.dart';
import 'views/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AuthService _auth = AuthService();
  late final StreamSubscription<AuthState> _authSubscription;
  bool? _isAdmin;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();

    // Listen to auth state changes (login/logout/token refresh)
    _authSubscription = _auth.authStateChanges.listen((_) {
      _checkAdminStatus();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    if (!_auth.isSignedIn) {
      if (mounted) setState(() => _isAdmin = false);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isAdmin = false);
        return;
      }

      final check = await Supabase.instance.client
          .from('admin_users')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) setState(() => _isAdmin = check != null);
    } catch (_) {
      if (mounted) setState(() => _isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      scaffoldKey: _scaffoldKey,
      isAdmin: _isAdmin,
      isSignedIn: _auth.isSignedIn,
      onSignOut: () async {
        await _auth.signOut();
        setState(() => _isAdmin = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out')),
          );
        }
      },
    );
  }
}
