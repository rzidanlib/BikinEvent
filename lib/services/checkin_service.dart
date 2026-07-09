import 'package:supabase_flutter/supabase_flutter.dart';

class CheckinService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> checkInTicket(String qrCode) async {
    final response = await _client.rpc(
      'check_in_ticket',
      params: {'p_qr_code': qrCode},
    );

    return Map<String, dynamic>.from(response);
  }
}
