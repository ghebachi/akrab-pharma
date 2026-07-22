import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../screens/pharmacy_registration_screen.dart';
import '../services/auth_service.dart';
import '../widgets/working_hours_picker.dart';
import '../widgets/pharmacy_preview_sheet.dart';

/// Pharmacist dashboard — duty toggle + view reports.
///
/// Requires:
///   - `pharmacies.pharmacist_id` column (links to auth.users)
///   - `pharmacies.is_duty` column (boolean toggle)
///   - RLS policies from add_pharmacist_columns.sql
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _auth = AuthService();

  // ── Pharmacy state ───────────────────────────────────────────────
  Map<String, dynamic>? _pharmacy;
  bool _isDuty = false;
  bool _isLoading = true;
  String? _error;

  // ── Working hours edit ──────────────────────────────────────────
  bool _isEditingHours = false;
  WorkingHours? _editedHours;

  // ── Reports ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _reports = [];

  // ── Inquiries ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _inquiries = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ── Data loading ─────────────────────────────────────────────────

  Future<void> _loadDashboard() async {
    if (!_auth.isSignedIn) {
      setState(() {
        _error = 'Please sign in to access the dashboard.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _auth.currentUser!.id;

      // Fetch the pharmacy linked to this pharmacist
      final pharmacyData = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, is_duty, working_hours')
          .eq('pharmacist_id', userId)
          .maybeSingle();

      if (pharmacyData == null) {
        setState(() {
          _error = 'No pharmacy linked to your account.';
          _isLoading = false;
        });
        return;
      }

      // Fetch reports for this pharmacy
      final reportData = await _supabase
          .from('user_reports')
          .select('id, report_type, created_at')
          .eq('pharmacy_id', pharmacyData['id'] as String)
          .order('created_at', ascending: false);

      // Fetch inquiries for this pharmacy
      final inquiryData = await _supabase
          .from('pharmacy_inquiries')
          .select('id, patient_name, patient_phone, message, status, pharmacist_reply, created_at')
          .eq('pharmacy_id', pharmacyData['id'] as String)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _pharmacy = pharmacyData;
        _isDuty = pharmacyData['is_duty'] as bool? ?? false;
        _reports = List<Map<String, dynamic>>.from(reportData as List);
        _inquiries = List<Map<String, dynamic>>.from(inquiryData as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  // ── Toggle duty ──────────────────────────────────────────────────

  Future<void> _toggleDuty(bool value) async {
    if (_pharmacy == null) return;

    // Optimistic update
    setState(() => _isDuty = value);

    try {
      await _supabase
          .from('pharmacies')
          .update({'is_duty': value}).eq('id', _pharmacy!['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? 'Duty activated' : 'Duty deactivated'),
          backgroundColor: value ? AppColors.success : AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() => _isDuty = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _saveWorkingHours() async {
    if (_pharmacy == null) return;

    final dbHours = WorkingHoursPicker.toDb(_editedHours);

    try {
      await _supabase
          .from('pharmacies')
          .update({'working_hours': dbHours}).eq('id', _pharmacy!['id'] as String);

      setState(() {
        _pharmacy!['working_hours'] = dbHours;
        _isEditingHours = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Working hours saved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _pharmacyCard(),
          const SizedBox(height: 12),
          _inquiriesSection(),
          const SizedBox(height: 12),
          _reportsSection(),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────

  Widget _buildError() {
    final noPharmacy = _error == 'No pharmacy linked to your account.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              noPharmacy ? Icons.local_pharmacy_outlined : Icons.error_outline,
              size: 48,
              color: noPharmacy ? AppColors.primary : AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (noPharmacy)
              FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PharmacyRegistrationScreen(),
                    ),
                  );
                  if (result == true && mounted) _loadDashboard();
                },
                icon: const Icon(Icons.add),
                label: const Text('Register Pharmacy'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              FilledButton.tonal(
                onPressed: _loadDashboard,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  // ── Pharmacy card with duty toggle ───────────────────────────────

  Widget _pharmacyCard() {
    final nameAr = _pharmacy!['name_ar'] as String? ?? '';
    final nameFr = _pharmacy!['name_fr'] as String? ?? '';
    final municipality = _pharmacy!['municipality'] as String? ?? '';
    final displayName = nameAr.isNotEmpty ? nameAr : nameFr;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_pharmacy_outlined,
                  color: _isDuty ? AppColors.success : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (nameFr.isNotEmpty && nameAr.isNotEmpty)
                        Text(
                          nameFr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      Text(
                        municipality,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Duty Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                _isDuty ? 'You are on duty today' : 'You are off duty',
                style: TextStyle(
                  color: _isDuty ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_isDuty ? AppColors.success : AppColors.textSecondary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isDuty ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDuty ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
              value: _isDuty,
              onChanged: _toggleDuty,
            ),
            const Divider(height: 24),

            // ── Preview as patient ────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => PharmacyPreviewSheet.show(context, _pharmacy!),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview as Patient'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildWorkingHours(),
          ],
        ),
      ),
    );
  }

  // ── Working hours display / edit ────────────────────────────────

  Widget _buildWorkingHours() {
    final dbHours = _pharmacy!['working_hours'];
    final parsed = WorkingHoursPicker.parseFromDb(dbHours);

    if (_isEditingHours) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Edit Working Hours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WorkingHoursPicker(
            initial: parsed,
            onChanged: (h) => _editedHours = h,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _saveWorkingHours,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() => _isEditingHours = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      );
    }

    // Read-only display
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hoursMap = parsed ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Working Hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() {
                _isEditingHours = true;
                _editedHours = parsed;
              }),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (parsed == null || parsed.isEmpty)
          const Text(
            'No working hours set',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          )
        else
          for (var i = 0; i < days.length; i++)
            _buildHourRow(labels[i], hoursMap[days[i]]),
      ],
    );
  }

  Widget _buildHourRow(String label, Map<String, String>? times) {
    final isOpen = times != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
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
  }

  // ── Inquiries section ──────────────────────────────────────────

  Widget _inquiriesSection() {
    final pending = _inquiries.where((i) => i['status'] == 'pending').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.question_answer_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Inquiries (${_inquiries.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (pending > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pending pending',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_inquiries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      const Text(
                        'No inquiries yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._inquiries.map((inquiry) => _inquiryTile(inquiry)),
          ],
        ),
      ),
    );
  }

  Widget _inquiryTile(Map<String, dynamic> inquiry) {
    final name = inquiry['patient_name'] as String? ?? 'Anonymous';
    final message = inquiry['message'] as String? ?? '';
    final status = inquiry['status'] as String? ?? 'pending';
    final reply = inquiry['pharmacist_reply'] as String?;
    final createdAt = inquiry['created_at'] as String?;
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withOpacity(0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPending ? AppColors.warning.withOpacity(0.2) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isPending
                    ? AppColors.warning.withOpacity(0.15)
                    : AppColors.success.withOpacity(0.15),
                child: Icon(
                  isPending ? Icons.help_outline : Icons.check_circle_outline,
                  size: 16,
                  color: isPending ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatInqDate(createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),

          // Existing reply
          if (reply != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your reply:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],

          // Reply button
          if (isPending || reply == null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showReplyDialog(inquiry),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Reply'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showReplyDialog(Map<String, dynamic> inquiry) async {
    final replyController = TextEditingController();
    final name = inquiry['patient_name'] as String? ?? 'Anonymous';
    final message = inquiry['message'] as String? ?? '';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reply to $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your reply',
                hintText: 'Type your response...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, replyController.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await _supabase
          .from('pharmacy_inquiries')
          .update({
            'pharmacist_reply': result,
            'status': 'replied',
            'replied_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', inquiry['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadDashboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  static String _formatInqDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // ── Reports section ──────────────────────────────────────────────

  Widget _reportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Reports (${_reports.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_reports.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 40, color: AppColors.success),
                      const SizedBox(height: 8),
                      const Text(
                        'No reports — all good!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._reports.take(10).map((r) => _reportTile(r)),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(Map<String, dynamic> report) {
    final type = report['report_type'] as String? ?? 'unknown';
    final createdAt = report['created_at'] as String?;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: _reportColor(type).withOpacity(0.12),
        child: Icon(_reportIcon(type), size: 16, color: _reportColor(type)),
      ),
      title: Text(
        _reportLabel(type),
        style: const TextStyle(fontSize: 14),
      ),
      trailing: Text(
        _formatDate(createdAt),
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  static Color _reportColor(String type) {
    switch (type) {
      case 'closed':
        return AppColors.error;
      case 'wrong_location':
        return AppColors.warning;
      case 'wrong_phone':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData _reportIcon(String type) {
    switch (type) {
      case 'closed':
        return Icons.lock_outline;
      case 'wrong_location':
        return Icons.location_off_outlined;
      case 'wrong_phone':
        return Icons.phone_disabled_outlined;
      default:
        return Icons.help_outline;
    }
  }

  static String _reportLabel(String type) {
    switch (type) {
      case 'closed':
        return 'Pharmacy reported closed';
      case 'wrong_location':
        return 'Wrong location reported';
      case 'wrong_phone':
        return 'Wrong phone number reported';
      default:
        return type;
    }
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
