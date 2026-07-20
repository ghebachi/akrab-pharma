import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized auth service wrapping Supabase Auth.
///
/// Provides:
/// - Sign in / sign out
/// - Reactive auth state via [authStateChanges]
/// - Convenience getters: [isSignedIn], [currentUser], [currentEmail]
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Current state ──────────────────────────────────────────────────

  bool get isSignedIn => _supabase.auth.currentSession != null;
  User? get currentUser => _supabase.auth.currentUser;
  String? get currentEmail => currentUser?.email;

  /// Stream that emits on every auth state change (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ── Actions ────────────────────────────────────────────────────────

  /// Sign in with email + password.
  ///
  /// Throws [AuthException] on invalid credentials, which the caller
  /// should catch and display to the user.
  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (kDebugMode) {
      print('[Auth] Signed in: ${currentUser?.email}');
    }
  }

  /// Sign out and clear the session.
  Future<void> signOut() async {
    await _supabase.auth.signOut();

    if (kDebugMode) {
      print('[Auth] Signed out');
    }
  }
}
