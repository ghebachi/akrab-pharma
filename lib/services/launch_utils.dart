import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralised phone / maps launcher with sanitisation and fallbacks.
class LaunchUtils {
  LaunchUtils._();

  // ── Phone ──────────────────────────────────────────────────────────────

  /// Strips everything except digits and leading '+', then dials.
  /// Returns true on success, false otherwise (so caller can show a Snackbar).
  static Future<bool> launchSecureCall(String rawPhone) async {
    final clean = sanitizePhone(rawPhone);
    if (clean.isEmpty) return false;

    final uri = Uri(scheme: 'tel', path: clean);
    return _safeLaunch(uri);
  }

  /// Removes spaces, dashes, parentheses, and leading/trailing junk.
  /// Keeps digits and a single leading '+' for international format.
  static String sanitizePhone(String raw) {
    // 1. Trim whitespace
    var s = raw.trim();

    // 2. Strip anything that isn't a digit or '+'
    s = s.replaceAll(RegExp(r'[^\d+]'), '');

    // 3. Normalise Algerian numbers: 0xxx → +213xxx
    if (s.startsWith('0') && s.length == 10) {
      s = '+213${s.substring(1)}';
    }

    // 4. Reject obviously broken strings
    if (s.length < 6) return '';

    return s;
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  /// 3-layer fallback: Google Maps app → Waze → web browser.
  static Future<bool> launchGoogleMaps(double lat, double lng) async {
    // 1. Google Maps app (deep-link)
    final gmapsApp = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await _safeLaunch(gmapsApp)) return true;

    // 2. Waze app (deep-link)
    final wazeApp = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await _safeLaunch(wazeApp)) return true;

    // 3. Google Maps in browser (web fallback)
    final gmapsWeb = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );
    return _safeLaunch(gmapsWeb);
  }

  /// 3-layer fallback with label: Google Maps app → browser → OS default map.
  static Future<bool> launchSecureNavigation(
    double lat,
    double lng, {
    String? label,
  }) async {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';

    final Uri appUrl = Uri.parse(
      'google.navigation:q=$lat,$lng'
      '${encodedLabel.isNotEmpty ? '&title=$encodedLabel' : ''}',
    );
    final Uri browserUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$lat,$lng'
      '${encodedLabel.isNotEmpty ? '&query=$encodedLabel' : ''}',
    );
    final Uri geoUrl = Uri.parse(
      'geo:$lat,$lng?q=$lat,$lng'
      '${encodedLabel.isNotEmpty ? '($encodedLabel)' : ''}',
    );

    if (await _safeLaunch(appUrl)) return true;
    if (await _safeLaunch(browserUrl)) return true;
    if (await _safeLaunch(geoUrl)) return true;
    return false;
  }

  // ── Internals ──────────────────────────────────────────────────────────

  /// Wraps [launchUrl] with try/catch so we never crash the UI.
  static Future<bool> _safeLaunch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      // Fallback: try without externalApplication flag
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Snackbar helper ────────────────────────────────────────────────────

  /// Shows a brief toast/snackbar if a launch action failed.
  static void showLaunchError(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not $action. Please try again.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
