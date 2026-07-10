import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/explore_filter.dart';
import '../theme/app_colors.dart';

Future<ExploreFilter?> showExploreFilterModal(
  BuildContext context, {
  required List<CategoryModel> categories,
  required ExploreFilter current,
}) {
  String? selectedCategoryId = current.categoryId;
  SortOption selectedSort = current.sortBy;

  return showModalBottomSheet<ExploreFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () => setSheetState(() {
                    selectedCategoryId = null;
                    selectedSort = SortOption.newest;
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  'Semua',
                  selectedCategoryId == null,
                  () => setSheetState(() => selectedCategoryId = null),
                ),
                ...categories.map(
                  (c) => _chip(
                    c.name,
                    selectedCategoryId == c.id,
                    () => setSheetState(() => selectedCategoryId = c.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._sortLabels.entries.map(
              (entry) => RadioListTile<SortOption>(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                value: entry.key,
                groupValue: selectedSort,
                activeColor: AppColors.primary,
                onChanged: (v) => setSheetState(() => selectedSort = v!),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                ExploreFilter(
                  categoryId: selectedCategoryId,
                  sortBy: selectedSort,
                ),
              ),
              child: const Text('Terapkan Filter'),
            ),
          ],
        ),
      ),
    ),
  );
}

const _sortLabels = {
  SortOption.newest: 'Terbaru',
  SortOption.popular: 'Paling Populer',
  SortOption.priceLowHigh: 'Harga: Rendah ke Tinggi',
  SortOption.priceHighLow: 'Harga: Tinggi ke Rendah',
};

Widget _chip(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textBlack,
        ),
      ),
    ),
  );
}
