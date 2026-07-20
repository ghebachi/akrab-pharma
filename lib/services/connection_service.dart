import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a Supabase connectivity check.
class ConnectionResult {
  final bool isConnected;
  final String? errorMessage;
  final Duration latency;

  const ConnectionResult({
    required this.isConnected,
    this.errorMessage,
    required this.latency,
  });
}

/// Lightweight Supabase connectivity check.
///
/// Pings the database with a tiny query instead of [getSession],
/// which only checks auth state (returns [] for unauthenticated users).
class ConnectionService {
  final SupabaseClient _client;
  final Duration _timeout;

  ConnectionService({
    SupabaseClient? client,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = client ?? Supabase.instance.client,
        _timeout = timeout;

  /// Checks if Supabase is reachable by running a minimal SELECT.
  Future<ConnectionResult> check() async {
    final stopwatch = Stopwatch()..start();

    try {
      // A lightweight query that always returns (empty or not).
      // Filters on an impossible condition so no rows are transferred.
      await _client
          .from('pharmacies')
          .select('id')
          .limit(1)
          .timeout(_timeout);

      stopwatch.stop();

      if (kDebugMode) {
        print('[Connection] OK (${stopwatch.elapsedMilliseconds} ms)');
      }

      return ConnectionResult(
        isConnected: true,
        latency: stopwatch.elapsed,
      );
    } on TimeoutException {
      stopwatch.stop();

      if (kDebugMode) {
        print('[Connection] TIMEOUT after ${_timeout.inSeconds}s');
      }

      return const ConnectionResult(
        isConnected: false,
        errorMessage: 'Connection timed out.',
        latency: Duration.zero,
      );
    } catch (e) {
      stopwatch.stop();

      if (kDebugMode) {
        print('[Connection] FAILED: $e');
      }

      return ConnectionResult(
        isConnected: false,
        errorMessage: e.toString(),
        latency: stopwatch.elapsed,
      );
    }
  }
}
