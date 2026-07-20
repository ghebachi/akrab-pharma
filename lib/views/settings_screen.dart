import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Location'),
          RadioListTile<String?>(
            title: const Text('Automatic (GPS)'),
            subtitle: const Text('Find nearest pharmacies using your location'),
            value: null,
            groupValue: settings.selectedMunicipality,
            activeColor: AppColors.primary,
            onChanged: (v) => settings.setMunicipality(v),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...SettingsService.municipalities
              .where((m) => m != 'Automatic (GPS)')
              .map(
                (m) => RadioListTile<String?>(
                  title: Text(m),
                  value: m,
                  groupValue: settings.selectedMunicipality,
                  activeColor: AppColors.primary,
                  onChanged: (v) => settings.setMunicipality(v),
                ),
              ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Choosing a municipality skips GPS and shows duty pharmacies in that area only.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
