import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../models/wilayas.dart';
import '../services/gps_service.dart';
import '../widgets/working_hours_picker.dart';

class PharmacyRegistrationScreen extends StatefulWidget {
  const PharmacyRegistrationScreen({super.key});

  @override
  State<PharmacyRegistrationScreen> createState() =>
      _PharmacyRegistrationScreenState();
}

class _PharmacyRegistrationScreenState
    extends State<PharmacyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _nameAr = TextEditingController();
  final _nameFr = TextEditingController();
  final _municipality = TextEditingController();
  final _phone = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  bool _isLoading = false;
  bool _isLocating = false;
  WorkingHours? _workingHours;

  // ── GPS capture ────────────────────────────────────────────────

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await GpsService.getCurrentPosition();
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Not signed in';

      final data = <String, dynamic>{
        'name_ar': _nameAr.text.trim(),
        'name_fr': _nameFr.text.trim(),
        'municipality': _municipality.text.trim(),
        'phone_number': _phone.text.trim().isEmpty
            ? null
            : _phone.text.trim(),
        'pharmacist_id': user.id,
        'is_duty': false,
      };

      final lat = double.tryParse(_lat.text.trim());
      final lng = double.tryParse(_lng.text.trim());
      if (lat != null && lng != null) {
        data['location'] = 'SRID=4326;POINT($lng $lat)';
      }

      final wh = WorkingHoursPicker.toDb(_workingHours);
      if (wh != null) data['working_hours'] = wh;

      await _supabase.from('pharmacies').insert(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pharmacy registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameAr.dispose();
    _nameFr.dispose();
    _municipality.dispose();
    _phone.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Pharmacy')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Enter your pharmacy details to activate your dashboard.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Name (Arabic) ─────────────────────────────────
            TextFormField(
              controller: _nameAr,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'Name (Arabic)',
                hintText: 'صيدلية الحياة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_pharmacy),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Name (French) ─────────────────────────────────
            TextFormField(
              controller: _nameFr,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Name (French)',
                hintText: 'Pharmacie El Hayat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_pharmacy_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Municipality ──────────────────────────────────
            TextFormField(
              controller: _municipality,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Municipality',
                hintText: 'Alger Centre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Phone ─────────────────────────────────────────
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                hintText: '0555 00 00 00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),

            // ── Location section ──────────────────────────────
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pharmacy Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isLocating ? null : _captureLocation,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gps_fixed, size: 18),
                  label: Text(_isLocating ? 'Locating...' : 'Use GPS'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '36.7538',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '3.0588',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Working hours section ────────────────────────
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.schedule, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Working Hours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Set your opening and closing times for each day.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            WorkingHoursPicker(
              onChanged: (h) => _workingHours = h,
            ),
            const SizedBox(height: 32),

            // ── Submit ────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Register Pharmacy',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
