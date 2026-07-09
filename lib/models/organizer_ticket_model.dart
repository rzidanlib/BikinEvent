class OrganizerTicketItem {
  final String id;
  final String eventId;
  final String eventTitle;
  final String name;
  final String category;
  final double price;
  final int quota;
  final int sold;

  OrganizerTicketItem({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.name,
    required this.category,
    required this.price,
    required this.quota,
    required this.sold,
  });

  factory OrganizerTicketItem.fromJson(Map<String, dynamic> json) {
    return OrganizerTicketItem(
      id: json['id'],
      eventId: json['event_id'],
      eventTitle: json['events']?['title'] ?? '-',
      name: json['name'],
      category: json['category'] ?? 'Umum',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quota: (json['quota'] as int?) ?? 0,
      sold: (json['sold'] as int?) ?? 0,
    );
  }
}
