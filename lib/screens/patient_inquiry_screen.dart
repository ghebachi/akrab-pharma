import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';

/// Screen for patients to send an inquiry to a specific pharmacy.
///
/// Requires [pharmacyId] and [pharmacyName] to pre-fill context.
class PatientInquiryScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;

  const PatientInquiryScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<PatientInquiryScreen> createState() => _PatientInquiryScreenState();
}

class _PatientInquiryScreenState extends State<PatientInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.from('pharmacy_inquiries').insert({
        'pharmacy_id': widget.pharmacyId,
        'patient_name': _name.text.trim(),
        'patient_phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'message': _message.text.trim(),
        'status': 'pending',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquiry sent successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Inquiry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Context banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_pharmacy, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.pharmacyName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Your Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The pharmacist will contact you back.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // ── Name ────────────────────────────────────────
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Ahmed Ben Ali',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Phone ───────────────────────────────────────
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '0555 00 00 00',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Message ─────────────────────────────────────
            const Text(
              'Your Inquiry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ask about medicine availability, hours, services, etc.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Do you have Amoxicillin 500mg in stock?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length < 10) return 'Please provide more detail';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // ── Submit ──────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
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
                        'Send Inquiry',
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
