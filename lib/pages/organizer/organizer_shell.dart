import 'package:bikinevent/pages/my_events_page.dart';
import 'package:bikinevent/pages/organizer/organizer_category_page.dart.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/organizer_drawer.dart';
import '../auth/login_page.dart';
import '../profile_page.dart';
import 'organizer_dashboard_page.dart';
import 'organizer_tickets_page.dart';

class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});

  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  OrganizerPage _currentPage = OrganizerPage.dashboard;
  final _authService = AuthService();
  String? _avatarInitial;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(
        () => _avatarInitial = (profile?.fullName.isNotEmpty ?? false)
            ? profile!.fullName[0].toUpperCase()
            : '?',
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Kamu perlu login kembali untuk mengakses akun ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  String get _pageTitle {
    switch (_currentPage) {
      case OrganizerPage.dashboard:
        return 'Dashboard';
      case OrganizerPage.events:
        return 'Event';
      case OrganizerPage.tickets:
        return 'Tickets';
      case OrganizerPage.category:
        return 'Category';
    }
  }

  Widget get _pageBody {
    switch (_currentPage) {
      case OrganizerPage.dashboard:
        return const OrganizerDashboardPage();
      case OrganizerPage.events:
        return const MyEventsPage();
      case OrganizerPage.tickets:
        return const OrganizerTicketsPage();
      case OrganizerPage.category:
        return const OrganizerCategoryPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  _avatarInitial ?? '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: OrganizerDrawer(
        currentPage: _currentPage,
        onSelect: (page) => setState(() => _currentPage = page),
        onLogout: _handleLogout,
      ),
      body: _pageBody,
    );
  }
}
