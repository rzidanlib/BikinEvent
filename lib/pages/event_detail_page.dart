import 'package:bikinevent/pages/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _eventService = EventService();

  EventModel? _event;
  List<TicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final event = await _eventService.getEventDetail(widget.eventId);
      final tickets = await _eventService.getTicketsByEvent(widget.eventId);
      setState(() {
        _event = event;
        _tickets = tickets;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat detail: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return const Scaffold(body: Center(child: Text('Event tidak ditemukan')));
    }

    final event = _event!;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.event, size: 48, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 16),

          if (event.categoryName != null)
            Chip(label: Text(event.categoryName!)),
          const SizedBox(height: 8),

          Text(
            event.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _infoRow(Icons.calendar_today, dateFormat.format(event.eventDate)),
          _infoRow(Icons.location_on, event.location),
          if (event.organizerName != null)
            _infoRow(
              Icons.person,
              'Diselenggarakan oleh ${event.organizerName}',
            ),

          const Divider(height: 32),

          const Text(
            'Deskripsi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(event.description ?? 'Tidak ada deskripsi.'),

          const Divider(height: 32),

          const Text(
            'Pilih Tiket',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          ..._tickets.map(
            (ticket) => Card(
              child: ListTile(
                title: Text(ticket.name),
                subtitle: Text(
                  ticket.isSoldOut ? 'Habis' : 'Sisa ${ticket.remaining} tiket',
                ),
                trailing: Text(
                  currencyFormat.format(ticket.price),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                enabled: !ticket.isSoldOut,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CheckoutPage(ticket: ticket, eventTitle: event.title),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
