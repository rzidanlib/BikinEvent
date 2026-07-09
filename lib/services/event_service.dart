import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventService {
  final SupabaseClient _client = Supabase.instance.client;

  // Ambil semua kategori (untuk chip filter)
  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.from('categories').select();
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  // Ambil daftar event, dengan join ke profiles (organizer) & categories
  // categoryId null = ambil semua kategori
  Future<List<EventModel>> getEvents({String? categoryId}) async {
    var query = _client
        .from('events')
        .select('*, profiles(full_name), categories(name)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query.order('event_date', ascending: true);

    return (response as List).map((json) => EventModel.fromJson(json)).toList();
  }

  // Ambil detail 1 event beserta daftar tiketnya
  Future<EventModel> getEventDetail(String eventId) async {
    final response = await _client
        .from('events')
        .select('*, profiles(full_name), categories(name)')
        .eq('id', eventId)
        .single();

    return EventModel.fromJson(response);
  }

  Future<List<TicketModel>> getTicketsByEvent(String eventId) async {
    final response = await _client
        .from('tickets')
        .select()
        .eq('event_id', eventId)
        .order('price', ascending: true);

    return (response as List)
        .map((json) => TicketModel.fromJson(json))
        .toList();
  }
}
