import 'package:bikinevent/models/institution_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/organizer_service.dart';
import '../../services/event_service.dart'; // tambahkan ini
import '../../models/event_model.dart';
import '../../models/institution_model.dart'; // tambahkan ini
import '../../theme/app_colors.dart';

class ManageTicketsPage extends StatefulWidget {
  final String eventId;
  const ManageTicketsPage({super.key, required this.eventId});

  @override
  State<ManageTicketsPage> createState() => _ManageTicketsPageState();
}

class _ManageTicketsPageState extends State<ManageTicketsPage> {
  final _organizerService = OrganizerService();
  final _eventService = EventService();
  List<TicketModel> _tickets = [];
  List<TicketTypeModel> _ticketTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _loadTicketTypes();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _organizerService.getEventTickets(widget.eventId);
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  Future<void> _loadTicketTypes() async {
    final types = await _organizerService.getTicketTypes();
    setState(() => _ticketTypes = types);
  }

  void _showAddTicketSheet() {
    TicketTypeModel? selectedType = _ticketTypes.isNotEmpty
        ? _ticketTypes.first
        : null;
    final priceController = TextEditingController();
    final quotaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    TicketRestriction selectedRestriction = TicketRestriction.none;
    List<InstitutionModel> allInstitutions = [];
    String? selectedInstitutionId;
    bool isLoadingInstitutions = false;

    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada jenis tiket. Buat dulu lewat menu Tickets di sidebar.',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Load institusi cuma sekali, saat pertama kali dropdown institution_only dipilih
          Future<void> loadInstitutionsIfNeeded() async {
            if (allInstitutions.isNotEmpty || isLoadingInstitutions) return;
            setSheetState(() => isLoadingInstitutions = true);
            final list = await _eventService
                .getAllInstitutions(); // ganti dari getInstitutionsByLevel(InstitutionLevel.sma)
            setSheetState(() {
              allInstitutions = list;
              isLoadingInstitutions = false;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tambah Tiket ke Event',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TicketTypeModel>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Jenis Tiket'),
                    items: _ticketTypes
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.name)),
                        )
                        .toList(),
                    onChanged: (v) => setSheetState(() => selectedType = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || double.tryParse(v) == null)
                        ? 'Masukkan angka valid'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quotaController,
                    decoration: const InputDecoration(
                      labelText: 'Kuota / Stok',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || int.tryParse(v) == null)
                        ? 'Masukkan angka valid'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Batasan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TicketRestriction>(
                    initialValue: selectedRestriction,
                    decoration: const InputDecoration(
                      labelText: 'Siapa yang boleh beli tiket ini?',
                    ),
                    items: TicketRestriction.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(ticketRestrictionLabel(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setSheetState(() {
                        selectedRestriction = v!;
                        selectedInstitutionId = null;
                      });
                      if (v == TicketRestriction.institutionOnly) {
                        loadInstitutionsIfNeeded();
                      }
                    },
                  ),

                  if (selectedRestriction ==
                      TicketRestriction.institutionOnly) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedInstitutionId,
                      decoration: InputDecoration(
                        labelText: 'Pilih Institusi',
                        suffixIcon: isLoadingInstitutions
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      items: allInstitutions
                          .map(
                            (i) => DropdownMenuItem(
                              value: i.id,
                              child: Text(
                                '${i.name} (${institutionLevelLabel(i.level)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedInstitutionId = v),
                    ),
                  ],

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate() ||
                                selectedType == null)
                              return;
                            if (selectedRestriction ==
                                    TicketRestriction.institutionOnly &&
                                selectedInstitutionId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih institusi dulu'),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              await _organizerService.addTicket(
                                eventId: widget.eventId,
                                ticketTypeId: selectedType!.id,
                                ticketTypeName: selectedType!.name,
                                price: double.parse(priceController.text),
                                quota: int.parse(quotaController.text),
                                restrictionType: selectedRestriction,
                                restrictionInstitutionId: selectedInstitutionId,
                              );
                              if (context.mounted) Navigator.pop(context);
                              _loadTickets();
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
                        ? const CircularProgressIndicator()
                        : const Text('Simpan Tiket'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Tiket Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
          ? const Center(
              child: Text('Belum ada jenis tiket. Tambahkan sekarang.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return Card(
                  child: ListTile(
                    title: Text(ticket.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terjual ${ticket.sold} / ${ticket.quota}'),
                        if (ticket.restrictionType != TicketRestriction.none)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ticket.restrictionType ==
                                      TicketRestriction.institutionOnly
                                  ? 'Khusus ${ticket.restrictionInstitutionName ?? "-"}'
                                  : 'Khusus Pelajar & Mahasiswa',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      currencyFormat.format(ticket.price),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTicketSheet,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tiket'),
      ),
    );
  }
}
