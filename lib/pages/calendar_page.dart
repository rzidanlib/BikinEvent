import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import 'event_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _eventService = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final events = await _eventService.getEvents();
      events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      setState(() => _events = events);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, List<EventModel>> get _grouped {
    final map = <String, List<EventModel>>{};
    for (final e in _events) {
      final key = DateFormat('yyyy-MM-dd').format(e.eventDate);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), centerTitle: true),
      body: _isLoading
          ? const LoadingView()
          : _errorMessage != null
          ? ErrorView(message: _errorMessage!, onRetry: _load)
          : _events.isEmpty
          ? const EmptyView(
              message: 'Belum ada event terjadwal',
              icon: Icons.calendar_month_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _grouped.entries
                    .map((e) => _buildSection(DateTime.parse(e.key), e.value))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildSection(DateTime date, List<EventModel> events) {
    final monthShort = DateFormat('MMM').format(date).toUpperCase();
    final dayNum = DateFormat('dd').format(date);
    final fullDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  monthShort,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  dayNum,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullDate.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.softDarkish,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...events.map(_eventRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event.posterUrl != null
                  ? Image.network(
                      event.posterUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('d MMMM, yy').format(event.eventDate)} • ${event.location}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.softDarkish,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 52,
    height: 52,
    color: AppColors.grey,
    child: const Icon(Icons.event, color: AppColors.primary, size: 20),
  );
}
