class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  CategoryModel({required this.id, required this.name, this.icon});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
    );
  }
}

class TicketModel {
  final String id;
  final String eventId;
  final String name;
  final double price;
  final int quota;
  final int sold;

  TicketModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.quota,
    required this.sold,
  });

  int get remaining => quota - sold;
  bool get isSoldOut => remaining <= 0;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      eventId: json['event_id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quota: json['quota'],
      sold: json['sold'],
    );
  }
}

class EventModel {
  final String id;
  final String organizerId;
  final String? categoryId;
  final String title;
  final String? description;
  final String location;
  final String? posterUrl;
  final DateTime eventDate;
  final bool isPublic;
  final double lowestPrice;
  final int totalSold;

  // Data relasi (opsional, diisi kalau di-join saat query)
  final String? organizerName;
  final String? categoryName;

  EventModel({
    required this.id,
    required this.organizerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.location,
    this.posterUrl,
    required this.eventDate,
    required this.isPublic,
    this.organizerName,
    this.categoryName,
    this.lowestPrice = 0,
    this.totalSold = 0,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    double lowest = 0;
    int sold = 0;

    if (json['tickets'] != null) {
      final tickets = json['tickets'] as List;
      if (tickets.isNotEmpty) {
        final prices = tickets
            .map((t) => (t['price'] as num).toDouble())
            .toList();
        lowest = prices.reduce((a, b) => a < b ? a : b);
        sold = tickets.fold(0, (sum, t) => sum + (t['sold'] as int));
      }
    }

    return EventModel(
      id: json['id'],
      organizerId: json['organizer_id'],
      categoryId: json['category_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      posterUrl: json['poster_url'],
      eventDate: DateTime.parse(json['event_date']),
      isPublic: json['is_public'],
      // Kalau query pakai join, Supabase mengembalikan nested object
      organizerName: json['profiles'] != null
          ? json['profiles']['full_name']
          : null,
      categoryName: json['categories'] != null
          ? json['categories']['name']
          : null,
      lowestPrice: lowest,
      totalSold: sold,
    );
  }
}
