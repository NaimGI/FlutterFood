import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';
import '../services/api_exception.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class SavedLocationFormScreen extends StatefulWidget {
  const SavedLocationFormScreen({super.key, this.address});

  final SavedAddress? address;

  @override
  State<SavedLocationFormScreen> createState() =>
      _SavedLocationFormScreenState();
}

class _SavedLocationFormScreenState extends State<SavedLocationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _country;
  late final TextEditingController _city;
  late final TextEditingController _street;
  late final TextEditingController _building;
  late final TextEditingController _premises;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _label = TextEditingController(text: address?.label ?? '');
    _country = TextEditingController(text: address?.country ?? '');
    _city = TextEditingController(text: address?.city ?? '');
    _street = TextEditingController(text: address?.street ?? '');
    _building = TextEditingController(text: address?.building ?? '');
    _premises = TextEditingController(text: address?.premises ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _country.dispose();
    _city.dispose();
    _street.dispose();
    _building.dispose();
    _premises.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final address = SavedAddress(
      id: widget.address?.id ?? 0,
      label: _label.text.trim(),
      country: _country.text.trim(),
      city: _city.text.trim(),
      street: _street.text.trim(),
      building: _building.text.trim(),
      premises: _premises.text.trim().isEmpty ? null : _premises.text.trim(),
      isDefault: _isDefault,
    );

    try {
      if (widget.address == null) {
        await AddressService().create(address);
      } else {
        await AddressService().update(address);
      }
      if (!mounted) return;
      AppSnackbar.success(context, 'Location saved');
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) AppSnackbar.error(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add location' : 'Edit location'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                label: 'Location name',
                hint: 'e.g. Home or Work',
                controller: _label,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Country',
                hint: 'e.g. Morocco',
                controller: _country,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'City',
                hint: 'e.g. Casablanca',
                controller: _city,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Street',
                hint: 'Street name',
                controller: _street,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Building',
                hint: 'Building or house number',
                controller: _building,
                validator: _required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Apartment or additional details (optional)',
                hint: 'Apartment, floor, entrance',
                controller: _premises,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.primary,
                title: const Text('Set as default location'),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'SAVE LOCATION',
                loading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
