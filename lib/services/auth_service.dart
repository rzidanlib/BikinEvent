import 'dart:io';

import 'package:bikinevent/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String statusType, // 'umum' atau 'pelajar_mahasiswa'
    String? educationLevel, // 'smp' / 'sma' / 'mahasiswa', null kalau umum
    String? institutionId,
    String? studentNumber,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        'status_type': statusType,
        'education_level': educationLevel,
        'institution_id': institutionId,
        'student_number': studentNumber,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }

  User? get currentUser => _client.auth.currentUser;

  // Ambil profile lengkap sebagai object (bukan Map mentah), lebih type-safe
  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('*, institutions(name)')
        .eq('id', userId)
        .single();

    return Profile.fromJson(response);
  }

  Future<void> updateProfile({required String fullName, String? phone}) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('profiles')
        .update({'full_name': fullName, 'phone': phone})
        .eq('id', userId);
  }

  Future<String> uploadAvatar(File imageFile) async {
    final userId = _client.auth.currentUser!.id;
    final fileExt = imageFile.path.split('.').last;
    final path = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
    final url = _client.storage.from('avatars').getPublicUrl(path);

    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }
}
