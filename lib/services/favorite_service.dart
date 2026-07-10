import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class FavoriteService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isFavorited(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final response = await _client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .maybeSingle();
    return response != null;
  }

  Future<void> toggleFavorite(String eventId, bool currentlyFavorited) async {
    final userId = _client.auth.currentUser!.id;
    if (currentlyFavorited) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);
    } else {
      await _client.from('favorites').insert({
        'user_id': userId,
        'event_id': eventId,
      });
    }
  }

  Future<List<EventModel>> getFavoriteEvents() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('favorites')
        .select(
          'events(*, profiles!events_organizer_id_fkey(full_name), categories(name), tickets(price, sold, quota))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((json) => json['events'] != null)
        .map((json) => EventModel.fromJson(json['events']))
        .toList();
  }
}
