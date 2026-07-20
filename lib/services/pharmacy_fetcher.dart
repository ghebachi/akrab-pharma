import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/duty_pharmacy.dart';
import '../services/gps_service.dart';

/// Result of a smart data fetch, carrying both duty pharmacies and
/// (optionally) the full fallback list.
class SmartFetchResult {
  final List<DutyPharmacy> dutyPharmacies;
  final List<DutyPharmacy> allPharmacies;
  final bool isUsingFallback;
  final double nearestDistanceKm;

  const SmartFetchResult({
    required this.dutyPharmacies,
    required this.allPharmacies,
    required this.isUsingFallback,
    required this.nearestDistanceKm,
  });

  List<DutyPharmacy> get displayList =>
      isUsingFallback ? allPharmacies : dutyPharmacies;
}

/// Central fetcher that combines RPC + fallback + retry logic.
///
/// Two modes:
///   - **GPS mode** (`municipality == null`): uses real coordinates.
///   - **Municipality mode** (`municipality != null`): skips GPS, queries by
///     municipality name — no location permission needed.
class PharmacyFetcher {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int _maxRetries = 3;
  static const int _baseDelaySeconds = 2;

  /// Fetch duty pharmacies for today by wilaya using the RPC function.
  Future<List<DutyPharmacy>> fetchDutyPharmacies(String wilaya) async {
    try {
      final response = await _supabase.rpc(
        'get_duty_pharmacies',
        params: {'wilaya_name': wilaya},
      );

      return (response as List<dynamic>)
          .map((e) => DutyPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch all nearby pharmacies within 25 km using GPS coordinates.
  Future<List<DutyPharmacy>> fetchNearby(double lat, double lng) async {
    try {
      final response = await _supabase.rpc(
        'get_nearby_pharmacies',
        params: {'user_lat': lat, 'user_lng': lng},
      );

      return (response as List<dynamic>)
          .map((e) => DutyPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Smart fetch with optional wilaya or municipality override.
  ///
  /// Priority: wilaya > municipality > GPS.
  Future<SmartFetchResult> getSmartData({
    required String targetDate,
    String? municipality,
    String? wilaya,
  }) async {
    // ── Wilaya mode: skip GPS, filter by wilaya column ────────────────
    if (wilaya != null) {
      return _fetchByWilaya(wilaya, targetDate);
    }

    // ── Municipality mode: skip GPS entirely ──────────────────────────
    if (municipality != null) {
      return _fetchByMunicipality(municipality, targetDate);
    }

    // ── GPS mode: need real coordinates ───────────────────────────────
    final position = await _getGpsWithRetry();
    final lat = position.latitude;
    final lng = position.longitude;

    final dutyList = await _fetchDutyPharmacies(lat, lng, targetDate);

    if (dutyList.isEmpty) {
      final allList = await _fetchAllPharmacies(lat, lng);
      return SmartFetchResult(
        dutyPharmacies: const [],
        allPharmacies: allList,
        isUsingFallback: true,
        nearestDistanceKm: allList.isNotEmpty ? allList.first.distanceKm : 0,
      );
    }

    return SmartFetchResult(
      dutyPharmacies: dutyList,
      allPharmacies: const [],
      isUsingFallback: false,
      nearestDistanceKm: dutyList.first.distanceKm,
    );
  }

  // ── Wilaya mode ──────────────────────────────────────────────────────

  /// Fetch duty pharmacies filtered by wilaya name (no GPS needed).
  Future<SmartFetchResult> _fetchByWilaya(
    String wilaya,
    String targetDate,
  ) async {
    try {
      final data = await _supabase
          .from('duty_schedules')
          .select('''
            pharmacy_id,
            is_night_duty,
            duty_date,
            pharmacies!inner (
              id, name_ar, name_fr, municipality, phone_number, location
            )
          ''')
          .eq('duty_date', targetDate);

      final list = <DutyPharmacy>[];
      for (final row in (data as List<dynamic>)) {
        final p = row['pharmacies'] as Map<String, dynamic>;
        // Match wilaya against municipality (wilaya-level filtering)
        if (p['municipality'] != wilaya) continue;

        final loc = p['location'];
        double lat = 0, lng = 0;
        if (loc is Map && loc.containsKey('coordinates')) {
          final coords = loc['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }

        list.add(DutyPharmacy(
          id: p['id'] as String,
          nameAr: p['name_ar'] as String? ?? '',
          nameFr: p['name_fr'] as String? ?? '',
          municipality: p['municipality'] as String? ?? '',
          phoneNumber: p['phone_number'] as String?,
          latitude: lat,
          longitude: lng,
          isNightDuty: row['is_night_duty'] as bool? ?? false,
          distanceMeters: 0,
        ));
      }

      if (list.isNotEmpty) {
        return SmartFetchResult(
          dutyPharmacies: list,
          allPharmacies: const [],
          isUsingFallback: false,
          nearestDistanceKm: 0,
        );
      }

      return _fetchAllByWilaya(wilaya);
    } catch (_) {
      return _fetchAllByWilaya(wilaya);
    }
  }

  /// Fallback: all pharmacies in a wilaya (no duty filter).
  Future<SmartFetchResult> _fetchAllByWilaya(String wilaya) async {
    try {
      final data = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, phone_number, location')
          .eq('municipality', wilaya);

      final list = (data as List<dynamic>).map((json) {
        final loc = json['location'];
        double lat = 0, lng = 0;
        if (loc is Map && loc.containsKey('coordinates')) {
          final coords = loc['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }

        return DutyPharmacy(
          id: json['id'] as String,
          nameAr: json['name_ar'] as String? ?? '',
          nameFr: json['name_fr'] as String? ?? '',
          municipality: json['municipality'] as String? ?? '',
          phoneNumber: json['phone_number'] as String?,
          latitude: lat,
          longitude: lng,
          isNightDuty: false,
          distanceMeters: 0,
        );
      }).toList();

      return SmartFetchResult(
        dutyPharmacies: const [],
        allPharmacies: list,
        isUsingFallback: true,
        nearestDistanceKm: 0,
      );
    } catch (_) {
      return const SmartFetchResult(
        dutyPharmacies: [],
        allPharmacies: [],
        isUsingFallback: true,
        nearestDistanceKm: 0,
      );
    }
  }

  // ── Municipality mode ────────────────────────────────────────────────

  /// Fetch duty pharmacies filtered by municipality name (no GPS needed).
  ///
  /// Queries pharmacies first by municipality to get IDs, then fetches
  /// only their duty schedules — avoids loading ALL schedules.
  Future<SmartFetchResult> _fetchByMunicipality(
    String municipality,
    String targetDate,
  ) async {
    try {
      final pharmacies = await _supabase
          .from('pharmacies')
          .select('id')
          .eq('municipality', municipality);

      final ids = (pharmacies as List<dynamic>)
          .map((e) => e['id'] as String)
          .toList();

      if (ids.isEmpty) return _fetchAllByMunicipality(municipality);

      final data = await _supabase
          .from('duty_schedules')
          .select('pharmacy_id, is_night_duty, duty_date')
          .inFilter('pharmacy_id', ids)
          .eq('duty_date', targetDate);

      if ((data as List<dynamic>).isEmpty) {
        return _fetchAllByMunicipality(municipality);
      }

      final pharmacyData = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, phone_number, location')
          .inFilter('id', ids);

      final pharmacyMap = {
        for (final p in (pharmacyData as List<dynamic>))
          p['id'] as String: p as Map<String, dynamic>,
      };

      final list = <DutyPharmacy>[];
      for (final row in (data as List<dynamic>)) {
        final pid = row['pharmacy_id'] as String;
        final p = pharmacyMap[pid];
        if (p == null) continue;

        final loc = p['location'];
        double lat = 0, lng = 0;
        if (loc is Map && loc.containsKey('coordinates')) {
          final coords = loc['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }

        list.add(DutyPharmacy(
          id: p['id'] as String,
          nameAr: p['name_ar'] as String? ?? '',
          nameFr: p['name_fr'] as String? ?? '',
          municipality: p['municipality'] as String? ?? '',
          phoneNumber: p['phone_number'] as String?,
          latitude: lat,
          longitude: lng,
          isNightDuty: row['is_night_duty'] as bool? ?? false,
          distanceMeters: 0,
        ));
      }

      return SmartFetchResult(
        dutyPharmacies: list,
        allPharmacies: const [],
        isUsingFallback: false,
        nearestDistanceKm: 0,
      );
    } catch (_) {
      return _fetchAllByMunicipality(municipality);
    }
  }

  /// Fallback: all pharmacies in a municipality (no duty filter).
  Future<SmartFetchResult> _fetchAllByMunicipality(String municipality) async {
    try {
      final data = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, phone_number, location')
          .eq('municipality', municipality);

      final list = (data as List<dynamic>).map((json) {
        final loc = json['location'];
        double lat = 0, lng = 0;
        if (loc is Map && loc.containsKey('coordinates')) {
          final coords = loc['coordinates'] as List;
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }

        return DutyPharmacy(
          id: json['id'] as String,
          nameAr: json['name_ar'] as String? ?? '',
          nameFr: json['name_fr'] as String? ?? '',
          municipality: json['municipality'] as String? ?? '',
          phoneNumber: json['phone_number'] as String?,
          latitude: lat,
          longitude: lng,
          isNightDuty: false,
          distanceMeters: 0,
        );
      }).toList();

      return SmartFetchResult(
        dutyPharmacies: const [],
        allPharmacies: list,
        isUsingFallback: true,
        nearestDistanceKm: 0,
      );
    } catch (_) {
      return const SmartFetchResult(
        dutyPharmacies: [],
        allPharmacies: [],
        isUsingFallback: true,
        nearestDistanceKm: 0,
      );
    }
  }

  // ── GPS mode ────────────────────────────────────────────────────────

  Future<Position> _getGpsWithRetry() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await GpsService.getCurrentPosition();
      } on GpsException catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        final delay = _baseDelaySeconds * pow(2, attempt).toInt();
        await Future.delayed(Duration(seconds: delay));
      }
    }
    throw GpsException('GPS failed after $_maxRetries attempts.');
  }

  Future<List<DutyPharmacy>> _fetchDutyPharmacies(
    double lat, double lng, String targetDate,
  ) async {
    try {
      final data = await _supabase.rpc('get_nearest_duty_pharmacies', params: {
        'user_lat': lat,
        'user_lng': lng,
        'target_date': targetDate,
      });

      return (data as List<dynamic>)
          .map((e) => DutyPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<DutyPharmacy>> _fetchAllPharmacies(double lat, double lng) async {
    try {
      final data = await _supabase.rpc('get_all_pharmacies_by_distance', params: {
        'user_lat': lat,
        'user_lng': lng,
      });

      return (data as List<dynamic>)
          .map((e) => DutyPharmacy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fetchAllPharmaciesFallback(lat, lng);
    }
  }

  Future<List<DutyPharmacy>> _fetchAllPharmaciesFallback(
    double lat, double lng,
  ) async {
    try {
      final data = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, phone_number, location');

      final list = (data as List<dynamic>).map((json) {
        final loc = json['location'];
        double pharmacyLat = 0, pharmacyLng = 0;

        if (loc is Map && loc.containsKey('coordinates')) {
          final coords = loc['coordinates'] as List;
          pharmacyLng = (coords[0] as num).toDouble();
          pharmacyLat = (coords[1] as num).toDouble();
        }

        final dist = _haversine(lat, lng, pharmacyLat, pharmacyLng);

        return DutyPharmacy(
          id: json['id'] as String,
          nameAr: json['name_ar'] as String? ?? '',
          nameFr: json['name_fr'] as String? ?? '',
          municipality: json['municipality'] as String? ?? '',
          phoneNumber: json['phone_number'] as String?,
          latitude: pharmacyLat,
          longitude: pharmacyLng,
          isNightDuty: false,
          distanceMeters: dist * 1000,
        );
      }).toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      return list;
    } catch (_) {
      return [];
    }
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
