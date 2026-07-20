import 'package:supabase_flutter/supabase_flutter.dart';

/// A site-wide announcement pushed by admin (stored in `site_announcements`).
class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Fetches the latest active announcement from Supabase.
///
/// Expects a table `site_announcements`:
///   id UUID PK, title TEXT, message TEXT, is_active BOOLEAN, created_at TIMESTAMPTZ
///
/// Falls back gracefully if the table doesn't exist yet.
class AnnouncementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the most recent active announcement, or `null`.
  Future<Announcement?> fetchLatest() async {
    try {
      final data = await _supabase
          .from('site_announcements')
          .select('id, title, message, created_at')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return Announcement.fromJson(data);
    } catch (_) {
      // Table may not exist yet — not an error.
      return null;
    }
  }
}
