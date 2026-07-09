import 'package:bikinevent/pages/manage_ticket_page.dart';
import 'package:bikinevent/pages/scan_ticket_page.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_stack.dart';
import 'create_event_page.dart';

class OrganizerEventDetailPage extends StatefulWidget {
  final String eventId;
  const OrganizerEventDetailPage({super.key, required this.eventId});

  @override
  State<OrganizerEventDetailPage> createState() =>
      _OrganizerEventDetailPageState();
}

class _OrganizerEventDetailPageState extends State<OrganizerEventDetailPage> {
  final _eventService = EventService();

  EventModel? _event;
  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final event = await _eventService.getEventDetail(widget.eventId);
      final tickets = await _eventService.getTicketsByEvent(widget.eventId);
      setState(() {
        _event = event;
        _tickets = tickets;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventPage(eventId: widget.eventId),
      ),
    );
    _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView());
    if (_errorMessage != null || _event == null) {
      return Scaffold(
        body: ErrorView(
          message: _errorMessage ?? 'Event tidak ditemukan',
          onRetry: _loadDetail,
        ),
      );
    }

    final event = _event!;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(event)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              dateFormat.format(event.eventDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AvatarStack(
                        count: event.totalSold,
                        label: 'Members are joined',
                      ),
                      const Divider(height: 32),

                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description ?? 'Tidak ada deskripsi.',
                        maxLines: _descExpanded ? null : 3,
                        overflow: _descExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.softDarkish,
                          height: 1.4,
                        ),
                      ),
                      if ((event.description?.length ?? 0) > 120)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _descExpanded = !_descExpanded),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _descExpanded ? 'Show Less' : 'Read More',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Tombol Buat Tiket -- rata kanan, sesuai permintaan
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManageTicketsPage(eventId: widget.eventId),
                              ),
                            );
                            _loadDetail();
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Buat Tiket'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_tickets.isNotEmpty) ...[
                        const Text(
                          'Jenis Tiket',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._tickets.map(
                          (ticket) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.grey,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Terjual ${ticket.sold} / ${ticket.quota}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.softDarkish,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(ticket.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tombol back & edit melayang di atas hero image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIconButton(
                      Icons.arrow_back_ios_new,
                      () => Navigator.pop(context),
                    ),
                    _circleIconButton(Icons.edit_outlined, _openEdit),
                  ],
                ),
              ),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroImage(EventModel event) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: event.posterUrl != null
              ? Image.network(
                  event.posterUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroPlaceholder(),
                )
              : _heroPlaceholder(),
        ),
        Container(
          height: 280,
          decoration: BoxDecoration(gradient: AppColors.imageOverlayGradient),
        ),
        if (event.categoryName != null)
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.categoryName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      height: 280,
      color: AppColors.grey,
      child: const Center(
        child: Icon(Icons.event, size: 56, color: AppColors.primary),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanTicketPage()),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text(
              'SCAN TICKET',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
