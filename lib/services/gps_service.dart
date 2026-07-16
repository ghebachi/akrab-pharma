import 'package:geolocator/geolocator.dart';

class GpsService {
  /// Requests permission and returns the current position.
  ///
  /// Throws [GpsException] on any failure so the caller can show a
  /// user-friendly message.
  static Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw GpsException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw GpsException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw GpsException(
        'Location permission permanently denied. '
        'Please enable it from app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}

class GpsException implements Exception {
  final String message;
  const GpsException(this.message);

  @override
  String toString() => message;
}
