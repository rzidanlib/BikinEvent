import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/organizer_service.dart';
import '../../models/event_model.dart';

class ManageTicketsPage extends StatefulWidget {
  final String eventId;
  const ManageTicketsPage({super.key, required this.eventId});

  @override
  State<ManageTicketsPage> createState() => _ManageTicketsPageState();
}

class _ManageTicketsPageState extends State<ManageTicketsPage> {
  final _organizerService = OrganizerService();
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
        builder: (context, setSheetState) => Padding(
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
                        (t) => DropdownMenuItem(value: t, child: Text(t.name)),
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
                  decoration: const InputDecoration(labelText: 'Kuota / Stok'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || int.tryParse(v) == null)
                      ? 'Masukkan angka valid'
                      : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate() ||
                              selectedType == null)
                            return;
                          setSheetState(() => isSaving = true);
                          try {
                            await _organizerService.addTicket(
                              eventId: widget.eventId,
                              ticketTypeId: selectedType!.id,
                              ticketTypeName: selectedType!.name,
                              price: double.parse(priceController.text),
                              quota: int.parse(quotaController.text),
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
        ),
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
                    subtitle: Text('Terjual ${ticket.sold} / ${ticket.quota}'),
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
