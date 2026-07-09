import 'dart:io';
import 'package:bikinevent/pages/manage_ticket_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/organizer_service.dart';
import '../../services/event_service.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';

class CreateEventPage extends StatefulWidget {
  final String? eventId; // null = mode create, terisi = mode edit

  const CreateEventPage({super.key, this.eventId});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _organizerService = OrganizerService();
  final _eventService = EventService();

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  DateTime? _selectedDate;
  bool _isPublic = true;
  File? _posterFile;
  String? _existingPosterUrl; // untuk mode edit, sebelum ada file baru dipilih
  bool _isLoading = false;
  bool _isLoadingInitial = true;

  bool get _isEditMode => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final categories = await _eventService.getCategories();
    setState(() => _categories = categories);

    if (_isEditMode) {
      final event = await _eventService.getEventDetail(widget.eventId!);
      setState(() {
        _titleController.text = event.title;
        _locationController.text = event.location;
        _descController.text = event.description ?? '';
        _selectedCategoryId = event.categoryId;
        _selectedDate = event.eventDate;
        _isPublic = event.isPublic;
        _existingPosterUrl = event.posterUrl;
      });
    }
    setState(() => _isLoadingInitial = false);
  }

  Future<void> _pickPoster() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _posterFile = File(picked.path));
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDate != null
          ? TimeOfDay.fromDateTime(_selectedDate!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal & waktu event')),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih tipe event')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? posterUrl;
      if (_posterFile != null) {
        posterUrl = await _organizerService.uploadPoster(_posterFile!);
      }

      if (_isEditMode) {
        await _organizerService.updateEvent(
          eventId: widget.eventId!,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          eventDate: _selectedDate!,
          categoryId: _selectedCategoryId!,
          isPublic: _isPublic,
          posterUrl: posterUrl, // null berarti poster lama dipertahankan
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perubahan berhasil disimpan')),
          );
          Navigator.pop(context);
        }
      } else {
        final eventId = await _organizerService.createEvent(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          eventDate: _selectedDate!,
          categoryId: _selectedCategoryId!,
          isPublic: _isPublic,
          posterUrl: posterUrl,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Event berhasil dibuat! Sekarang tambahkan jenis tiket.',
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ManageTicketsPage(eventId: eventId),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Event' : 'Create New Event'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildCoverPhotoBox(),
            const SizedBox(height: 28),

            const Text(
              'Event Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 16),

            _labeledField(
              label: 'Event Name',
              required: true,
              child: TextFormField(
                controller: _titleController,
                decoration: _fieldDecoration('Type your event name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 18),

            _labeledField(
              label: 'Location',
              required: true,
              child: TextFormField(
                controller: _locationController,
                decoration: _fieldDecoration('Type event location'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 18),

            _labeledField(
              label: 'Event Type',
              required: true,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: _fieldDecoration('Choose event type'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategoryId = value),
              ),
            ),
            const SizedBox(height: 18),

            _labeledField(
              label: 'Select Date and Time',
              required: true,
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: _fieldDecoration('Choose event Date').copyWith(
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: AppColors.softDarkish,
                    ),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? ''
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • ${TimeOfDay.fromDateTime(_selectedDate!).format(context)}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            _labeledField(
              label: 'Event Visibility',
              required: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey2),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _isPublic ? 'Publik (terbuka untuk umum)' : 'Khusus',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ),
            ),
            const SizedBox(height: 18),

            _labeledField(
              label: 'Event Description',
              required: true,
              child: TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: _fieldDecoration('Type your event description...'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_isEditMode ? 'SAVE CHANGES' : 'PUBLISH NOW'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPhotoBox() {
    final hasImage = _posterFile != null || _existingPosterUrl != null;

    return GestureDetector(
      onTap: _pickPoster,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.4,
          ),
          image: _posterFile != null
              ? DecorationImage(
                  image: FileImage(_posterFile!),
                  fit: BoxFit.cover,
                )
              : (_existingPosterUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_existingPosterUrl!),
                        fit: BoxFit.cover,
                      )
                    : null),
        ),
        child: hasImage
            ? Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 32, color: AppColors.primary),
                    SizedBox(height: 6),
                    Text(
                      'Add Cover Photos',
                      style: TextStyle(color: AppColors.softDarkish),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required bool required,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: AppColors.textBlack,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
