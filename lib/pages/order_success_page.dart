import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/checkout_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ticket_card.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;
  final String eventTitle;
  final String ticketTypeName;
  final DateTime eventDate;
  final String location;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.eventTitle,
    required this.ticketTypeName,
    required this.eventDate,
    required this.location,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final _checkoutService = CheckoutService();
  final _pageController = PageController();

  List<OrderItemModel> _items = [];
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _checkoutService.getOrderItems(widget.orderId);
      setState(() => _items = items);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur download gambar akan segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Tickets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: _isLoading
          ? const LoadingView()
          : _errorMessage != null
          ? ErrorView(message: _errorMessage!, onRetry: _loadItems)
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: TicketCard(
                          eventTitle: widget.eventTitle,
                          ticketTypeName: widget.ticketTypeName,
                          eventDate: widget.eventDate,
                          location: widget.location,
                          qrCode: item.qrCode,
                        ),
                      );
                    },
                  ),
                ),

                if (_items.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.grey2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: ElevatedButton.icon(
                    onPressed: _showComingSoon,
                    icon: const Icon(Icons.download),
                    label: const Text('DOWNLOAD IMAGE'),
                  ),
                ),
              ],
            ),
    );
  }
}
