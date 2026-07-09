import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/checkout_service.dart';
import '../theme/app_colors.dart';
import 'order_success_page.dart';

enum PaymentMethod { gopay, ovo, qris }

class PaymentPage extends StatefulWidget {
  final TicketModel ticket;
  final String eventTitle;
  final DateTime eventDate;
  final String location;
  final int quantity;
  final double totalPrice;

  const PaymentPage({
    super.key,
    required this.ticket,
    required this.eventTitle,
    required this.eventDate,
    required this.location,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _checkoutService = CheckoutService();
  final _voucherController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.gopay;
  bool _isProcessing = false;

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _applyVoucher() {
    // Placeholder -- belum ada sistem voucher sesungguhnya
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur voucher akan segera hadir')),
    );
  }

  Future<void> _handleCheckout() async {
    setState(() => _isProcessing = true);
    try {
      final orderId = await _checkoutService.createOrder(
        ticketId: widget.ticket.id,
        quantity: widget.quantity,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessPage(
              orderId: orderId,
              eventTitle: widget.eventTitle,
              ticketTypeName: widget.ticket.name,
              eventDate: widget.eventDate,
              location: widget.location,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pembayaran gagal: $e')));
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

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Total: ${currencyFormat.format(widget.totalPrice)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _paymentOption(
                  method: PaymentMethod.gopay,
                  label: 'GoPay',
                  color: const Color(0xFF00AED6),
                  logoText: 'Go',
                ),
                const SizedBox(height: 12),
                _paymentOption(
                  method: PaymentMethod.ovo,
                  label: 'OVO',
                  color: const Color(0xFF4C2A86),
                  logoText: 'OVO',
                ),
                const SizedBox(height: 12),
                _paymentOption(
                  method: PaymentMethod.qris,
                  label: 'QRIS',
                  color: AppColors.textBlack,
                  logoText: 'QR',
                ),

                const SizedBox(height: 28),
                const Text(
                  'Add Voucher',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'VOUCHER CODE',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _applyVoucher,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(90, 56),
                      ),
                      child: const Text('APPLY'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode simulasi: pesanan langsung dianggap lunas tanpa proses pembayaran nyata.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.softDarkish,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleCheckout,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('CHECKOUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required PaymentMethod method,
    required String label,
    required Color color,
    required String logoText,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey2,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  logoText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (v) => setState(() => _selectedMethod = v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
