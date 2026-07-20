/// A pharmacy entry — either on-duty or from the full-province fallback list.
class DutyPharmacy {
  final String id;
  final String nameAr;
  final String nameFr;
  final String municipality;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final bool isNightDuty;
  final double distanceMeters;

  DutyPharmacy({
    required this.id,
    required this.nameAr,
    required this.nameFr,
    required this.municipality,
    this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.isNightDuty,
    required this.distanceMeters,
  });

  factory DutyPharmacy.fromJson(Map<String, dynamic> json) {
    return DutyPharmacy(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      municipality: json['municipality'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      isNightDuty: json['is_night_duty'] as bool? ?? false,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
    );
  }

  String get displayName => nameAr.isNotEmpty ? nameAr : nameFr;

  double get distanceKm => distanceMeters / 1000.0;
}
