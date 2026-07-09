import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/organizer_service.dart';
import '../../models/dashboard_model.dart';
import '../../theme/app_colors.dart';

class OrganizerDashboardPage extends StatefulWidget {
  const OrganizerDashboardPage({super.key});

  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  final _organizerService = OrganizerService();

  DashboardInsights? _insights;
  List<EventPerformance> _performance = [];
  List<RecentOrder> _recentOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final insights = await _organizerService.getInsights();
      final performance = await _organizerService.getEventPerformance();
      final recentOrders = await _organizerService.getRecentOrders(limit: 5);
      setState(() {
        _insights = insights;
        _performance = performance;
        _recentOrders = recentOrders;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _loadAll);

    final insights = _insights!;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Insights',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              // 3 kartu berjejer kalau layar cukup lebar, wrap ke bawah kalau sempit
              final isWide = constraints.maxWidth > 600;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 24) / 3
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isWide ? cardWidth : constraints.maxWidth,
                    child: _insightCard(
                      'Total Net Sales',
                      currencyFormat.format(insights.netSales),
                      insights.netSalesChangePct,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _insightCard(
                      'Total Tickets Sold',
                      '${insights.ticketsSold} / ${insights.totalQuota}',
                      insights.ticketsSoldChangePct,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _insightCard(
                      'Total Orders',
                      '${insights.totalOrders}',
                      insights.totalOrdersChangePct,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),
          const Text(
            'Performa per Event',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildPerformanceTable(currencyFormat),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecentOrdersTable(currencyFormat),
        ],
      ),
    );
  }

  Widget _insightCard(String label, String value, double changePct) {
    final isPositive = changePct >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.softDarkish),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${changePct.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs last month',
                style: TextStyle(fontSize: 11, color: AppColors.softDarkish),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable(NumberFormat currencyFormat) {
    if (_performance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const EmptyView(
          message: 'Belum ada event dengan data penjualan',
          icon: Icons.bar_chart_outlined,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Event',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softDarkish,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Terjual',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softDarkish,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Revenue',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softDarkish,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._performance.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.eventTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${p.sold} / ${p.quota}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormat.format(p.revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersTable(NumberFormat currencyFormat) {
    if (_recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const EmptyView(
          message: 'Belum ada pesanan masuk',
          icon: Icons.receipt_long_outlined,
        ),
      );
    }

    final dateFormat = DateFormat('d MMM, HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _recentOrders.map((order) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    order.customerName.isNotEmpty
                        ? order.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${order.ticketName} • ${dateFormat.format(order.orderDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.softDarkish,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(order.totalPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
