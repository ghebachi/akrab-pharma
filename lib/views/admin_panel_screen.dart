import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';
import '../services/auth_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _auth = AuthService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  bool _isAdmin = false;

  // ── Stats ──────────────────────────────────────────────────────
  int _totalVisits = 0;
  int _totalPharmacies = 0;
  int _totalSchedules = 0;
  int _nightSchedules = 0;
  int _totalReports = 0;

  // ── Pharmacies ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _pharmacies = [];

  // ── Schedules ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _schedules = [];
  bool _nightOnlyFilter = false;

  // ── Reports ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  AUTH CHECK
  // ══════════════════════════════════════════════════════════════

  Future<void> _checkAdmin() async {
    if (!_auth.isSignedIn) {
      setState(() {
        _error = 'Please sign in as an admin.';
        _isLoading = false;
      });
      return;
    }

    try {
      final check = await _supabase
          .from('admin_users')
          .select('user_id')
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (check == null) {
        setState(() {
          _error = 'Access denied. Admin only.';
          _isLoading = false;
        });
        return;
      }

      _isAdmin = true;
      await _loadAll();
    } catch (e) {
      setState(() {
        _error = 'Auth check failed: $e';
        _isLoading = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  DATA LOADING
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadStats(),
        _loadPharmacies(),
        _loadSchedules(),
        _loadReports(),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Load failed: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    try {
      final data = await _supabase.rpc('get_admin_stats');
      final row = (data as List).first as Map<String, dynamic>;
      _totalVisits = (row['total_visits'] as num?)?.toInt() ?? 0;
      _totalPharmacies = (row['total_pharmacies'] as num?)?.toInt() ?? 0;
      _totalSchedules = (row['total_schedules'] as num?)?.toInt() ?? 0;
      _nightSchedules = (row['night_schedules'] as num?)?.toInt() ?? 0;
      _totalReports = (row['total_reports'] as num?)?.toInt() ?? 0;
    } catch (_) {
      _totalVisits = 0;
      _totalPharmacies = 0;
      _totalSchedules = 0;
      _nightSchedules = 0;
      _totalReports = 0;
    }
  }

  Future<void> _loadPharmacies() async {
    final data = await _supabase
        .from('pharmacies')
        .select('id, name_ar, name_fr, municipality, phone_number, pharmacist_id')
        .order('name_ar');
    _pharmacies = List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> _loadSchedules() async {
    final data = await _supabase.rpc('get_admin_schedules', params: {
      'p_night_only': _nightOnlyFilter,
    });
    _schedules = List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> _loadReports() async {
    try {
      final data = await _supabase.rpc('get_admin_reports');
      _reports = List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      _reports = [];
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  PHARMACY CRUD
  // ══════════════════════════════════════════════════════════════

  Future<void> _addOrEditPharmacy([Map<String, dynamic>? existing]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _PharmacyDialog(existing: existing),
    );
    if (result == true) {
      await _loadPharmacies();
      await _loadStats();
      setState(() {});
    }
  }

  Future<void> _deletePharmacy(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pharmacy'),
        content: Text('Delete "$name" and all its schedules?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('pharmacies').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" deleted'), backgroundColor: AppColors.success),
        );
        await _loadPharmacies();
        await _loadStats();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  REPORT DELETE
  // ══════════════════════════════════════════════════════════════

  Future<void> _deleteReport(String id) async {
    try {
      await _supabase.from('user_reports').delete().eq('id', id);
      await _loadReports();
      await _loadStats();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          if (_isAdmin)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
        bottom: _isAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Stats'),
                  Tab(icon: Icon(Icons.local_pharmacy_outlined), text: 'Pharmacies'),
                  Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Schedules'),
                  Tab(icon: Icon(Icons.report_outlined), text: 'Reports'),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAdmin ? Icons.error_outline : Icons.lock_outline,
                size: 48,
                color: _isAdmin ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: _checkAdmin, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _StatsTab(visits: _totalVisits, pharmacies: _totalPharmacies,
            schedules: _totalSchedules, nightSchedules: _nightSchedules,
            reports: _totalReports),
        _PharmaciesTab(
          pharmacies: _pharmacies,
          onAdd: () => _addOrEditPharmacy(),
          onEdit: (p) => _addOrEditPharmacy(p),
          onDelete: _deletePharmacy,
        ),
        _SchedulesTab(
          schedules: _schedules,
          nightOnly: _nightOnlyFilter,
          onFilterChanged: (v) async {
            _nightOnlyFilter = v;
            setState(() {});
            await _loadSchedules();
            setState(() {});
          },
        ),
        _ReportsTab(reports: _reports, onDelete: _deleteReport),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 1: STATS
// ══════════════════════════════════════════════════════════════════

class _StatsTab extends StatelessWidget {
  final int visits, pharmacies, schedules, nightSchedules, reports;

  const _StatsTab({
    required this.visits,
    required this.pharmacies,
    required this.schedules,
    required this.nightSchedules,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _card('Visits', visits.toString(), Icons.visibility_outlined, AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _card('Pharmacies', pharmacies.toString(), Icons.local_pharmacy_outlined, AppColors.success)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _card('Schedules (30d)', schedules.toString(), Icons.calendar_month_outlined, AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _card('Night Shifts', nightSchedules.toString(), Icons.nightlight_outlined, AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        _card('User Reports', reports.toString(), Icons.report_outlined, AppColors.error),
      ],
    );
  }

  static Widget _card(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Icon(icon, size: 20, color: color),
            ]),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 2: PHARMACIES
// ══════════════════════════════════════════════════════════════════

class _PharmaciesTab extends StatelessWidget {
  final List<Map<String, dynamic>> pharmacies;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final void Function(String id, String name) onDelete;

  const _PharmaciesTab({
    required this.pharmacies,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('${pharmacies.length} pharmacies',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: pharmacies.isEmpty
              ? const Center(child: Text('No pharmacies.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: pharmacies.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final p = pharmacies[i];
                    final name = (p['name_ar'] as String? ?? '').isNotEmpty
                        ? p['name_ar'] as String
                        : p['name_fr'] as String? ?? '';
                    final muni = p['municipality'] as String? ?? '';
                    final phone = p['phone_number'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.local_pharmacy_outlined, size: 18, color: AppColors.primary),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('$muni${phone.isNotEmpty ? ' · $phone' : ''}',
                          style: const TextStyle(fontSize: 13)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => onEdit(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => onDelete(p['id'] as String, name),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 3: SCHEDULES
// ══════════════════════════════════════════════════════════════════

class _SchedulesTab extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  final bool nightOnly;
  final ValueChanged<bool> onFilterChanged;

  const _SchedulesTab({
    required this.schedules,
    required this.nightOnly,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('${schedules.length} schedules',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const Spacer(),
              Row(children: [
                const Text('Night only', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Switch(
                  value: nightOnly,
                  onChanged: onFilterChanged,
                  activeColor: AppColors.primary,
                ),
              ]),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: schedules.isEmpty
              ? const Center(child: Text('No schedules found.', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final s = schedules[i];
                    final name = (s['name_ar'] as String? ?? '').isNotEmpty
                        ? s['name_ar'] as String
                        : s['name_fr'] as String? ?? '';
                    final isNight = s['is_night_duty'] as bool? ?? false;
                    final date = s['duty_date'] as String? ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isNight
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.success.withOpacity(0.15),
                        child: Icon(
                          isNight ? Icons.nightlight_outlined : Icons.wb_sunny_outlined,
                          size: 18,
                          color: isNight ? AppColors.primary : AppColors.success,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(date, style: const TextStyle(fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isNight
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isNight ? 'Night' : 'Day',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isNight ? AppColors.primary : AppColors.success,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  TAB 4: REPORTS
// ══════════════════════════════════════════════════════════════════

class _ReportsTab extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final ValueChanged<String> onDelete;

  const _ReportsTab({required this.reports, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
            SizedBox(height: 12),
            Text('No reports — all good!', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final r = reports[i];
        final type = r['report_type'] as String? ?? 'unknown';
        final name = (r['name_ar'] as String? ?? '').isNotEmpty
            ? r['name_ar'] as String
            : r['name_fr'] as String? ?? '';
        final createdAt = r['created_at'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _reportColor(type).withOpacity(0.12),
            child: Icon(_reportIcon(type), size: 18, color: _reportColor(type)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(_reportLabel(type), style: TextStyle(color: _reportColor(type), fontSize: 13)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_formatDate(createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppColors.error),
              onPressed: () => onDelete(r['report_id'] as String),
            ),
          ]),
        );
      },
    );
  }

  static Color _reportColor(String t) {
    switch (t) {
      case 'closed': return AppColors.error;
      case 'wrong_location': return AppColors.warning;
      case 'wrong_phone': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  static IconData _reportIcon(String t) {
    switch (t) {
      case 'closed': return Icons.lock_outline;
      case 'wrong_location': return Icons.location_off_outlined;
      case 'wrong_phone': return Icons.phone_disabled_outlined;
      default: return Icons.help_outline;
    }
  }

  static String _reportLabel(String t) {
    switch (t) {
      case 'closed': return 'Pharmacy reported closed';
      case 'wrong_location': return 'Wrong location';
      case 'wrong_phone': return 'Wrong phone number';
      default: return t;
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

// ══════════════════════════════════════════════════════════════════
//  ADD / EDIT PHARMACY DIALOG
// ══════════════════════════════════════════════════════════════════

class _PharmacyDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _PharmacyDialog({this.existing});

  @override
  State<_PharmacyDialog> createState() => _PharmacyDialogState();
}

class _PharmacyDialogState extends State<_PharmacyDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameAr;
  late final TextEditingController _nameFr;
  late final TextEditingController _municipality;
  late final TextEditingController _phone;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  bool _isSaving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameAr = TextEditingController(text: e?['name_ar'] as String? ?? '');
    _nameFr = TextEditingController(text: e?['name_fr'] as String? ?? '');
    _municipality = TextEditingController(text: e?['municipality'] as String? ?? '');
    _phone = TextEditingController(text: e?['phone_number'] as String? ?? '');
    _lat = TextEditingController(text: '');
    _lng = TextEditingController(text: '');
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'name_ar': _nameAr.text.trim(),
        'name_fr': _nameFr.text.trim(),
        'municipality': _municipality.text.trim(),
        'phone_number': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      };

      // Add PostGIS location only if lat/lng provided
      final lat = double.tryParse(_lat.text.trim());
      final lng = double.tryParse(_lng.text.trim());
      if (lat != null && lng != null) {
        data['location'] =
            'SRID=4326;POINT($lng $lat)';
      }

      if (isEditing) {
        await supabase.from('pharmacies').update(data).eq('id', widget.existing!['id'] as String);
      } else {
        await supabase.from('pharmacies').insert(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Pharmacy' : 'Add Pharmacy'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameAr,
                decoration: const InputDecoration(labelText: 'Name (Arabic) *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _nameFr, decoration: const InputDecoration(labelText: 'Name (French)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _municipality,
                decoration: const InputDecoration(labelText: 'Municipality *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
