import 'dart:io';
import 'package:bikinevent/widgets/state_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/checkout_service.dart';
import '../services/favorite_service.dart';
import '../models/profile_model.dart';
import '../models/order_model.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/ticket_list_card.dart';
import '../widgets/ticket_detail_modal.dart';
import '../widgets/event_card_compact.dart';
import 'auth/login_page.dart';
import 'event_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _isUploadingAvatar = false;
  Profile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _authService.getProfile();
      setState(() => _profile = profile);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatarFromRoot() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await _authService.uploadAvatar(File(picked.path));
      await _loadProfile();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView());
    if (_errorMessage != null)
      return Scaffold(
        body: ErrorView(message: _errorMessage!, onRetry: _loadProfile),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          _buildAvatarHeader(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.softDarkish,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Events'),
              Tab(text: 'Favorites'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProfileInfoTab(
                  profile: _profile,
                  onProfileUpdated: _loadProfile,
                ),
                const _MyEventsTab(),
                const _FavoritesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    // Dipindahkan dari dalam _ProfileInfoTab -- sekarang jadi header bersama di atas semua tab
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _profile?.avatarUrl != null
                    ? NetworkImage(_profile!.avatarUrl!)
                    : null,
                child: _profile?.avatarUrl == null
                    ? Text(
                        (_profile?.fullName.isNotEmpty ?? false)
                            ? _profile!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAvatarFromRoot,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              _profile?.fullName ?? '-',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTab extends StatefulWidget {
  final Profile? profile;
  final VoidCallback onProfileUpdated;

  const _ProfileInfoTab({
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<_ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<_ProfileInfoTab> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile?.fullName ?? '';
    _phoneController.text = widget.profile?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await _authService.uploadAvatar(File(picked.path));
      widget.onProfileUpdated();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        setState(() => _isEditing = false);
        widget.onProfileUpdated();
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

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Kamu perlu login kembali untuk mengakses akun ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(_isEditing ? 'Batal' : 'Edit Profil'),
          ),
        ),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nama Lengkap',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _isEditing
                  ? AppTextField(
                      controller: _nameController,
                      hintText: 'Nama lengkap',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    )
                  : _readOnlyField(
                      profile?.fullName ?? '-',
                      Icons.person_outline,
                    ),
              const SizedBox(height: 16),

              const Text(
                'Nomor HP',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _isEditing
                  ? AppTextField(
                      controller: _phoneController,
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    )
                  : _readOnlyField(
                      (profile?.phone?.isNotEmpty ?? false)
                          ? profile!.phone!
                          : 'Belum diisi',
                      Icons.phone_outlined,
                    ),
              const SizedBox(height: 16),

              const Text(
                'Email',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _readOnlyField(
                _authService.currentUser?.email ?? '-',
                Icons.mail_outline,
              ),

              if (_isEditing) ...[
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
                      : const Text('Simpan'),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 40),
        if (!(profile?.isOrganizer ?? false)) ...[
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text(
              'Keluar Akun',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _readOnlyField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.grey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.softDarkish, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MyEventsTab extends StatefulWidget {
  const _MyEventsTab();

  @override
  State<_MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<_MyEventsTab> {
  final _checkoutService = CheckoutService();
  List<MyTicketItem> _tickets = [];
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
      final raw = await _checkoutService.getMyTickets();
      setState(
        () => _tickets = raw.map((j) => MyTicketItem.fromJson(j)).toList(),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _load);

    // Grup unik per event -- 1 event cukup 1 kartu meski tiketnya dibeli berkali-kali
    final uniqueEvents = <String, MyTicketItem>{};
    for (final t in _tickets) {
      uniqueEvents[t.eventId] = t;
    }
    final list = uniqueEvents.values.toList();

    if (list.isEmpty)
      return const EmptyView(
        message: 'Kamu belum mengikuti event apapun',
        icon: Icons.event_busy_outlined,
      );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          final dateFormat = DateFormat('d MMMM, yy');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(eventId: item.eventId),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.eventTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(item.eventDate)} • ${item.eventLocation}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.softDarkish,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.softDarkish),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoritesTab extends StatefulWidget {
  const _FavoritesTab();

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  final _favoriteService = FavoriteService();
  List<EventModel> _events = [];
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
      final events = await _favoriteService.getFavoriteEvents();
      setState(() => _events = events);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null)
      return ErrorView(message: _errorMessage!, onRetry: _load);
    if (_events.isEmpty)
      return const EmptyView(
        message: 'Belum ada event favorit',
        icon: Icons.favorite_border,
      );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return EventCardCompact(
            event: event,
            lowestPrice: event.lowestPrice,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(eventId: event.id),
              ),
            ).then((_) => _load()),
          );
        },
      ),
    );
  }
}
