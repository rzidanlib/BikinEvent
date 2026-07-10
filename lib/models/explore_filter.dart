enum SortOption { popular, priceLowHigh, priceHighLow, newest }

class ExploreFilter {
  final String? categoryId;
  final SortOption sortBy;

  const ExploreFilter({this.categoryId, this.sortBy = SortOption.newest});

  ExploreFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    SortOption? sortBy,
  }) {
    return ExploreFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}
