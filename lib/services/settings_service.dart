import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings (municipality preference, etc.) to disk.
///
/// Must be initialised once via [init] before any other call.
class SettingsService extends ChangeNotifier {
  static const _keyMunicipality = 'selected_municipality';

  String? _selectedMunicipality;

  /// The municipality the user chose, or `null` = "Automatic" (GPS-based).
  String? get selectedMunicipality => _selectedMunicipality;

  bool get isAutomatic => _selectedMunicipality == null;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Load persisted values. Call once in `main()` before `runApp`.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedMunicipality = prefs.getString(_keyMunicipality);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  /// Set the preferred municipality, or `null` for GPS-based automatic mode.
  Future<void> setMunicipality(String? municipality) async {
    if (_selectedMunicipality == municipality) return;

    _selectedMunicipality = municipality;

    final prefs = await SharedPreferences.getInstance();
    if (municipality == null) {
      await prefs.remove(_keyMunicipality);
    } else {
      await prefs.setString(_keyMunicipality, municipality);
    }

    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Hardcoded list of municipalities in Guelma province.
  static const List<String> municipalities = [
    'Automatic (GPS)',
    'Guelma',
    'Héliopolis',
    'Bouati Mahmoud',
    'Hammam Debagh',
    'Bouhamama',
    'Ain Sandel',
    'Khezara',
    'Sidi Sandel',
    'Medjez Sfa',
    'Nechmaya',
    'Boumahra Ahmed',
    'Ain Reggada',
    'Oued Zenati',
    'Tamlouka',
    'Djellal',
    'Bir El Arch',
    'El Fedjoudj',
    'Roknia',
  ];

  /// Returns the municipality string to pass to the fetcher.
  /// `null` means "use GPS".
  String? get effectiveMunicipality => _selectedMunicipality;
}
