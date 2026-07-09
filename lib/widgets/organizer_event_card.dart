import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';

enum EventTimeStatus { current, upcoming, past }

class OrganizerEventCard extends StatelessWidget {
  final EventModel event;
  final int totalSold;
  final int totalQuota;
  final EventTimeStatus status;
  final VoidCallback onTap;

  const OrganizerEventCard({
    super.key,
    required this.event,
    required this.totalSold,
    required this.totalQuota,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM, yy • HH:mm');

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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: event.posterUrl != null
                  ? Image.network(
                      event.posterUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(event.eventDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.softDarkish,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 13,
                        color: AppColors.softDarkish,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalSold / $totalQuota terjual',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.softDarkish,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _statusBadge(),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.softDarkish),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    late String label;
    late Color color;
    switch (status) {
      case EventTimeStatus.current:
        label = 'Berlangsung';
        color = AppColors.success;
        break;
      case EventTimeStatus.upcoming:
        label = 'Mendatang';
        color = AppColors.blue;
        break;
      case EventTimeStatus.past:
        label = 'Selesai';
        color = AppColors.softDarkish;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.grey,
      child: const Icon(Icons.event, color: AppColors.primary, size: 24),
    );
  }
}
