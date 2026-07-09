import 'dart:io';
import 'package:bikinevent/models/dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/organizer_ticket_model.dart';

class OrganizerService {
  final SupabaseClient _client = Supabase.instance.client;

  // Upload file poster ke Storage, kembalikan public URL-nya
  Future<String> uploadPoster(File imageFile) async {
    final userId = _client.auth.currentUser!.id;
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path =
        '$userId/$fileName'; // folder = user id, sesuai policy Step 9.1

    await _client.storage.from('event-posters').upload(path, imageFile);

    return _client.storage.from('event-posters').getPublicUrl(path);
  }

  // Buat event baru
  Future<String> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required String categoryId,
    required bool isPublic,
    String? posterUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('events')
        .insert({
          'organizer_id': userId,
          'category_id': categoryId,
          'title': title,
          'description': description,
          'location': location,
          'event_date': eventDate.toIso8601String(),
          'is_public': isPublic,
          'poster_url': posterUrl,
        })
        .select()
        .single();

    return response['id'];
  }

  // Ambil semua event milik organizer yang sedang login
  Future<List<EventModel>> getMyEvents() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('events')
        .select('*, categories(name), tickets(price, sold, quota)')
        .eq('organizer_id', userId)
        .order('event_date', ascending: false);

    return (response as List).map((json) => EventModel.fromJson(json)).toList();
  }

  // Tambah jenis tiket ke event
  Future<void> addTicket({
    required String eventId,
    required String name,
    required double price,
    required int quota,
  }) async {
    await _client.from('tickets').insert({
      'event_id': eventId,
      'name': name,
      'price': price,
      'quota': quota,
    });
  }

  Future<List<TicketModel>> getEventTickets(String eventId) async {
    final response = await _client
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .order('price');

    return (response as List)
        .map((json) => TicketModel.fromJson(json))
        .toList();
  }

  Future<void> deleteTicket(String ticketId) async {
    await _client.from('tickets').delete().eq('id', ticketId);
  }

  // Ambil ringkasan statistik untuk dashboard:
  // total event, total tiket terjual, estimasi total pendapatan, event terdekat
  Future<Map<String, dynamic>> getDashboardStats() async {
    final userId = _client.auth.currentUser!.id;

    // Ambil semua event milik organizer, sekaligus join ke tickets-nya
    final response = await _client
        .from('events')
        .select('id, title, event_date, tickets(price, sold, quota)')
        .eq('organizer_id', userId)
        .order('event_date', ascending: true);

    final events = response as List;

    int totalEvents = events.length;
    int totalSold = 0;
    double totalRevenue = 0;
    int upcomingCount = 0;
    Map<String, dynamic>? nextEvent;

    final now = DateTime.now();

    for (final event in events) {
      final eventDate = DateTime.parse(event['event_date']);
      final tickets = event['tickets'] as List;

      for (final ticket in tickets) {
        final sold = ticket['sold'] as int;
        final price = (ticket['price'] as num).toDouble();
        totalSold += sold;
        totalRevenue += sold * price;
      }

      if (eventDate.isAfter(now)) {
        upcomingCount++;
        // Ambil event terdekat (karena sudah di-order ascending, yang pertama
        // ditemukan yang "akan datang" itulah event terdekat)
        nextEvent ??= event;
      }
    }

    return {
      'totalEvents': totalEvents,
      'totalSold': totalSold,
      'totalRevenue': totalRevenue,
      'upcomingCount': upcomingCount,
      'nextEvent': nextEvent,
    };
  }

  Future<DashboardInsights> getInsights() async {
    final response = await _client.rpc('get_organizer_insights');
    return DashboardInsights.fromJson(response as Map<String, dynamic>);
  }

  Future<List<EventPerformance>> getEventPerformance() async {
    final response = await _client.rpc('get_organizer_event_performance');
    return (response as List)
        .map((json) => EventPerformance.fromJson(json))
        .toList();
  }

  Future<List<RecentOrder>> getRecentOrders({int limit = 10}) async {
    final response = await _client.rpc(
      'get_organizer_recent_orders',
      params: {'p_limit': limit},
    );
    return (response as List)
        .map((json) => RecentOrder.fromJson(json))
        .toList();
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required String categoryId,
    required bool isPublic,
    String? posterUrl,
  }) async {
    await _client
        .from('events')
        .update({
          'category_id': categoryId,
          'title': title,
          'description': description,
          'location': location,
          'event_date': eventDate.toIso8601String(),
          'is_public': isPublic,
          if (posterUrl != null) 'poster_url': posterUrl,
        })
        .eq('id', eventId);
  }

  // Ambil semua tiket dari semua event milik organizer, sekaligus nama event-nya
  Future<List<Map<String, dynamic>>> getAllTicketsRaw() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('tickets')
        .select('*, events!inner(title, organizer_id)')
        .eq('events.organizer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createTicket({
    required String eventId,
    required String name,
    required String category,
    required double price,
    required int quota,
  }) async {
    await _client.from('tickets').insert({
      'event_id': eventId,
      'name': name,
      'category': category,
      'price': price,
      'quota': quota,
    });
  }

  Future<void> updateTicket({
    required String ticketId,
    required String name,
    required String category,
    required double price,
    required int quota,
  }) async {
    await _client
        .from('tickets')
        .update({
          'name': name,
          'category': category,
          'price': price,
          'quota': quota,
        })
        .eq('id', ticketId);
  }

  Future<void> createCategory({
    required String name,
    required String icon,
  }) async {
    await _client.from('categories').insert({'name': name, 'icon': icon});
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String icon,
  }) async {
    await _client
        .from('categories')
        .update({'name': name, 'icon': icon})
        .eq('id', id);
  }
}
