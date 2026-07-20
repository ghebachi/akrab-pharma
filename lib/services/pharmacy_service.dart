import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PharmacyService {
  final _supabase = Supabase.instance.client;

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchNearestDutyPharmacies({
    required double longitude,
    required double latitude,
  }) async {
    try {
      final String todayDate = DateTime.now().toIso8601String().split('T')[0];

      final List<dynamic> response = await _supabase.rpc(
        'get_nearest_duty_pharmacies',
        params: {
          'user_lat': latitude,
          'user_lng': longitude,
          'target_date': todayDate,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching pharmacies from Supabase: $e');
      return [];
    }
  }
}
