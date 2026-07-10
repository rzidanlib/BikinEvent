import 'package:bikinevent/services/favorite_service.dart';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import '../models/explore_filter.dart';
import '../theme/app_colors.dart';
import '../widgets/pill_search_bar.dart';
import '../widgets/event_card_compact.dart';
import '../widgets/event_card_large.dart';
import '../widgets/explore_filter_modal.dart';
import 'event_detail_page.dart';

class ExplorePage extends StatefulWidget {
  final ExploreFilter? initialFilter;
  final String? initialQuery; // baru

  const ExplorePage({super.key, this.initialFilter, this.initialQuery});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _eventService = EventService();
  final _searchController = TextEditingController();
  final _favoriteService = FavoriteService();

  Set<String> _favoriteIds = {};
  List<EventModel> _allEvents = [];
  List<CategoryModel> _categories = [];
  late ExploreFilter _filter;
  bool _isGridView = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? const ExploreFilter();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    _loadFavorites();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final events = await _eventService.getEvents();
      final categories = await _eventService.getCategories();
      setState(() {
        _allEvents = events;
        _categories = categories;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  List<EventModel> get _result {
    var list = [..._allEvents];

    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      list = list
          .where((e) => e.title.toLowerCase().contains(keyword))
          .toList();
    }

    if (_filter.categoryId != null) {
      list = list.where((e) => e.categoryId == _filter.categoryId).toList();
    }

    switch (_filter.sortBy) {
      case SortOption.popular:
        list.sort((a, b) => b.totalSold.compareTo(a.totalSold));
        break;
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.lowestPrice.compareTo(b.lowestPrice));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.lowestPrice.compareTo(a.lowestPrice));
        break;
      case SortOption.newest:
        list.sort((a, b) => b.eventDate.compareTo(a.eventDate));
        break;
    }

    return list;
  }

  Future<void> _openFilterModal() async {
    final result = await showExploreFilterModal(
      context,
      categories: _categories,
      current: _filter,
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Explore'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: PillSearchBar(
                    controller: _searchController,
                    dark: false,
                    onChanged: (_) => setState(() {}),
                    onFilterTap: _openFilterModal,
                  ),
                ),
                const SizedBox(width: 10),
                _toggleViewButton(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const LoadingView()
                  : _errorMessage != null
                  ? ErrorView(message: _errorMessage!, onRetry: _load)
                  : _result.isEmpty
                  ? const EmptyView(
                      message: 'Tidak ada event ditemukan',
                      icon: Icons.event_busy,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _isGridView
                          ? _buildLargeList()
                          : _buildCompactList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleViewButton() {
    return GestureDetector(
      onTap: () => setState(() => _isGridView = !_isGridView),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _isGridView ? Icons.view_list_outlined : Icons.grid_view_rounded,
          color: AppColors.textBlack,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCompactList() {
    final list = _result;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final event = list[index];
        return EventCardCompact(
          event: event,
          lowestPrice: event.lowestPrice,
          onTap: () => _openDetail(event),
        );
      },
    );
  }

  Widget _buildLargeList() {
    final list = _result;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final event = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EventCardLarge(
            event: event,
            lowestPrice: event.lowestPrice,
            soldCount: event.totalSold,
            isFavorite: _favoriteIds.contains(event.id),
            onFavoriteTap: () => _toggleFavorite(event),
            onTap: () => _openDetail(event),
          ),
        );
      },
    );
  }

  void _openDetail(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
    );
  }
}
