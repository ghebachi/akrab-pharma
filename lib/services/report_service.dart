import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitReport({
    required String pharmacyId,
    required String reportType,
  }) async {
    await _client.from('user_reports').insert({
      'pharmacy_id': pharmacyId,
      'report_type': reportType,
    });
  }
}
