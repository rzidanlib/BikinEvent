import 'package:bikinevent/pages/payment_page.dart';
import 'package:bikinevent/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';

class CheckoutPage extends StatefulWidget {
  final List<TicketModel> tickets;
  final String eventTitle;
  final DateTime eventDate;
  final String location;

  const CheckoutPage({
    super.key,
    required this.tickets,
    required this.eventTitle,
    required this.eventDate,
    required this.location,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _eventService = EventService();
  late TicketModel _selectedTicket;
  int _quantity = 1;

  Map<String, bool> _eligibilityMap = {}; // ticketId -> eligible atau tidak
  bool _isCheckingEligibility = true;

  @override
  void initState() {
    super.initState();
    _selectedTicket = widget.tickets.firstWhere(
      (t) => !t.isSoldOut,
      orElse: () => widget.tickets.first,
    );
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final map = <String, bool>{};
    for (final ticket in widget.tickets) {
      if (ticket.restrictionType == TicketRestriction.none) {
        map[ticket.id] = true;
      } else {
        map[ticket.id] = await _eventService.isTicketEligible(ticket.id);
      }
    }
    if (mounted) {
      setState(() {
        _eligibilityMap = map;
        _isCheckingEligibility = false;
        // Pastikan tiket yang otomatis terpilih di awal memang eligible
        if (_eligibilityMap[_selectedTicket.id] != true) {
          final firstEligible = widget.tickets
              .where((t) => !t.isSoldOut && _eligibilityMap[t.id] == true)
              .toList();
          if (firstEligible.isNotEmpty) _selectedTicket = firstEligible.first;
        }
      });
    }
  }

  void _selectTicket(TicketModel ticket) {
    if (_eligibilityMap[ticket.id] != true)
      return; // cegah pilih tiket yang tidak eligible
    setState(() {
      _selectedTicket = ticket;
      _quantity = 1;
    });
  }

  int get _maxQuantity => _selectedTicket.remaining.clamp(0, 5);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final totalPrice = _selectedTicket.price * _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            Row(
              children: widget.tickets.map((ticket) {
                final isSelected = ticket.id == _selectedTicket.id;
                final isEligible = _eligibilityMap[ticket.id] ?? false;
                final isDisabled = ticket.isSoldOut || !isEligible;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: isDisabled ? null : () => _selectTicket(ticket),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? AppColors.grey2
                              : (isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(
                                        alpha: 0.12,
                                      )),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ticket.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? AppColors.softDarkish
                                    : (isSelected
                                          ? Colors.white
                                          : AppColors.primary),
                              ),
                            ),
                            if (ticket.isSoldOut)
                              const Text(
                                'Habis',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.softDarkish,
                                ),
                              )
                            else if (!isEligible)
                              Text(
                                ticket.restrictionType ==
                                        TicketRestriction.institutionOnly
                                    ? 'Khusus ${ticket.restrictionInstitutionName ?? "Institusi"}'
                                    : 'Khusus Pelajar/Mhs',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.softDarkish,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_isCheckingEligibility)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            const SizedBox(height: 28),

            const Text(
              'Jumlah Tiket',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: AppColors.primary),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: _quantity < _maxQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Ticket Price',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedTicket.name} Ticket',
                  style: const TextStyle(color: AppColors.softDarkish),
                ),
                Text(currencyFormat.format(_selectedTicket.price)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$_quantity x ${currencyFormat.format(_selectedTicket.price)}',
                  style: const TextStyle(
                    color: AppColors.softDarkish,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  currencyFormat.format(totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: _maxQuantity == 0
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            ticket: _selectedTicket,
                            eventTitle: widget.eventTitle,
                            eventDate:
                                widget.eventDate, // lihat catatan di bawah
                            location: widget.location, // lihat catatan di bawah
                            quantity: _quantity,
                            totalPrice: totalPrice,
                          ),
                        ),
                      );
                    },
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ),
    );
  }
}
