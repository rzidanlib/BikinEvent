import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar_stack.dart';
import 'checkout_page.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final _eventService = EventService();
  final _authService = AuthService();
  final _scrollController = ScrollController();

  EventModel? _event;
  List<TicketModel> _tickets = [];
  String? _userRole;
  bool _isFavorite = false; // sementara UI-only, belum tersimpan ke database
  bool _isLoading = true;
  String? _errorMessage;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final event = await _eventService.getEventDetail(widget.eventId);
      final tickets = await _eventService.getTicketsByEvent(widget.eventId);
      final profile = await _authService.getProfile();
      setState(() {
        _event = event;
        _tickets = tickets;
        _userRole = profile?.role;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _lowestPrice {
    if (_tickets.isEmpty) return 0;
    return _tickets.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  bool get _isSoldOutAll =>
      _tickets.isNotEmpty && _tickets.every((t) => t.isSoldOut);

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
    final isOrganizer = _userRole == 'organizer';
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(event, currencyFormat)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    120,
                  ), // ruang untuk bottom bar
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

                      // Kartu organizer
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
                          _circleIconButton(
                            Icons.chat_bubble_outline,
                            () => _showComingSoon('Chat'),
                          ),
                          const SizedBox(width: 8),
                          _circleIconButton(
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

                      if (isOrganizer)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Event ini memiliki ${_tickets.length} jenis tiket. Akun Organizer tidak dapat melakukan pembelian.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tombol back & favorite melayang di atas hero image
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
                      size: 18,
                    ),
                    _circleIconButton(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      () => setState(() => _isFavorite = !_isFavorite),
                      iconColor: _isFavorite ? AppColors.error : Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar sticky
          if (!isOrganizer) _buildBottomBar(currencyFormat),
        ],
      ),
    );
  }

  Widget _buildHeroImage(EventModel event, NumberFormat currencyFormat) {
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
        // Overlay gradasi gelap tipis supaya tombol back/love tetap terbaca
        Container(
          height: 320,
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
      height: 320,
      color: AppColors.grey,
      child: const Center(
        child: Icon(Icons.event, size: 56, color: AppColors.primary),
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat currencyFormat) {
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bookmark_border,
                  color: AppColors.softDarkish,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_tickets.isEmpty || _isSoldOutAll)
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              tickets: _tickets,
                              eventTitle: _event!.title,
                              eventDate: _event!.eventDate,
                              location: _event!.location,
                            ),
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text(
                    _isSoldOutAll
                        ? 'TIKET HABIS'
                        : (_tickets.isEmpty
                              ? 'BELUM ADA TIKET'
                              : 'BUY A TICKET • ${currencyFormat.format(_lowestPrice)}'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(
    IconData icon,
    VoidCallback onTap, {
    double size = 20,
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
        child: Icon(icon, color: iconColor, size: size),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Fitur $feature akan segera hadir')));
  }
}
