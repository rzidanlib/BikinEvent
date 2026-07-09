import 'package:bikinevent/pages/create_event_page.dart';
import 'package:bikinevent/pages/my_events_page.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/organizer_service.dart';
import '../../theme/app_colors.dart';

class OrganizerDashboardPage extends StatefulWidget {
  const OrganizerDashboardPage({super.key});

  @override
  State<OrganizerDashboardPage> createState() => _OrganizerDashboardPageState();
}

class _OrganizerDashboardPageState extends State<OrganizerDashboardPage> {
  final _organizerService = OrganizerService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final stats = await _organizerService.getDashboardStats();
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView());
    if (_errorMessage != null) {
      return Scaffold(
        body: ErrorView(message: _errorMessage!, onRetry: _loadStats),
      );
    }

    final stats = _stats!;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final nextEvent = stats['nextEvent'];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Grid ringkasan statistik
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _statCard(
                  'Total Event',
                  '${stats['totalEvents']}',
                  Icons.event,
                  AppColors.primary,
                ),
                _statCard(
                  'Event Mendatang',
                  '${stats['upcomingCount']}',
                  Icons.upcoming,
                  AppColors.blue,
                ),
                _statCard(
                  'Tiket Terjual',
                  '${stats['totalSold']}',
                  Icons.confirmation_number,
                  AppColors.green,
                ),
                _statCard(
                  'Total Pendapatan',
                  currencyFormat.format(stats['totalRevenue']),
                  Icons.payments,
                  AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Akses Cepat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.add_box_outlined,
                    label: 'Buat Event',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateEventPage(),
                        ),
                      );
                      _loadStats();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.dashboard_outlined,
                    label: 'Kelola Event',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyEventsPage()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (nextEvent != null) ...[
              const Text(
                'Event Terdekat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.grey,
                    child: Icon(Icons.event, color: AppColors.primary),
                  ),
                  title: Text(nextEvent['title']),
                  subtitle: Text(
                    DateFormat(
                      'd MMM yyyy, HH:mm',
                    ).format(DateTime.parse(nextEvent['event_date'])),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyEventsPage()),
                  ),
                ),
              ),
            ] else
              const EmptyView(
                message:
                    'Belum ada event mendatang.\nYuk buat event pertamamu!',
                icon: Icons.event_available_outlined,
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.softDarkish),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
