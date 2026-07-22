import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/duty_pharmacy.dart';
import '../models/wilayas.dart';
import '../providers/pharmacy_provider.dart';
import '../screens/auth_screen.dart';
import '../services/announcement_service.dart';
import '../services/launch_utils.dart';
import '../widgets/shimmer_loading.dart';
import 'admin_dashboard_screen.dart';
import 'admin_panel_screen.dart';
import 'all_pharmacies_screen.dart';
import 'pharmacy_details_screen.dart';
import 'settings_screen.dart';

// ---------------------------------------------------------------------------
// Home screen
// ---------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool? isAdmin;
  final bool isSignedIn;
  final VoidCallback? onSignOut;

  const HomeScreen({
    super.key,
    this.scaffoldKey,
    this.isAdmin,
    this.isSignedIn = false,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return _HomeView(
      scaffoldKey: scaffoldKey,
      isAdmin: isAdmin,
      isSignedIn: isSignedIn,
      onSignOut: onSignOut,
    );
  }
}

class _HomeView extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool? isAdmin;
  final bool isSignedIn;
  final VoidCallback? onSignOut;

  const _HomeView({this.scaffoldKey, this.isAdmin, this.isSignedIn = false, this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacyProvider>();

    return Scaffold(
      key: scaffoldKey,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Akrab Pharma'),
        actions: [
          // Wilaya dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedWilaya,
                isDense: true,
                items: Wilayas.all
                    .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) provider.setWilaya(v);
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick date',
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: _buildBody(context, provider),
      floatingActionButton: provider.status == PharmacyStatus.loading
          ? null
          : FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => provider.load(),
              icon: const Icon(Icons.my_location),
              label: const Text('Refresh'),
            ),
    );
  }

  // ── Date picker ──────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<PharmacyProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.setDate(picked);
    }
  }

  // ── Drawer ─────────────────────────────────────────────────────

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Akrab Pharma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const Divider(height: 1),
            if (isSignedIn) ...[
              if (isAdmin == true) ...[
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Admin Panel'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.local_pharmacy_outlined),
                title: const Text('Pharmacist Dashboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
              ),
              const Divider(height: 1),
            ],
            const Spacer(),
            const Divider(height: 1),
            if (isSignedIn)
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSignOut!();
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign In'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Body builder ─────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, PharmacyProvider provider) {
    return Column(
      children: [
        // Announcement banner (if exists)
        if (provider.announcement != null) _announcementBanner(provider.announcement!),
        // Main content
        Expanded(child: _buildStateContent(context, provider)),
      ],
    );
  }

  Widget _buildStateContent(BuildContext context, PharmacyProvider provider) {
    switch (provider.status) {
      // ---------------------------------------------------------------
      // STATE 1: Loading → Shimmer skeleton
      // ---------------------------------------------------------------
      case PharmacyStatus.loading:
        return Column(
          children: [
            _dateBanner(provider.selectedDate),
            const Expanded(child: ShimmerLoading()),
          ],
        );

      // ---------------------------------------------------------------
      // STATE 2: Error → Friendly error + Retry
      // ---------------------------------------------------------------
      case PharmacyStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined, size: 72, color: AppColors.error.withOpacity(0.7)),
                const SizedBox(height: 20),
                const Text(
                  'Oops!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => provider.retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllPharmaciesScreen()),
                    );
                  },
                  child: const Text('View all pharmacies in province'),
                ),
              ],
            ),
          ),
        );

      // ---------------------------------------------------------------
      // STATE 3: Empty (no duty pharmacies today in this wilaya)
      // ---------------------------------------------------------------
      case PharmacyStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 72,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'لا توجد صيدليات مناوبة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا توجد صيدليات مناوبة اليوم في ولاية ${provider.selectedWilaya}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => provider.retry(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );

      // ---------------------------------------------------------------
      // STATE 4: Fallback (no duty today) → auto-loaded all pharmacies
      // ---------------------------------------------------------------
      case PharmacyStatus.fallback:
        return Column(
          children: [
            _fallbackBanner(provider.selectedDate),
            Expanded(
              child: _buildDataList(context, provider),
            ),
          ],
        );

      // ---------------------------------------------------------------
      // STATE 4: Data → List (with optional far-away warning)
      // ---------------------------------------------------------------
      case PharmacyStatus.data:
        return Column(
          children: [
            _dateBanner(provider.selectedDate),
            if (provider.isFarAway) _farAwayBanner(provider.nearestDistanceKm),
            Expanded(child: _buildDataList(context, provider)),
          ],
        );
    }
  }

  // ── Banners ──────────────────────────────────────────────────────────
  Widget _announcementBanner(Announcement a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.accent.withOpacity(0.10),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.title.isNotEmpty)
                  Text(
                    a.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                Text(
                  a.message,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBanner(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.primary.withOpacity(0.06),
      child: Text(
        'Duty pharmacies — ${date.day}/${date.month}/${date.year}',
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }

  Widget _fallbackBanner(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No duty pharmacies for ${date.day}/${date.month}/${date.year}. Showing all nearby pharmacies.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _farAwayBanner(double nearestKm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No nearby duty pharmacies. Nearest is ${nearestKm.toStringAsFixed(1)} km away.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────
  Widget _buildDataList(BuildContext context, PharmacyProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: provider.pharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = provider.pharmacies[index];
        return _PharmacyCard(
          pharmacy: pharmacy,
          isOpen: provider.isPharmacyOpen(pharmacy.id),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pharmacy card widget
// ---------------------------------------------------------------------------
class _PharmacyCard extends StatelessWidget {
  final DutyPharmacy pharmacy;
  final bool isOpen;
  final VoidCallback? onTap;

  const _PharmacyCard({
    required this.pharmacy,
    required this.isOpen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_pharmacy, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pharmacy.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                  if (pharmacy.isNightDuty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Night', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ),
                  if (pharmacy.isNightDuty) const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.accent.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppColors.accent : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_city, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(pharmacy.municipality, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.straighten, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${pharmacy.distanceKm.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable action button
// ---------------------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

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
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: enabled ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
