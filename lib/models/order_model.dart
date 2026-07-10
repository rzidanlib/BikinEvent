class OrderItemModel {
  final String id;
  final String orderId;
  final String ticketId;
  final String qrCode;
  final bool isCheckedIn;
  final String eventId;
  final DateTime? checkedInAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.ticketId,
    required this.qrCode,
    required this.isCheckedIn,
    required this.eventId,
    this.checkedInAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      qrCode: json['qr_code'] as String? ?? '',
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'])
          : null,
    );
  }
}

class MyTicketItem {
  final String orderItemId;
  final String qrCode;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final String ticketName;
  final double ticketPrice;
  final String eventId;
  final String eventTitle;
  final String eventLocation;
  final DateTime eventDate;

  MyTicketItem({
    required this.orderItemId,
    required this.qrCode,
    required this.isCheckedIn,
    this.checkedInAt,
    required this.ticketName,
    required this.ticketPrice,
    required this.eventId,
    required this.eventTitle,
    required this.eventLocation,
    required this.eventDate,
  });

  factory MyTicketItem.fromJson(Map<String, dynamic> json) {
    final ticket = json['tickets'];
    final event = ticket['events'];

    return MyTicketItem(
      orderItemId: json['id'],
      qrCode: json['qr_code'],
      isCheckedIn: json['is_checked_in'],
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'])
          : null,
      ticketName: ticket['name'],
      ticketPrice: (ticket['price'] as num).toDouble(),
      eventId: event['id'],
      eventTitle: event['title'],
      eventLocation: event['location'],
      eventDate: DateTime.parse(event['event_date']),
    );
  }
}
