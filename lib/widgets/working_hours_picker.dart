import 'package:flutter/material.dart';

import '../config/app_colors.dart';

/// JSONB shape: `{ "mon": {"open":"08:00","close":"20:00"}, …, "sun": null }`
typedef WorkingHours = Map<String, Map<String, String>?>;

class WorkingHoursPicker extends StatefulWidget {
  /// Initial value parsed from DB.
  final WorkingHours? initial;

  /// Called whenever the user changes any day.
  final ValueChanged<WorkingHours> onChanged;

  const WorkingHoursPicker({
    super.key,
    this.initial,
    required this.onChanged,
  });

  @override
  State<WorkingHoursPicker> createState() => _WorkingHoursPickerState();

  /// Parse DB JSONB (Map<dynamic,dynamic>) into [WorkingHours].
  static WorkingHours? parseFromDb(dynamic json) {
    if (json == null) return null;
    if (json is! Map) return null;

    final result = <String, Map<String, String>?>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val == null) {
        result[key] = null;
      } else if (val is Map) {
        result[key] = {
          'open': val['open']?.toString() ?? '08:00',
          'close': val['close']?.toString() ?? '20:00',
        };
      }
    }
    return result;
  }

  /// Convert to JSONB-safe Map for Supabase insert/update.
  static Map<String, dynamic>? toDb(WorkingHours? hours) {
    if (hours == null || hours.isEmpty) return null;
    return hours.map((k, v) => MapEntry(k, v));
  }
}

class _WorkingHoursPickerState extends State<WorkingHoursPicker> {
  static const _dayLabels = [
    ('Mon', 'mon'),
    ('Tue', 'tue'),
    ('Wed', 'wed'),
    ('Thu', 'thu'),
    ('Fri', 'fri'),
    ('Sat', 'sat'),
    ('Sun', 'sun'),
  ];

  late WorkingHours _hours;

  @override
  void initState() {
    super.initState();
    _hours = widget.initial != null
        ? Map<String, Map<String, String>?>.from(widget.initial!)
        : {for (final d in _dayLabels) d.$2: null};
  }

  bool _isOpen(String day) => _hours[day] != null;

  Future<void> _pickTime(String day, {required bool isClose}) async {
    final current = _hours[day];
    final initial = TimeOfDay(
      hour: int.tryParse(current?[isClose ? 'close' : 'open']?.split(':').first ?? '') ?? (isClose ? 20 : 8),
      minute: int.tryParse(current?[isClose ? 'close' : 'open']?.split(':').last ?? '') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      setState(() {
        final existing = _hours[day] ?? {'open': '08:00', 'close': '20:00'};
        existing[isClose ? 'close' : 'open'] = formatted;
        _hours[day] = existing;
      });
      widget.onChanged(_hours);
    }
  }

  void _toggleDay(String day, bool open) {
    setState(() {
      _hours[day] = open ? {'open': '08:00', 'close': '20:00'} : null;
    });
    widget.onChanged(_hours);
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, key) in _dayLabels) ...[
          _buildDayRow(label, key),
          if (key != 'sun') const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _buildDayRow(String label, String key) {
    final open = _isOpen(key);

    return Row(
      children: [
        // Day label
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: open ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),

        // Toggle
        SizedBox(
          width: 44,
          child: Switch(
            value: open,
            onChanged: (v) => _toggleDay(key, v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),

        if (!open)
          // Closed label
          Expanded(
            child: Text(
              'Closed',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else ...[
          // Open time
          _TimeChip(
            label: _hours[key]!['open'] ?? '08:00',
            onTap: () => _pickTime(key, isClose: false),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('–', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          // Close time
          _TimeChip(
            label: _hours[key]!['close'] ?? '20:00',
            onTap: () => _pickTime(key, isClose: true),
          ),
        ],
      ],
    );
  }
}

/// Tappable time chip showing "HH:MM".
class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
