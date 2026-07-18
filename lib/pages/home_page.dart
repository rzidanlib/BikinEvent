import 'package:bikinevent/models/explore_filter.dart';
import 'package:bikinevent/pages/calendar_page.dart';
import 'package:bikinevent/pages/explore_page.dart';
import 'package:bikinevent/pages/location_page.dart';
import 'package:bikinevent/pages/my_tickets.dart';
import 'package:bikinevent/services/favorite_service.dart';
import 'package:bikinevent/services/location_service.dart';
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
          LocationPage(), // Step 22 nanti diisi lengkap
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
  final _locationService = LocationService();
  final _favoriteService = FavoriteService();

  Set<String> _favoriteIds = {};
  String? _locationLabel;
  List<CategoryModel> _categories = [];
  List<EventModel> _allEvents = [];
  Profile? _profile;
  String? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;
  List<EventModel> _campusEvents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFavorites();
    _loadLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null || !mounted) return;

    final city = await _locationService.getCityName(position);
    if (mounted && city != null) {
      setState(() => _locationLabel = city);
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _authService.getProfile();
      final categories = await _eventService.getCategories();
      final events = await _eventService.getEvents();
      final campusEvents = profile?.statusType == 'pelajar_mahasiswa'
          ? await _eventService.getCampusEvents()
          : <EventModel>[];
      setState(() {
        _profile = profile;
        _categories = categories;
        _allEvents = events;
        _campusEvents = campusEvents;
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

  Future<void> _loadFavorites() async {
    final favorites = await _favoriteService.getFavoriteEvents();
    if (mounted)
      setState(() => _favoriteIds = favorites.map((e) => e.id).toSet());
  }

  Future<void> _toggleFavorite(EventModel event) async {
    final isFav = _favoriteIds.contains(event.id);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(event.id);
      } else {
        _favoriteIds.add(event.id);
      }
    });
    try {
      await _favoriteService.toggleFavorite(event.id, isFav);
    } catch (_) {
      // rollback kalau gagal
      setState(() {
        if (isFav) {
          _favoriteIds.add(event.id);
        } else {
          _favoriteIds.remove(event.id);
        }
      });
    }
  }

  // Popular TIDAK terpengaruh kategori yang dipilih -- selalu dari _allEvents utuh
  List<EventModel> get _popularEvents {
    final sorted = [..._allEvents]
      ..sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return sorted.take(5).toList();
  }

  // List Explore bawah TERPENGARUH kategori + pencarian
  List<EventModel> get _exploreList {
    var list = [..._allEvents];
    if (_selectedCategoryId != null) {
      list = list.where((e) => e.categoryId == _selectedCategoryId).toList();
    }
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      list = list
          .where((e) => e.title.toLowerCase().contains(keyword))
          .toList();
    }
    return list;
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
              SliverToBoxAdapter(child: _buildCampusEvents()),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (_locationLabel != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Current location',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Row(
                        children: [
                          Text(
                            _locationLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PillSearchBar(
              controller: _searchController,
              dark: true,
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExplorePage(initialQuery: value.trim()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularEvents() {
    final topEvents = _popularEvents;
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
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExplorePage(
                        initialFilter: ExploreFilter(
                          sortBy: SortOption.popular,
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 315,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topEvents.length,
              itemBuilder: (context, index) {
                final event = topEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 260,
                    child: EventCardLarge(
                      event: event,
                      lowestPrice: event.lowestPrice,
                      soldCount: event.totalSold,
                      isFavorite: _favoriteIds.contains(event.id),
                      onFavoriteTap: () => _toggleFavorite(event),
                      onTap: () => _openDetail(event),
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

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Explore',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExplorePage()),
                  ),
                  child: Text(
                    'VIEW ALL',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildCampusEvents() {
    if (_campusEvents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Event Khusus Kamu',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _campusEvents.length,
              itemBuilder: (context, index) {
                final event = _campusEvents[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 14, left: 0),
                  child: SizedBox(
                    width: 260,
                    child: EventCardLarge(
                      event: event,
                      lowestPrice: event.lowestPrice,
                      soldCount: event.totalSold,
                      isFavorite: _favoriteIds.contains(event.id),
                      onFavoriteTap: () => _toggleFavorite(event),
                      onTap: () => _openDetail(event),
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
    final list = _exploreList;

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
