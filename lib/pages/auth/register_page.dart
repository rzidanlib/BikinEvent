import 'package:bikinevent/models/institution_model.dart';
import 'package:bikinevent/services/event_service.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/social_login_row.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _eventService = EventService();
  final _studentNumberController = TextEditingController();

  String _statusType = 'umum'; // 'umum' atau 'pelajar_mahasiswa'
  InstitutionLevel? _selectedEducationLevel;
  List<InstitutionModel> _institutions = [];
  String? _selectedInstitutionId;
  bool _isLoadingInstitutions = false;
  String _selectedRole = 'user';
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onEducationLevelChanged(InstitutionLevel? level) async {
    setState(() {
      _selectedEducationLevel = level;
      _selectedInstitutionId = null;
      _institutions = [];
    });
    if (level == null) return;

    setState(() => _isLoadingInstitutions = true);
    try {
      final list = await _eventService.getInstitutionsByLevel(level);
      setState(() => _institutions = list);
    } finally {
      if (mounted) setState(() => _isLoadingInstitutions = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    if (_statusType == 'pelajar_mahasiswa') {
      if (_selectedEducationLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenjang pendidikan')),
        );
        return;
      }
      if (_selectedInstitutionId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih institusi')));
        return;
      }
      if (_studentNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor induk wajib diisi')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        statusType: _statusType,
        educationLevel: _statusType == 'pelajar_mahasiswa'
            ? _selectedEducationLevel!.name
            : null,
        institutionId: _statusType == 'pelajar_mahasiswa'
            ? _selectedInstitutionId
            : null,
        studentNumber: _statusType == 'pelajar_mahasiswa'
            ? _studentNumberController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registrasi berhasil! Silakan cek email untuk verifikasi.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal daftar: ${e.toString()}')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create account and enjoy all services',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.softDarkish, fontSize: 14),
                ),
                const SizedBox(height: 28),

                AppTextField(
                  controller: _nameController,
                  hintText: 'Type your full name',
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailController,
                  hintText: 'Type your email',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email tidak valid'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Type your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Type your confirm password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Pemilihan role — didesain sebagai segmented toggle
                // supaya tetap ringkas & konsisten dengan gaya visual referensi
                Text(
                  'Daftar sebagai',
                  style: TextStyle(
                    color: AppColors.softDarkish,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _roleOption(
                        'user',
                        'Peserta / Umum',
                        Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _roleOption(
                        'organizer',
                        'Panitia',
                        Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  'Status',
                  style: TextStyle(
                    color: AppColors.softDarkish,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _statusOption('umum', 'Umum', Icons.public),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statusOption(
                        'pelajar_mahasiswa',
                        'Pelajar/Mahasiswa',
                        Icons.school,
                      ),
                    ),
                  ],
                ),

                if (_statusType == 'pelajar_mahasiswa') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<InstitutionLevel>(
                    initialValue: _selectedEducationLevel,
                    decoration: const InputDecoration(
                      labelText: 'Jenjang Pendidikan',
                    ),
                    items: InstitutionLevel.values
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(institutionLevelLabel(l)),
                          ),
                        )
                        .toList(),
                    onChanged: _onEducationLevelChanged,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedInstitutionId,
                    decoration: InputDecoration(
                      labelText: 'Institusi',
                      suffixIcon: _isLoadingInstitutions
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                    items: _institutions
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(i.name),
                          ),
                        )
                        .toList(),
                    onChanged: _selectedEducationLevel == null
                        ? null
                        : (v) => setState(() => _selectedInstitutionId = v),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _studentNumberController,
                    hintText: 'Nomor Induk (NISN/NIM)',
                    prefixIcon: Icons.badge_outlined,
                  ),
                ],
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('SIGN UP'),
                ),
                const SizedBox(height: 32),

                const SocialLoginRow(),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusOption(String value, String label, IconData icon) {
    final isSelected = _statusType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _statusType = value;
        if (value == 'umum') {
          _selectedEducationLevel = null;
          _selectedInstitutionId = null;
          _institutions = [];
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.softDarkish,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.softDarkish,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleOption(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.grey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.softDarkish,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.softDarkish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
