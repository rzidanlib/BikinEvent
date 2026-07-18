import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/institution_model.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<InstitutionModel>> getInstitutions({
    InstitutionLevel? level,
  }) async {
    var query = _client.from('institutions').select();
    if (level != null) query = query.eq('level', level.name);
    final response = await query.order('name');
    return (response as List)
        .map((json) => InstitutionModel.fromJson(json))
        .toList();
  }

  Future<void> createInstitution({
    required String name,
    required InstitutionLevel level,
    String? emailDomain,
  }) async {
    await _client.from('institutions').insert({
      'name': name,
      'level': level.name,
      'email_domain': emailDomain?.isEmpty ?? true ? null : emailDomain,
    });
  }

  Future<void> updateInstitution({
    required String id,
    required String name,
    required InstitutionLevel level,
    String? emailDomain,
  }) async {
    await _client
        .from('institutions')
        .update({
          'name': name,
          'level': level.name,
          'email_domain': emailDomain?.isEmpty ?? true ? null : emailDomain,
        })
        .eq('id', id);
  }
}
