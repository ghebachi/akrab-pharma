import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../widgets/working_hours_picker.dart';

/// Bottom sheet that shows a pharmacy exactly as a patient would see it.
///
/// Takes the raw Supabase row (Map) so it works with any data shape.
class PharmacyPreviewSheet extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyPreviewSheet({super.key, required this.pharmacy});

  /// Convenience opener.
  static void show(BuildContext context, Map<String, dynamic> pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PharmacyPreviewSheet(pharmacy: pharmacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameAr = pharmacy['name_ar'] as String? ?? '';
    final nameFr = pharmacy['name_fr'] as String? ?? '';
    final displayName = nameAr.isNotEmpty ? nameAr : nameFr;
    final municipality = pharmacy['municipality'] as String? ?? '';
    final phone = pharmacy['phone_number'] as String?;
    final isDuty = pharmacy['is_duty'] as bool? ?? false;
    final hours = WorkingHoursPicker.parseFromDb(pharmacy['working_hours']);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // ── Drag handle ──────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Preview banner ───────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Patient Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pharmacy header ──────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDuty ? AppColors.accent : AppColors.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.local_pharmacy,
                      size: 32,
                      color: isDuty ? AppColors.accent : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (nameAr.isNotEmpty && nameFr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              nameFr,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Duty badge ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDuty
                      ? AppColors.accent.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDuty
                        ? AppColors.accent.withOpacity(0.3)
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDuty ? Icons.check_circle : Icons.cancel_outlined,
                      size: 20,
                      color: isDuty ? AppColors.accent : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isDuty ? 'On Duty Today' : 'Not on Duty',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDuty ? AppColors.accent : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Info rows ────────────────────────────────────
              _InfoTile(
                icon: Icons.location_city,
                title: 'Municipality',
                value: municipality,
              ),
              _InfoTile(
                icon: Icons.phone,
                title: 'Phone',
                value: phone ?? 'Not available',
                valueColor: phone != null ? AppColors.primary : AppColors.textSecondary,
              ),

              // ── Working hours ────────────────────────────────
              if (hours != null && hours.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.schedule, size: 20, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Working Hours',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildHoursDisplay(hours),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoursDisplay(WorkingHours hours) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: List.generate(7, (i) {
        final day = days[i];
        final times = hours[day];
        final isOpen = times != null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              if (isOpen)
                Text(
                  '${times['open']} – ${times['close']}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                )
              else
                const Text(
                  'Closed',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Info tile (compact) ────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
