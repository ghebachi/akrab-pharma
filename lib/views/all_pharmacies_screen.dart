import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_colors.dart';

/// Displays ALL pharmacies in the province (not filtered by duty date).
class AllPharmaciesScreen extends StatefulWidget {
  const AllPharmaciesScreen({super.key});

  @override
  State<AllPharmaciesScreen> createState() => _AllPharmaciesScreenState();
}

class _AllPharmaciesScreenState extends State<AllPharmaciesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pharmacies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('pharmacies')
          .select('id, name_ar, name_fr, municipality, phone_number');

      if (!mounted) return;
      setState(() {
        _pharmacies = List<Map<String, dynamic>>.from(data as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load pharmacies.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Pharmacies')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_pharmacies.isEmpty) {
      return const Center(
        child: Text('No pharmacies found.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _pharmacies.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final p = _pharmacies[index];
        final displayName =
            (p['name_ar'] as String?)?.isNotEmpty == true ? p['name_ar'] : p['name_fr'];

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.accent,
            child: Icon(Icons.local_pharmacy, color: Colors.white, size: 20),
          ),
          title: Text(displayName ?? 'Unknown'),
          subtitle: Text(p['municipality'] ?? ''),
          trailing: p['phone_number'] != null
              ? IconButton(
                  icon: const Icon(Icons.phone, color: AppColors.accent),
                  onPressed: () {},
                )
              : null,
        );
      },
    );
  }
}
