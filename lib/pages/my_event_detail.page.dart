import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/event_service.dart';
import '../services/checkout_service.dart';
import '../services/favorite_service.dart';
import '../models/event_model.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../widgets/ticket_card.dart';

class MyEventDetailPage extends StatefulWidget {
  final String eventId;
  const MyEventDetailPage({super.key, required this.eventId});

  @override
  State<MyEventDetailPage> createState() => _MyEventDetailPageState();
}

class _MyEventDetailPageState extends State<MyEventDetailPage> {
  final _eventService = EventService();
  final _checkoutService = CheckoutService();
  final _favoriteService = FavoriteService();

  EventModel? _event;
  List<MyTicketItem> _myTickets = [];
  bool _isFavorite = false;
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
      final rawTickets = await _checkoutService.getMyTicketsForEvent(
        widget.eventId,
      );
      final favorited = await _favoriteService.isFavorited(widget.eventId);
      setState(() {
        _event = event;
        _myTickets = rawTickets.map((j) => MyTicketItem.fromJson(j)).toList();
        _isFavorite = favorited;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final newState = !_isFavorite;
    setState(() => _isFavorite = newState);
    try {
      await _favoriteService.toggleFavorite(widget.eventId, !newState);
    } catch (_) {
      setState(() => _isFavorite = !newState);
    }
  }

  Future<void> _openDirections() async {
    final event = _event!;
    Uri uri;

    if (event.mapsUrl != null && event.mapsUrl!.isNotEmpty) {
      final parsed = Uri.tryParse(event.mapsUrl!);
      if (parsed != null) {
        uri = parsed;
      } else {
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(event.location)}',
        );
      }
    } else if (event.latitude != null && event.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${event.latitude},${event.longitude}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(event.location)}',
      );
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka aplikasi peta')),
        );
      }
    }
  }

  void _openTicketDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _myTickets.length > 1
                      ? _buildTicketCarousel()
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            if (_myTickets.isNotEmpty)
                              TicketCard(
                                eventTitle: _event!.title,
                                ticketTypeName: _myTickets.first.ticketName,
                                eventDate: _event!.eventDate,
                                location: _event!.location,
                                qrCode: _myTickets.first.qrCode,
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCarousel() {
    return PageView.builder(
      itemCount: _myTickets.length,
      itemBuilder: (context, index) {
        final ticket = _myTickets[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TicketCard(
            eventTitle: _event!.title,
            ticketTypeName: ticket.ticketName,
            eventDate: _event!.eventDate,
            location: _event!.location,
            qrCode: ticket.qrCode,
          ),
        );
      },
    );
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
                      // 3 tombol aksi: Call, Directions, My Ticket
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionButton(
                            Icons.call,
                            'Call',
                            AppColors.primary,
                            null,
                          ),
                          _actionButton(
                            Icons.directions,
                            'Directions',
                            AppColors.blue,
                            _openDirections,
                          ),
                          _actionButton(
                            Icons.confirmation_number,
                            'My Ticket',
                            AppColors.warning,
                            _openTicketDrawer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'BOOKED',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateFormat.format(event.eventDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (event.organizerName?.isNotEmpty ?? false)
                                  ? event.organizerName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.organizerName ?? 'Panitia Event',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  'Event Organiser',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.softDarkish,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _circleIconButtonSmall(
                            Icons.chat_bubble_outline,
                            () => _showComingSoon('Chat'),
                          ),
                          const SizedBox(width: 8),
                          _circleIconButtonSmall(
                            Icons.call_outlined,
                            () => _showComingSoon('Telepon'),
                          ),
                        ],
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
                    ],
                  ),
                ),
              ),
            ],
          ),

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
                    _circleIconButton(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      _toggleFavorite,
                      iconColor: _isFavorite ? AppColors.error : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildTicketBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeroImage(EventModel event) {
    return Stack(
      children: [
        SizedBox(
          height: 320,
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
          height: 320,
          decoration: BoxDecoration(gradient: AppColors.imageOverlayGradient),
        ),
      ],
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      height: 320,
      color: AppColors.grey,
      child: const Center(
        child: Icon(Icons.event, size: 56, color: AppColors.primary),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDisabled ? AppColors.grey2 : color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDisabled ? AppColors.softDarkish : Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBottomBar() {
    final ticketCount = _myTickets.length;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: _openTicketDrawer,
        onVerticalDragEnd: (details) {
          // Swipe ke atas (velocity negatif) juga membuka drawer tiket
          if ((details.primaryVelocity ?? 0) < -200) _openTicketDrawer();
        },
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.buttonLinear,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ticket ($ticketCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _circleIconButtonSmall(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.grey,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.softDarkish),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Fitur $feature akan segera hadir')));
  }
}
