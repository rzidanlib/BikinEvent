import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/organizer_service.dart';
import '../../models/organizer_ticket_model.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

class OrganizerTicketsPage extends StatefulWidget {
  const OrganizerTicketsPage({super.key});

  @override
  State<OrganizerTicketsPage> createState() => _OrganizerTicketsPageState();
}

class _OrganizerTicketsPageState extends State<OrganizerTicketsPage> {
  final _organizerService = OrganizerService();
  List<OrganizerTicketItem> _tickets = [];
  List<EventModel> _events = [];
  String? _selectedCategory;
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
      final raw = await _organizerService.getAllTicketsRaw();
      final events = await _organizerService.getMyEvents();
      setState(() {
        _tickets = raw.map((j) => OrganizerTicketItem.fromJson(j)).toList();
        _events = events;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final set = _tickets.map((t) => t.category).toSet().toList()..sort();
    return set;
  }

  List<OrganizerTicketItem> get _filtered => _selectedCategory == null
      ? _tickets
      : _tickets.where((t) => t.category == _selectedCategory).toList();

  void _openForm({OrganizerTicketItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _TicketFormSheet(events: _events, existing: existing, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _load);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _catChip(null, 'Semua'),
                        ..._categories.map((c) => _catChip(c, c)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _events.isEmpty ? null : () => _openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Tiket'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyView(
                    message: 'Belum ada tiket',
                    icon: Icons.confirmation_number_outlined,
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) =>
                          _ticketCard(_filtered[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(String? value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textBlack,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        onSelected: (_) => setState(() => _selectedCategory = value),
      ),
    );
  }

  Widget _ticketCard(OrganizerTicketItem ticket) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () => _openForm(existing: ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.eventTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.softDarkish,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ticket.sold} / ${ticket.quota} terjual',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        currencyFormat.format(ticket.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketFormSheet extends StatefulWidget {
  final List<EventModel> events;
  final OrganizerTicketItem? existing;
  final VoidCallback onSaved;

  const _TicketFormSheet({
    required this.events,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_TicketFormSheet> createState() => _TicketFormSheetState();
}

class _TicketFormSheetState extends State<_TicketFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _organizerService = OrganizerService();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _quotaController;
  String? _selectedEventId;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _priceController = TextEditingController(
      text: e != null ? e.price.toStringAsFixed(0) : '',
    );
    _quotaController = TextEditingController(
      text: e != null ? e.quota.toString() : '',
    );
    _selectedEventId =
        e?.eventId ??
        (widget.events.isNotEmpty ? widget.events.first.id : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        await _organizerService.updateTicket(
          ticketId: widget.existing!.id,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text),
          quota: int.parse(_quotaController.text),
        );
      } else {
        await _organizerService.createTicket(
          eventId: _selectedEventId!,
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          price: double.parse(_priceController.text),
          quota: int.parse(_quotaController.text),
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit Tiket' : 'Buat Tiket Baru',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (!_isEdit) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedEventId,
                decoration: const InputDecoration(labelText: 'Event'),
                items: widget.events
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.id, child: Text(e.title)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedEventId = v),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Tiket (misal: VIP Awal)',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Kategori (misal: VIP, Reguler)',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Harga (Rp)'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? 'Masukkan angka valid'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quotaController,
              decoration: const InputDecoration(labelText: 'Kuota'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || int.tryParse(v) == null)
                  ? 'Masukkan angka valid'
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Tiket'),
            ),
          ],
        ),
      ),
    );
  }
}
