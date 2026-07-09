import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';

class TicketListCard extends StatelessWidget {
  final MyTicketItem ticket;
  final VoidCallback onTap;

  const TicketListCard({super.key, required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM, yy');
    final isPast = ticket.eventDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.confirmation_number_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.eventTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(ticket.eventDate)} • ${ticket.eventLocation}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.softDarkish,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _statusBadge(isPast),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.softDarkish),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isPast) {
    String label;
    Color color;

    if (ticket.isCheckedIn) {
      label = 'Sudah Check-in';
      color = AppColors.success;
    } else if (isPast) {
      label = 'Event Selesai';
      color = AppColors.softDarkish;
    } else {
      label = 'Belum Digunakan';
      color = AppColors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
