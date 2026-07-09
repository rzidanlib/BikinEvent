import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class CheckoutService {
  final SupabaseClient _client = Supabase.instance.client;

  // Panggil function create_order yang sudah kita buat di database
  Future<String> createOrder({
    required String ticketId,
    required int quantity,
  }) async {
    final response = await _client.rpc(
      'create_order',
      params: {'p_ticket_id': ticketId, 'p_quantity': quantity},
    );

    return response as String; // order_id yang dikembalikan
  }

  // Ambil semua order_items dari 1 order (untuk ditampilkan sebagai QR)
  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final response = await _client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    return (response as List)
        .map((json) => OrderItemModel.fromJson(json))
        .toList();
  }

  // Ambil semua tiket milik user yang sedang login, join sampai ke data event
  Future<List<Map<String, dynamic>>> getMyTickets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('order_items')
        .select('''
        id,
        qr_code,
        is_checked_in,
        checked_in_at,
        created_at,
        tickets (
          name,
          price,
          events (
            id,
            title,
            location,
            event_date,
            poster_url
          )
        ),
        orders!inner (
          buyer_id
        )
      ''')
        .eq('orders.buyer_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
