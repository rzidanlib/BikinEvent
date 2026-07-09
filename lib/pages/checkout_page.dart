import 'package:bikinevent/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/checkout_service.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final TicketModel ticket;
  final String eventTitle;

  const CheckoutPage({
    super.key,
    required this.ticket,
    required this.eventTitle,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _checkoutService = CheckoutService();
  int _quantity = 1;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final profile = await AuthService().getProfile();
    if (profile?.role == 'organizer' && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun Organizer tidak dapat membeli tiket'),
        ),
      );
    }
  }

  Future<void> _handleConfirmOrder() async {
    setState(() => _isProcessing = true);
    try {
      final orderId = await _checkoutService.createOrder(
        ticketId: widget.ticket.id,
        quantity: _quantity,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: orderId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout gagal: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final totalPrice = widget.ticket.price * _quantity;
    final maxQuantity = widget.ticket.remaining.clamp(
      0,
      5,
    ); // batasi max 5 tiket per transaksi

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Jenis tiket: ${widget.ticket.name}'),
                    Text(
                      'Harga: ${currencyFormat.format(widget.ticket.price)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jumlah Tiket',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _quantity < maxQuantity
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bayar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  currencyFormat.format(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Note simulasi pembayaran - nanti diganti payment gateway
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Mode simulasi: pesanan langsung dianggap lunas tanpa proses pembayaran nyata.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: (_isProcessing || maxQuantity == 0)
                  ? null
                  : _handleConfirmOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Konfirmasi & Bayar (Simulasi)'),
            ),
          ],
        ),
      ),
    );
  }
}
