import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import 'avatar_stack.dart';

class EventCardLarge extends StatelessWidget {
  final EventModel event;
  final double lowestPrice;
  final int soldCount;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final double posterHeight; // baru: default lebih tinggi untuk Home

  const EventCardLarge({
    super.key,
    required this.event,
    required this.lowestPrice,
    required this.soldCount,
    required this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
    this.posterHeight =
        190, // Home pakai default ini (lebih tinggi dari sebelumnya 150)
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d-MMM, yy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster sekarang punya padding di 3 sisi (bukan mepet ke tepi card),
            // dan sudutnya sendiri dibulatkan -- sesuai referensi
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: event.posterUrl != null
                        ? Image.network(
                            event.posterUrl!,
                            height: posterHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _posterPlaceholder(),
                          )
                        : _posterPlaceholder(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.error : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(event.eventDate),
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: AvatarStack(count: soldCount),
                      ), // dibungkus Flexible
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.buttonLinear,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'JOIN NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      height: posterHeight,
      color: AppColors.grey,
      child: const Center(
        child: Icon(Icons.event, size: 36, color: AppColors.primary),
      ),
    );
  }
}
