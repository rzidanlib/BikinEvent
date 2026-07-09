class OrderItemModel {
  final String id;
  final String orderId;
  final String ticketId;
  final String qrCode;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.ticketId,
    required this.qrCode,
    required this.isCheckedIn,
    this.checkedInAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      ticketId: json['ticket_id'],
      qrCode: json['qr_code'],
      isCheckedIn: json['is_checked_in'],
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
