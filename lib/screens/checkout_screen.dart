import 'package:flutter/material.dart';
import 'package:my_flutter_app/widgets/max_width.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/cart_draft.dart';
import '../services/cart_service.dart';
import '../services/meal_service.dart';
import '../services/order_service.dart';
import '../services/organization_service.dart';
import '../services/token_storage.dart';
import '../services/delivery_profile_storage.dart';
import '../models/delivery_profile.dart';
import 'profile_screen.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<Organization> _orgs = [];
  int? _orgId;
  bool _loadingOrgs = true;
  bool _loadingProfile = true;
  DeliveryProfile? _deliveryProfile;
  bool _placing = false;
  bool _isPriority = false;
  bool _isBadWeather = false;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
    _loadDeliveryProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _buildingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrgs() async {
    try {
      final orgs = await OrganizationService().getAll();
      if (!mounted) return;
      setState(() {
        _orgs = orgs;
        _orgId = orgs.isNotEmpty ? orgs.first.id : null;
        _loadingOrgs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOrgs = false);
    }
  }

  Future<void> _loadDeliveryProfile() async {
    final profile = await DeliveryProfileStorage.read();
    if (!mounted) return;
    setState(() {
      _deliveryProfile = profile;
      _loadingProfile = false;
      _phoneCtrl.text = profile?.phone ?? '';
      _countryCtrl.text = profile?.country ?? '';
      _cityCtrl.text = profile?.city ?? '';
      _streetCtrl.text = profile?.street ?? '';
      _buildingCtrl.text = profile?.building ?? '';
    });
  }

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  Widget _buildDeliveryProfileCard() {
    final profile = _deliveryProfile;
    final ready = profile?.isComplete == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ready ? AppColors.fieldFill : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ready ? Colors.transparent : AppColors.primary.withValues(alpha: .35)),
      ),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.location_on_outlined, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ready ? 'Saved delivery address' : 'Delivery details needed', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(ready ? '${profile!.phone}\n${profile.addressLabel}' : 'Save your phone and address once in Profile.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
        ])),
        TextButton(onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          _loadDeliveryProfile();
        }, child: Text(ready ? 'Change' : 'Set up')),
      ]),
    );
  }

  Future<void> _goLogin() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// 3-step backend flow: Cart -> Order (total 0) -> addMeal per line.
  Future<void> _placeOrder() async {
    final draft = CartDraft.instance;
    if (draft.isEmpty || draft.restaurant == null) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_orgId == null) {
      AppSnackbar.error(context, 'Please select an organization');
      return;
    }
    if (_deliveryProfile?.isComplete != true) {
      AppSnackbar.error(context, 'Add your delivery details in Profile first');
      return;
    }
    setState(() => _placing = true);
    try {
      final userId = int.tryParse(await TokenStorage.readUserId() ?? '');
      if (userId == null) {
        throw const ApiException('Account not found, please log in again (401)',
            statusCode: 401);
      }
      final cartId = await CartService().createCart(
        restaurantId: draft.restaurant!.id,
        organizationId: _orgId!,
        phoneNumber: _phoneCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        building: _buildingCtrl.text.trim(),
      );
      final orderId = await OrderService().create(
        cartId: cartId,
        accountId: userId,
        totalPrice: 0,
        notes: _notesCtrl.text.trim(),
        isPriority: _isPriority,
        isBadWeather: _isBadWeather,
      );
      for (final line in draft.value) {
        await MealService().addToOrder(
            orderId: orderId,
            mealId: line.meal.id,
            quantity: line.quantity);
      }
      draft.clear();
      if (!mounted) return;
      AppSnackbar.success(context, 'Order #$orderId placed successfully');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _goLogin();
        return;
      }
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = CartDraft.instance;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: draft.isEmpty
            ? const Center(child: Text('Your basket is empty'))
            : MaxWidth(
                child: Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                                16, 12, 16, 16 + bottomInset * 0.3),
                            children: [
                              _buildSummary(draft),
                              const SizedBox(height: 20),
                              const Text('Delivery details',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 10),
                              _loadingOrgs
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : DropdownButtonFormField<int>(
                                      initialValue: _orgId,
                                      decoration: const InputDecoration(
                                        labelText: 'Organization',
                                      ),
                                      isExpanded: true,
                                      items: _orgs
                                          .map((o) =>
                                              DropdownMenuItem(
                                                  value: o.id,
                                                  child: Text(o.name,
                                                      overflow: TextOverflow
                                                          .ellipsis)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _orgId = v),
                                      validator: (v) => v == null
                                          ? 'Select an organization'
                                          : null,
                                    ),
                              const SizedBox(height: 12),
                              _loadingProfile
                                  ? const Center(child: CircularProgressIndicator())
                                  : _buildDeliveryProfileCard(),
                              const SizedBox(height: 12),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Priority delivery'),
                                subtitle: const Text('Express delivery fee applies'),
                                value: _isPriority,
                                onChanged: (v) => setState(() => _isPriority = v),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Bad weather delivery'),
                                subtitle: const Text('Weather surcharge applies'),
                                value: _isBadWeather,
                                onChanged: (v) => setState(() => _isBadWeather = v),
                              ),
                              const SizedBox(height: 12),
                              const Text('Note (optional)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _notesCtrl,
                                maxLines: 3,
                                minLines: 2,
                                maxLength: 200,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  hintText:
                                      'e.g. no onions (optional)',
                                ),
                              ),
                              // Spacer so last field is never hidden
                              // behind the sticky button.
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildStickyBar(draft),
                  ],
                ),
              ),
      ),
    );
  }

  /// Always-visible bottom bar: total + PLACE ORDER.
  /// Never scrolls away, respects notch + keyboard.
  Widget _buildStickyBar(CartDraft draft) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${draft.count} ${draft.count == 1 ? 'item' : 'items'}',
                    style: const TextStyle(color: Colors.grey)),
                Text(_money(draft.itemsTotal),
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              text: 'PLACE ORDER  •  ${_money(draft.itemsTotal)}',
              loading: _placing,
              onPressed: _placing ? null : _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(CartDraft draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.restaurant?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const Divider(height: 20),
          ...draft.value.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text('${e.quantity}×',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(e.meal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(_money(e.lineTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total to pay',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              Text(_money(draft.itemsTotal),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
