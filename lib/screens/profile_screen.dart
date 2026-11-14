import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cart_draft.dart';
import '../services/token_storage.dart';
import '../services/delivery_profile_storage.dart';
import '../models/delivery_profile.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _userId;
  bool _isAdmin = false;
  DeliveryProfile? _deliveryProfile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await TokenStorage.readUsername();
    final id = await TokenStorage.readUserId();
    final admin = await TokenStorage.isAdmin();
    final delivery = await DeliveryProfileStorage.read();
    if (!mounted) return;
    setState(() {
      _username = u;
      _userId = id;
      _isAdmin = admin;
      _deliveryProfile = delivery;
    });
  }

  Future<void> _logout() async {
    CartDraft.instance.clear();
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editDeliveryProfile() async {
    final current = _deliveryProfile;
    final phone = TextEditingController(text: current?.phone ?? '');
    final country = TextEditingController(text: current?.country ?? '');
    final city = TextEditingController(text: current?.city ?? '');
    final street = TextEditingController(text: current?.street ?? '');
    final building = TextEditingController(text: current?.building ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showAppSheet<bool>(
      context: context,
      title: 'Delivery information',
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Phone number',
              hint: 'e.g. +216 55 123 456',
              controller: phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Phone is required'
                  : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Country',
              hint: 'e.g. Tunisia',
              controller: country,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Country is required'
                  : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'City',
              hint: 'e.g. Tunis',
              controller: city,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'City is required'
                  : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Street',
              hint: 'e.g. Avenue Habib Bourguiba',
              controller: street,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Street is required'
                  : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Building / apartment',
              hint: 'e.g. Apt 4, 2nd floor',
              controller: building,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Building is required'
                  : null,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Save delivery details',
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final updated = DeliveryProfile(
      phone: phone.text.trim(),
      country: country.text.trim(),
      city: city.text.trim(),
      street: street.text.trim(),
      building: building.text.trim(),
      latitude: current?.latitude,
      longitude: current?.longitude,
    );
    await DeliveryProfileStorage.save(updated);
    if (mounted) setState(() => _deliveryProfile = updated);
    if (mounted) AppSnackbar.success(context, 'Delivery details saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Profile',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF9A4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: .25),
                  child: Text(
                    (_username?.isNotEmpty == true
                            ? _username![0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_username ?? '…',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text(
                          'Account #${_userId ?? '…'} • ${_isAdmin ? 'Admin' : 'Customer'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Username'),
                  subtitle: Text(_username ?? '…'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Account ID'),
                  subtitle: Text(_userId ?? '…'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Role'),
                  subtitle:
                      Text(_isAdmin ? 'Administrator' : 'Customer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              title: const Text('Delivery details', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_deliveryProfile?.isComplete == true
                  ? '${_deliveryProfile!.phone}\n${_deliveryProfile!.addressLabel}'
                  : 'Add once and use automatically at checkout'),
              isThreeLine: _deliveryProfile?.isComplete == true,
              trailing: const Icon(Icons.chevron_right),
              onTap: _editDeliveryProfile,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
