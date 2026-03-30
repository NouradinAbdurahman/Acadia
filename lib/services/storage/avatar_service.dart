import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarService {
  final SupabaseClient _supabase;

  AvatarService(this._supabase);

  Future<String> uploadAvatar(File file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final fileExt = file.path.split('.').last;
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = fileName;

    // 1. Upload image
    await _supabase.storage.from('avatars').upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    // 2. Get public URL
    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

    // 3. Save URL in user profile
    await _supabase.from('users').update({'avatar_url': imageUrl}).eq('id', user.id);

    // 4. Return URL
    return imageUrl;
  }
}
