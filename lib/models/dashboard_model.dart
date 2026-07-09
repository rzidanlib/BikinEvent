class DashboardInsights {
  final double netSales;
  final double netSalesThisMonth;
  final double netSalesLastMonth;
  final int ticketsSold;
  final int ticketsSoldThisMonth;
  final int ticketsSoldLastMonth;
  final int totalQuota;
  final int totalOrders;
  final int totalOrdersThisMonth;
  final int totalOrdersLastMonth;

  DashboardInsights({
    required this.netSales,
    required this.netSalesThisMonth,
    required this.netSalesLastMonth,
    required this.ticketsSold,
    required this.ticketsSoldThisMonth,
    required this.ticketsSoldLastMonth,
    required this.totalQuota,
    required this.totalOrders,
    required this.totalOrdersThisMonth,
    required this.totalOrdersLastMonth,
  });

  factory DashboardInsights.fromJson(Map<String, dynamic> json) {
    return DashboardInsights(
      netSales: (json['netSales'] as num).toDouble(),
      netSalesThisMonth: (json['netSalesThisMonth'] as num).toDouble(),
      netSalesLastMonth: (json['netSalesLastMonth'] as num).toDouble(),
      ticketsSold: json['ticketsSold'],
      ticketsSoldThisMonth: json['ticketsSoldThisMonth'],
      ticketsSoldLastMonth: json['ticketsSoldLastMonth'],
      totalQuota: json['totalQuota'],
      totalOrders: json['totalOrders'],
      totalOrdersThisMonth: json['totalOrdersThisMonth'],
      totalOrdersLastMonth: json['totalOrdersLastMonth'],
    );
  }

  // Menghitung persentase perubahan bulan ini vs bulan lalu.
  // Kalau bulan lalu 0 tapi bulan ini ada penjualan, dianggap +100%.
  double _pctChange(num current, num previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  double get netSalesChangePct =>
      _pctChange(netSalesThisMonth, netSalesLastMonth);
  double get ticketsSoldChangePct =>
      _pctChange(ticketsSoldThisMonth, ticketsSoldLastMonth);
  double get totalOrdersChangePct =>
      _pctChange(totalOrdersThisMonth, totalOrdersLastMonth);
}

class EventPerformance {
  final String eventId;
  final String eventTitle;
  final int sold;
  final int quota;
  final double revenue;

  EventPerformance({
    required this.eventId,
    required this.eventTitle,
    required this.sold,
    required this.quota,
    required this.revenue,
  });

  factory EventPerformance.fromJson(Map<String, dynamic> json) {
    return EventPerformance(
      eventId: json['event_id'],
      eventTitle: json['event_title'],
      sold: json['sold'],
      quota: json['quota'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

class RecentOrder {
  final String orderId;
  final String customerName;
  final String ticketName;
  final DateTime orderDate;
  final double totalPrice;

  RecentOrder({
    required this.orderId,
    required this.customerName,
    required this.ticketName,
    required this.orderDate,
    required this.totalPrice,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderId: json['order_id'],
      customerName: json['customer_name'],
      ticketName: json['ticket_name'],
      orderDate: DateTime.parse(json['order_date']),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}
