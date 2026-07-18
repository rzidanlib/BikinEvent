import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';

class TicketCard extends StatelessWidget {
  final String eventTitle;
  final String ticketTypeName;
  final DateTime eventDate;
  final String location;
  final String qrCode;
  final Widget?
  statusBadge; // opsional, dipakai di Tiket Saya untuk status check-in

  const TicketCard({
    super.key,
    required this.eventTitle,
    required this.ticketTypeName,
    required this.eventDate,
    required this.location,
    required this.qrCode,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner ikon pengganti poster (kita sengaja tidak menampilkan poster event di sini)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Icon(
                Icons.confirmation_number_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eventTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (statusBadge != null) statusBadge!,
                  ],
                ),
                const SizedBox(height: 14),
                _dashedDivider(),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _infoField('Date', dateFormat.format(eventDate)),
                    ),
                    Expanded(
                      child: _infoField('Time', timeFormat.format(eventDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _infoField('Venue', location)),
                    Expanded(child: _infoField('Ticket', ticketTypeName)),
                  ],
                ),
                const SizedBox(height: 16),
                _infoField('Ticket ID', qrCode.substring(0, 12).toUpperCase()),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Area seam dengan efek "notch" kiri-kanan
          SizedBox(
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(color: Colors.white),
                Positioned(
                  left: -14,
                  top: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -14,
                  top: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: 10,
                  child: _dashedDivider(),
                ),
              ],
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final qrSize = constraints.maxWidth * 0.65;
                return Center(
                  child: SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: QrImageView(
                      data: qrCode,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.softDarkish),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _dashedDivider() {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = 6.0;
          final dashCount = (constraints.constrainWidth() / (dashWidth * 2))
              .floor();
          return Flex(
            direction: Axis.horizontal,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.grey2),
                ),
              );
            }),
          ).paddedDash();
        },
      ),
    );
  }
}

// Extension kecil supaya spacing antar dash konsisten tanpa perlu widget tambahan berlebih
extension on Flex {
  Widget paddedDash() => Row(
    children: children
        .map((w) => Padding(padding: const EdgeInsets.only(right: 6), child: w))
        .toList(),
  );
}
