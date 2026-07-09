import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../../services/event_service.dart';
import '../../services/organizer_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

class OrganizerCategoryPage extends StatefulWidget {
  const OrganizerCategoryPage({super.key});

  @override
  State<OrganizerCategoryPage> createState() => _OrganizerCategoryPageState();
}

class _OrganizerCategoryPageState extends State<OrganizerCategoryPage> {
  final _eventService = EventService();
  final _organizerService = OrganizerService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _iconOptions = {
    'mic': Icons.mic,
    'music_note': Icons.music_note,
    'sports_soccer': Icons.sports_soccer,
    'storefront': Icons.storefront,
    'build': Icons.build,
    'category': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _eventService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm({CategoryModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    String selectedIcon = existing?.icon ?? 'category';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Buat Kategori' : 'Edit Kategori',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kategori'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Icon',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _iconOptions.entries.map((entry) {
                  final isSelected = selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedIcon = entry.key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected
                            ? Colors.white
                            : AppColors.softDarkish,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) return;
                        setSheetState(() => isSaving = true);
                        try {
                          if (existing == null) {
                            await _organizerService.createCategory(
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                            );
                          } else {
                            await _organizerService.updateCategory(
                              id: existing.id,
                              name: nameController.text.trim(),
                              icon: selectedIcon,
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                          _load();
                        } catch (e) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')),
                            );
                          setSheetState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _load);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _categories.isEmpty
          ? const EmptyView(
              message: 'Belum ada kategori',
              icon: Icons.category_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            categoryIconFromString(category.icon),
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openForm(existing: category),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Buat Kategori'),
      ),
    );
  }
}
