import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/duty_pharmacy.dart';
import '../models/wilayas.dart';
import '../services/announcement_service.dart';
import '../services/gps_service.dart';
import '../services/pharmacy_fetcher.dart';
import '../services/settings_service.dart';

enum PharmacyStatus { loading, error, fallback, empty, data }

class PharmacyProvider extends ChangeNotifier {
  final PharmacyFetcher _fetcher = PharmacyFetcher();
  final AnnouncementService _announcementService = AnnouncementService();
  final SettingsService _settings;

  PharmacyStatus _status = PharmacyStatus.loading;
  List<DutyPharmacy> _pharmacies = [];
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  bool _isFarAway = false;
  double _nearestDistanceKm = 0;
  String _selectedWilaya = Wilayas.all.first; // default: Automatic (GPS)

  // ── Announcement ───────────────────────────────────────────────────
  Announcement? _announcement;
  Announcement? get announcement => _announcement;

  // ── isOpen timer ───────────────────────────────────────────────────
  Timer? _openStatusTimer;

  PharmacyProvider(this._settings) {
    _settings.addListener(_onSettingsChanged);
    _startOpenStatusTimer();
    _refreshAnnouncement();
  }

  // ── Getters ──────────────────────────────────────────────────────────
  PharmacyStatus get status => _status;
  List<DutyPharmacy> get pharmacies => _pharmacies;
  String get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  bool get isFarAway => _isFarAway;
  double get nearestDistanceKm => _nearestDistanceKm;
  String get selectedWilaya => _selectedWilaya;
  bool get isAutomaticWilaya => _selectedWilaya == Wilayas.all.first;

  /// isOpen map: pharmacy.id → bool.
  /// Updated every 60 seconds by [_openStatusTimer].
  Map<String, bool> _openStatus = {};
  Map<String, bool> get openStatus => _openStatus;

  /// Convenience: is this specific pharmacy open right now?
  bool isPharmacyOpen(String pharmacyId) => _openStatus[pharmacyId] ?? false;

  String get bannerMessage {
    switch (_status) {
      case PharmacyStatus.loading:
        return 'Loading…';
      case PharmacyStatus.error:
        return _errorMessage;
      case PharmacyStatus.empty:
        return 'لا توجد صيدليات مناوبة اليوم في $_selectedWilaya';
      case PharmacyStatus.fallback:
        if (!isAutomaticWilaya) {
          return 'No duty pharmacies in $_selectedWilaya. Showing all.';
        }
        if (_settings.isAutomatic) {
          return 'No duty pharmacies today. Showing all nearby pharmacies.';
        }
        return 'No duty pharmacies in ${_settings.selectedMunicipality}. Showing all.';
      case PharmacyStatus.data:
        if (_isFarAway) {
          return 'No nearby duty pharmacies. Nearest is ${_nearestDistanceKm.toStringAsFixed(1)} km away.';
        }
        return 'Duty pharmacies — ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  // ── isOpen logic ──────────────────────────────────────────────────────

  /// Algerian pharmacy duty hours:
  ///   Day   duty: 08:00 – 20:00
  ///   Night duty: 20:00 – 08:00 (next day)
  void _recalculateOpenStatus() {
    final now = DateTime.now();
    final hour = now.hour;

    final Map<String, bool> updated = {};
    for (final p in _pharmacies) {
      if (p.isNightDuty) {
        // Night shift: open 20:00–08:00
        updated[p.id] = hour >= 20 || hour < 8;
      } else {
        // Day shift: open 08:00–20:00
        updated[p.id] = hour >= 8 && hour < 20;
      }
    }
    _openStatus = updated;
    notifyListeners();
  }

  void _startOpenStatusTimer() {
    _openStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _recalculateOpenStatus(),
    );
  }

  // ── Announcement ──────────────────────────────────────────────────────

  Future<void> _refreshAnnouncement() async {
    try {
      _announcement = await _announcementService.fetchLatest();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Announcement fetch failed: $e');
    }
  }

  // ── Listeners ────────────────────────────────────────────────────────

  void _onSettingsChanged() {
    load();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _openStatusTimer?.cancel();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Change the selected wilaya and auto-refetch.
  void setWilaya(String wilaya) {
    if (_selectedWilaya == wilaya) return;
    _selectedWilaya = wilaya;
    notifyListeners();
    load();
  }

  Future<void> setDate(DateTime date) async {
    _selectedDate = date;
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    _status = PharmacyStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // ── Wilaya mode: use the RPC function ────────────────────────────
      if (!isAutomaticWilaya) {
        if (kDebugMode) print('[RPC] get_duty_pharmacies → wilaya=$_selectedWilaya');

        final rpcResult = await _fetcher.fetchDutyPharmacies(_selectedWilaya);

        if (kDebugMode) {
          print('[RPC] Response count: ${rpcResult.length}');
          for (final p in rpcResult) {
            print('  → ${p.nameAr} | ${p.municipality} | night=${p.isNightDuty}');
          }
        }

        if (rpcResult.isEmpty) {
          _pharmacies = [];
          _status = PharmacyStatus.empty;
        } else {
          _pharmacies = rpcResult;
          _status = PharmacyStatus.data;
        }

        _recalculateOpenStatus();
        notifyListeners();
        return;
      }

      // ── GPS / Municipality mode: use smart fetcher ───────────────────
      String? municipalityParam;
      if (!_settings.isAutomatic) {
        municipalityParam = _settings.effectiveMunicipality;
      }

      if (kDebugMode) print('[GPS] municipality=$municipalityParam | fetching…');

      final result = await _fetcher.getSmartData(
        targetDate: _selectedDate.toIso8601String().substring(0, 10),
        municipality: municipalityParam,
      );

      _pharmacies = result.displayList;
      _nearestDistanceKm = result.nearestDistanceKm;
      _isFarAway = result.nearestDistanceKm > _maxNearbyKm && !result.isUsingFallback;

      if (kDebugMode) {
        print('[GPS] Result count: ${_pharmacies.length}');
        print('[GPS] Using fallback: ${result.isUsingFallback}');
        for (final p in _pharmacies.take(5)) {
          print('  → ${p.nameAr} | ${p.distanceKm.toStringAsFixed(1)} km');
        }
        if (_pharmacies.length > 5) {
          print('  … and ${_pharmacies.length - 5} more');
        }
      }

      if (result.isUsingFallback) {
        _status = PharmacyStatus.fallback;
      } else if (_pharmacies.isEmpty) {
        _status = PharmacyStatus.fallback;
      } else {
        _status = PharmacyStatus.data;
      }

      _recalculateOpenStatus();
    } on GpsException catch (e) {
      _errorMessage = e.message;
      _status = PharmacyStatus.error;
    } catch (e) {
      _errorMessage = 'Connection failed. Check your internet and try again.';
      _status = PharmacyStatus.error;
    }

    notifyListeners();
  }

  Future<void> retry() => load();

  static const double _maxNearbyKm = 50.0;
}
