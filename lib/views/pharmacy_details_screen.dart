import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../models/duty_pharmacy.dart';
import '../services/launch_utils.dart';
import '../services/report_service.dart';

class PharmacyDetailsScreen extends StatelessWidget {
  final DutyPharmacy pharmacy;

  const PharmacyDetailsScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pharmacy.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_pharmacy, color: AppColors.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pharmacy.displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pharmacy.isNightDuty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Night Duty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Info rows
          _InfoRow(
            icon: Icons.location_city,
            label: 'Municipality',
            value: pharmacy.municipality,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: pharmacy.municipality,
          ),
          _InfoRow(
            icon: Icons.phone,
            label: 'Phone',
            value: pharmacy.phoneNumber ?? 'Not available',
          ),
          _InfoRow(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${pharmacy.distanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.phone,
                  label: 'Call',
                  color: AppColors.accent,
                  onTap: pharmacy.phoneNumber != null
                      ? () async {
                          final ok = await LaunchUtils.launchSecureCall(pharmacy.phoneNumber!);
                          if (!ok && context.mounted) LaunchUtils.showLaunchError(context, 'make call');
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.directions,
                  label: 'Navigate',
                  color: AppColors.primary,
                  onTap: () async {
                    final ok = await LaunchUtils.launchGoogleMaps(
                      pharmacy.latitude,
                      pharmacy.longitude,
                    );
                    if (!ok && context.mounted) LaunchUtils.showLaunchError(context, 'open navigation');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.flag_outlined,
                  label: 'Report Issue',
                  color: AppColors.error,
                  onTap: () => _showReportDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // External launchers
  // -----------------------------------------------------------------------

  // -----------------------------------------------------------------------
  // Report dialog
  // -----------------------------------------------------------------------
  void _showReportDialog(BuildContext context) {
    String? selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report an Issue',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacy.displayName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What is wrong?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _ReportOption(
                    value: 'closed',
                    icon: Icons.lock_outline,
                    label: 'Pharmacy is closed',
                    groupValue: selectedType,
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  _ReportOption(
                    value: 'wrong_location',
                    icon: Icons.location_off_outlined,
                    label: 'Wrong location on map',
                    groupValue: selectedType,
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  _ReportOption(
                    value: 'wrong_phone',
                    icon: Icons.phone_disabled_outlined,
                    label: 'Wrong phone number',
                    groupValue: selectedType,
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedType != null
                          ? () async {
                              await _submitReport(ctx, selectedType!);
                            }
                          : null,
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(BuildContext context, String type) async {
    try {
      await ReportService().submitReport(
        pharmacyId: pharmacy.id,
        reportType: type,
      );
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Info row widget
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
// Action tile (used in detail screen buttons)
// ---------------------------------------------------------------------------
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? color.withOpacity(0.08) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, size: 24, color: enabled ? color : Colors.grey),
              const SizedBox(height: 6),
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

// ---------------------------------------------------------------------------
// Report option radio tile
// ---------------------------------------------------------------------------
class _ReportOption extends StatelessWidget {
  final String value;
  final IconData icon;
  final String label;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _ReportOption({
    required this.value,
    required this.icon,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
