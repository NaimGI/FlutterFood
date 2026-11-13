import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../services/address_service.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/cart_draft.dart';
import '../services/profile_service.dart';
import '../services/token_storage.dart';
import '../services/delivery_profile_storage.dart';
import '../models/delivery_profile.dart';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'saved_locations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _userId;
  bool _isAdmin = false;
  int _locationCount = 0;
  double? _totalSpent;
  String? _loadError;
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
    try {
      final profile = await ProfileService().getProfile();
      await TokenStorage.saveUsername(profile.login);
      await TokenStorage.saveUserId(profile.id.toString());
      final addresses = await AddressService().getMine();
      if (!mounted) return;
      setState(() {
        _username = profile.login;
        _userId = profile.id.toString();
        _isAdmin = admin;
        _locationCount = addresses.length;
        _totalSpent = profile.totalSpent;
        _deliveryProfile = delivery;
        _loadError = null;
      });
      return;
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.message);
    }
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
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              TextField(
                controller: country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              TextField(
                controller: street,
                decoration: const InputDecoration(labelText: 'Street'),
              ),
              TextField(
                controller: building,
                decoration: const InputDecoration(
                  labelText: 'Building / apartment',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
                    (_username?.isNotEmpty == true ? _username![0] : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username ?? '…',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Account #${_userId ?? '…'} • ${_isAdmin ? 'Admin' : 'Customer'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Could not refresh account details: $_loadError',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
                  subtitle: Text(_isAdmin ? 'Administrator' : 'Customer'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Total spent'),
                  subtitle: Text(
                    _totalSpent == null
                        ? '…'
                        : '${Meal.currency}${_totalSpent!.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Profile settings'),
                  subtitle: const Text('Username and password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileSettingsScreen(),
                      ),
                    );
                    _load();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Saved locations'),
                  subtitle: Text('$_locationCount delivery locations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedLocationsScreen(),
                      ),
                    );
                    _load();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Delivery details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _deliveryProfile?.isComplete == true
                    ? '${_deliveryProfile!.phone}\n${_deliveryProfile!.addressLabel}'
                    : 'Add once and use automatically at checkout',
              ),
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
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
