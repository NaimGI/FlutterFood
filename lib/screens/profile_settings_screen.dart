import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/api_exception.dart';
import '../services/profile_service.dart';
import '../services/token_storage.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _login.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final isAdmin = await TokenStorage.isAdmin();
      final profile = await ProfileService().getProfile();
      if (!mounted) return;
      _login.text = profile.login;
      await TokenStorage.saveUsername(profile.login);
      setState(() {
        _isAdmin = isAdmin;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!(_profileKey.currentState?.validate() ?? false)) return;
    setState(() => _savingProfile = true);
    try {
      final profile = await ProfileService().updateLogin(_login.text.trim());
      await TokenStorage.saveUsername(profile.login);
      if (!mounted) return;
      _login.text = profile.login;
      AppSnackbar.success(context, 'Profile updated');
    } on ApiException catch (error) {
      if (mounted) AppSnackbar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    setState(() => _changingPassword = true);
    try {
      await ProfileService().changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      AppSnackbar.success(context, 'Password changed');
    } on ApiException catch (error) {
      if (mounted) AppSnackbar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!_isAdmin) ...[
                  _sectionHeading(
                    Icons.person_outline,
                    'Account details',
                    'Update the username shown on your account.',
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _profileKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Username',
                          hint: 'At least 6 characters',
                          controller: _login,
                          validator: (value) {
                            if (value == null || value.trim().length < 6) {
                              return 'Username must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          text: 'SAVE PROFILE',
                          loading: _savingProfile,
                          onPressed: _savingProfile ? null : _saveProfile,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                _sectionHeading(
                  Icons.lock_outline,
                  'Change password',
                  'Choose a new password with at least 6 characters.',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _passwordKey,
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Current password',
                        hint: 'Enter your current password',
                        controller: _currentPassword,
                        isPassword: true,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Current password is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'New password',
                        hint: 'At least 6 characters',
                        controller: _newPassword,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Confirm new password',
                        hint: 'Re-enter the new password',
                        controller: _confirmPassword,
                        isPassword: true,
                        validator: (value) => value != _newPassword.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        text: 'CHANGE PASSWORD',
                        loading: _changingPassword,
                        onPressed: _changingPassword ? null : _changePassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionHeading(IconData icon, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    ],
  );
}
