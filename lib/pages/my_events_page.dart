import 'package:bikinevent/pages/organizer_event_detail_page.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../../services/organizer_service.dart';
import '../../models/event_model.dart';
import '../../widgets/organizer_event_card.dart';
import 'create_event_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  final _organizerService = OrganizerService();
  List<EventModel> _events = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final events = await _organizerService.getMyEvents();
      setState(() => _events = events);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  EventTimeStatus _statusOf(EventModel event) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(event.eventDate, now))
      return EventTimeStatus.current;
    if (event.eventDate.isAfter(now)) return EventTimeStatus.upcoming;
    return EventTimeStatus.past;
  }

  void _openDetail(EventModel event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerEventDetailPage(eventId: event.id),
      ),
    );
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _loadEvents);

    final current = _events
        .where((e) => _statusOf(e) == EventTimeStatus.current)
        .toList();
    final upcoming = _events
        .where((e) => _statusOf(e) == EventTimeStatus.upcoming)
        .toList();
    final past = _events
        .where((e) => _statusOf(e) == EventTimeStatus.past)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _events.isEmpty
          ? RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView(
                children: const [
                  SizedBox(height: 100),
                  EmptyView(
                    message: 'Kamu belum membuat event',
                    icon: Icons.event_busy_outlined,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (current.isNotEmpty)
                    ..._buildSection('Current Event', current),
                  if (upcoming.isNotEmpty)
                    ..._buildSection('Upcoming Events', upcoming),
                  if (past.isNotEmpty) ..._buildSection('Last Events', past),
                  const SizedBox(height: 80), // ruang untuk FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()),
          );
          _loadEvents();
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Event'),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<EventModel> events) {
    return [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      const SizedBox(height: 10),
      ...events.map((event) {
        return OrganizerEventCard(
          event: event,
          totalSold: event.totalSold,
          totalQuota: event.totalQuota,
          status: _statusOf(event),
          onTap: () => _openDetail(event),
        );
      }),
      const SizedBox(height: 16),
    ];
  }

  // Sementara pakai pendekatan sederhana -- karena EventModel belum simpan totalQuota
  // secara eksplisit, kita ambil dari selisih data yang ada. Diperbaiki di Step 27.3.
  int _quotaOf(EventModel event) => event.totalQuota;
}
