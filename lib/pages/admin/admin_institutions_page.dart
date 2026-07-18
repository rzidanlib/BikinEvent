import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/institution_model.dart';
import '../../theme/app_colors.dart';

class AdminInstitutionsPage extends StatefulWidget {
  const AdminInstitutionsPage({super.key});

  @override
  State<AdminInstitutionsPage> createState() => _AdminInstitutionsPageState();
}

class _AdminInstitutionsPageState extends State<AdminInstitutionsPage> {
  final _adminService = AdminService();
  List<InstitutionModel> _institutions = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final list = await _adminService.getInstitutions();
      setState(() => _institutions = list);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm({InstitutionModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final domainController = TextEditingController(
      text: existing?.emailDomain ?? '',
    );
    InstitutionLevel selectedLevel = existing?.level ?? InstitutionLevel.sma;
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
                existing == null ? 'Tambah Institusi' : 'Edit Institusi',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Institusi'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InstitutionLevel>(
                initialValue: selectedLevel,
                decoration: const InputDecoration(labelText: 'Jenjang'),
                items: InstitutionLevel.values
                    .map(
                      (l) => DropdownMenuItem(
                        value: l,
                        child: Text(institutionLevelLabel(l)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSheetState(() => selectedLevel = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: domainController,
                decoration: const InputDecoration(
                  labelText: 'Domain Email (opsional)',
                  hintText: 'contoh: sman1bdg.sch.id',
                ),
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
                            await _adminService.createInstitution(
                              name: nameController.text.trim(),
                              level: selectedLevel,
                              emailDomain: domainController.text.trim(),
                            );
                          } else {
                            await _adminService.updateInstitution(
                              id: existing.id,
                              name: nameController.text.trim(),
                              level: selectedLevel,
                              emailDomain: domainController.text.trim(),
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
                    ? const CircularProgressIndicator()
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
      body: _institutions.isEmpty
          ? const EmptyView(
              message: 'Belum ada institusi',
              icon: Icons.school_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _institutions.length,
                itemBuilder: (context, index) {
                  final inst = _institutions[index];
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
                          child: const Icon(
                            Icons.school,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inst.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${institutionLevelLabel(inst.level)}${inst.emailDomain != null ? ' • ${inst.emailDomain}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.softDarkish,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openForm(existing: inst),
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
        label: const Text('Tambah Institusi'),
      ),
    );
  }
}
