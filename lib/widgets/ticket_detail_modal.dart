import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'ticket_card.dart';

void showTicketDetailModal(BuildContext context, MyTicketItem ticket) {
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
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              TicketCard(
                eventTitle: ticket.eventTitle,
                ticketTypeName: ticket.ticketName,
                eventDate: ticket.eventDate,
                location: ticket.eventLocation,
                qrCode: ticket.qrCode,
                statusBadge: ticket.isCheckedIn ? _checkedInBadge() : null,
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _checkedInBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'Checked In',
      style: TextStyle(
        color: Colors.green,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
