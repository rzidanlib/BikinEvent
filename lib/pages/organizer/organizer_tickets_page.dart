import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import '../../services/organizer_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

class OrganizerTicketsPage extends StatefulWidget {
  const OrganizerTicketsPage({super.key});

  @override
  State<OrganizerTicketsPage> createState() => _OrganizerTicketsPageState();
}

class _OrganizerTicketsPageState extends State<OrganizerTicketsPage> {
  final _organizerService = OrganizerService();
  List<TicketTypeModel> _ticketTypes = [];
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
      final types = await _organizerService.getTicketTypes();
      setState(() => _ticketTypes = types);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForm({TicketTypeModel? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
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
                existing == null ? 'Buat Jenis Tiket' : 'Edit Jenis Tiket',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Tiket (misal: VIP, Reguler)',
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
                            await _organizerService.createTicketType(
                              nameController.text.trim(),
                            );
                          } else {
                            await _organizerService.updateTicketType(
                              existing.id,
                              nameController.text.trim(),
                            );
                          }
                          if (context.mounted) Navigator.pop(context);
                          _load();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal: $e')),
                            );
                          }
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
      body: _ticketTypes.isEmpty
          ? const EmptyView(
              message: 'Belum ada jenis tiket',
              icon: Icons.confirmation_number_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ticketTypes.length,
                itemBuilder: (context, index) {
                  final type = _ticketTypes[index];
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
                            Icons.confirmation_number_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            type.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _openForm(existing: type),
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
        label: const Text('Buat Ticket'),
      ),
    );
  }
}
