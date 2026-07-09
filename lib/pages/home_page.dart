import 'package:bikinevent/pages/calendar_page.dart';
import 'package:bikinevent/pages/my_tickets.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import '../models/profile_model.dart';
import '../theme/app_colors.dart';
import '../widgets/pill_search_bar.dart';
import '../widgets/event_card_large.dart';
import '../widgets/event_card_compact.dart';
import 'event_detail_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: const [
          _EventListView(),
          CalendarPage(),
          MyTicketsPage(),
          _LocationPlaceholder(), // Step 22 nanti diisi lengkap
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentNavIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Location',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder sementara untuk tab Location, diisi lengkap nanti
class _LocationPlaceholder extends StatelessWidget {
  const _LocationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Location (segera hadir)')));
  }
}

class _EventListView extends StatefulWidget {
  const _EventListView();

  @override
  State<_EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<_EventListView> {
  final _eventService = EventService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<EventModel> _events = [];
  Profile? _profile;
  String? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _authService.getProfile();
      final categories = await _eventService.getCategories();
      final events = await _eventService.getEvents(
        categoryId: _selectedCategoryId,
      );
      setState(() {
        _profile = profile;
        _categories = categories;
        _events = events;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadData();
  }

  List<EventModel> get _filteredBySearch {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return _events;
    return _events
        .where((e) => e.title.toLowerCase().contains(keyword))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isLoading)
              const SliverFillRemaining(child: LoadingView())
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: ErrorView(message: _errorMessage!, onRetry: _loadData),
              )
            else ...[
              SliverToBoxAdapter(child: _buildPopularEvents()),
              SliverToBoxAdapter(child: _buildCategorySection()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: _buildFilteredList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (_profile?.fullName.isNotEmpty ?? false)
                        ? _profile!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hi Welcome 👋',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _profile?.fullName ?? 'Peserta',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PillSearchBar(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              dark: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularEvents() {
    // "Popular" didefinisikan sederhana: event dengan tiket terjual terbanyak
    final popular = [..._events]
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    final topEvents = popular.take(5).toList();

    if (topEvents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Popular Events 🔥',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'VIEW ALL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 256,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topEvents.length,
              itemBuilder: (context, index) {
                final event = topEvents[index];
                return EventCardLarge(
                  event: event,
                  lowestPrice: event.lowestPrice,
                  soldCount: event.totalSold,
                  onTap: () => _openDetail(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose By Category ✨',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip(null, 'Semua', Icons.apps),
                ..._categories.map(
                  (c) => _categoryChip(
                    c.id,
                    c.name,
                    categoryIconFromString(c.icon),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String? id, String label, IconData icon) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _onCategorySelected(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.grey,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.softDarkish,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredList() {
    final list = _filteredBySearch;

    if (list.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: EmptyView(
            message: 'Tidak ada event ditemukan',
            icon: Icons.event_busy,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = list[index];
        return EventCardCompact(
          event: event,
          lowestPrice: event.lowestPrice,
          onTap: () => _openDetail(event),
        );
      }, childCount: list.length),
    );
  }

  void _openDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
    );
  }
}
