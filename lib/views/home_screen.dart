import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../services/gps_service.dart';

// ---------------------------------------------------------------------------
// Data model for a single pharmacy row returned by the RPC.
// ---------------------------------------------------------------------------
class DutyPharmacy {
  final String id;
  final String name;
  final String address;
  final String municipality;
  final String? phoneNumber;
  final String? whatsappNumber;
  final double latitude;
  final double longitude;
  final bool isNightDuty;
  final double distanceMeters;

  DutyPharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.municipality,
    this.phoneNumber,
    this.whatsappNumber,
    required this.latitude,
    required this.longitude,
    required this.isNightDuty,
    required this.distanceMeters,
  });

  factory DutyPharmacy.fromJson(Map<String, dynamic> json) {
    return DutyPharmacy(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      municipality: json['municipality'] as String,
      phoneNumber: json['phone_number'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isNightDuty: json['is_night_duty'] as bool? ?? false,
      distanceMeters: (json['distance_meters'] as num).toDouble(),
    );
  }

  double get distanceKm => distanceMeters / 1000.0;
}

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<DutyPharmacy> _pharmacies = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  // -----------------------------------------------------------------------
  // Data fetching
  // -----------------------------------------------------------------------
  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await GpsService.getCurrentPosition();

      final data = await _supabase.rpc('get_nearest_duty_pharmacies', params: {
        'user_lat': position.latitude,
        'user_lng': position.longitude,
        'target_date': _selectedDate.toIso8601String().substring(0, 10),
      });

      if (!mounted) return;

      setState(() {
        _pharmacies = (data as List<dynamic>)
            .map((e) => DutyPharmacy.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } on GpsException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load pharmacies. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadPharmacies();
    }
  }

  // -----------------------------------------------------------------------
  // External launchers
  // -----------------------------------------------------------------------
  Future<void> _openWhatsApp(String phoneNumber) async {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$digits?text=');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps(double lat, double lng, String name) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );
    // Fallback: query-less search by name
    final fallback = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(fallback)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  // -----------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akrab Pharma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadPharmacies,
        icon: const Icon(Icons.my_location),
        label: const Text('Refresh'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadPharmacies,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pharmacies.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_pharmacy_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'No duty pharmacies found for this date.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Date banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.primary.withOpacity(0.06),
          child: Text(
            'Duty pharmacies — ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        // Pharmacy list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: _pharmacies.length,
            itemBuilder: (context, index) {
              return _PharmacyCard(
                pharmacy: _pharmacies[index],
                onWhatsApp: _openWhatsApp,
                onMaps: _openMaps,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pharmacy card widget
// ---------------------------------------------------------------------------
class _PharmacyCard extends StatelessWidget {
  final DutyPharmacy pharmacy;
  final void Function(String phone) onWhatsApp;
  final void Function(double lat, double lng, String name) onMaps;

  const _PharmacyCard({
    required this.pharmacy,
    required this.onWhatsApp,
    required this.onMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 — name + night badge
            Row(
              children: [
                const Icon(Icons.local_pharmacy, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pharmacy.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (pharmacy.isNightDuty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Night',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Row 2 — municipality
            Row(
              children: [
                const Icon(Icons.location_city, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  pharmacy.municipality,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Row 3 — distance
            Row(
              children: [
                const Icon(Icons.straighten, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${pharmacy.distanceKm.toStringAsFixed(1)} km away',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: AppColors.accent,
                    onTap: pharmacy.whatsappNumber != null
                        ? () => onWhatsApp(pharmacy.whatsappNumber!)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.directions,
                    label: 'Navigate',
                    color: AppColors.primary,
                    onTap: () => onMaps(pharmacy.latitude, pharmacy.longitude, pharmacy.name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable action button inside a card
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color.withOpacity(0.10) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: enabled ? color : Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled ? color : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
