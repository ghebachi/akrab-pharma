import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  /// Minimum acceptable accuracy in meters.
  /// If GPS reports worse accuracy, we ask the user to retry.
  static const double minAccuracyMeters = 500.0;

  /// Requests permission and returns the current position.
  ///
  /// Throws [GpsException] on any failure so the caller can show a
  /// user-friendly message.
  static Future<Position> getCurrentPosition() async {
    if (kIsWeb) {
      return _getCurrentPositionWeb();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const GpsException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const GpsException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const GpsException(
        'Location permission permanently denied. '
        'Please enable it from app settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // Precision check: reject if accuracy is too low
    if (position.accuracy > minAccuracyMeters) {
      throw GpsException(
        'GPS signal is weak (accuracy: ${position.accuracy.round()}m). '
        'Please move to an open area and try again.',
      );
    }

    return position;
  }

  /// On web, Geolocator uses the browser Geolocation API.
  /// Accuracy checks and permissions are handled differently.
  static Future<Position> _getCurrentPositionWeb() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (position.accuracy > minAccuracyMeters) {
        throw GpsException(
          'GPS signal is weak (accuracy: ${position.accuracy.round()}m). '
          'Please move to an open area and try again.',
        );
      }

      return position;
    } catch (e) {
      if (e is GpsException) rethrow;
      throw GpsException('Failed to get location: $e');
    }
  }
}

class GpsException implements Exception {
  final String message;
  const GpsException(this.message);

  @override
  String toString() => message;
}
