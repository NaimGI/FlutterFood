import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/saved_address.dart';
import '../services/address_service.dart';
import '../services/api_exception.dart';
import '../widgets/app_snackbar.dart';
import 'saved_location_form_screen.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final _service = AddressService();
  List<SavedAddress> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addresses = await _service.getMine();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
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

  Future<void> _openForm([SavedAddress? address]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SavedLocationFormScreen(address: address),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _setDefault(SavedAddress address) async {
    try {
      await _service.setDefault(address.id);
      await _load();
      if (mounted) AppSnackbar.success(context, 'Default location updated');
    } on ApiException catch (error) {
      if (mounted) AppSnackbar.error(context, error.message);
    }
  }

  Future<void> _delete(SavedAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text('Remove "${address.label}" from your saved locations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.delete(address.id);
      await _load();
      if (mounted) AppSnackbar.success(context, 'Location deleted');
    } on ApiException catch (error) {
      if (mounted) AppSnackbar.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved locations'),
        actions: [
          IconButton(
            tooltip: 'Add location',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : _addresses.isEmpty
          ? _EmptyState(onAdd: () => _openForm())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: .1,
                            ),
                            child: Icon(
                              address.label.toLowerCase() == 'work'
                                  ? Icons.work_outline
                                  : Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  address.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (address.isDefault)
                                const Chip(
                                  label: Text('Default'),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          subtitle: Text(address.formattedAddress),
                          isThreeLine: true,
                        ),
                        const Divider(height: 1),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: address.isDefault
                                  ? null
                                  : () => _setDefault(address),
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Make default'),
                            ),
                            TextButton.icon(
                              onPressed: () => _openForm(address),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _delete(address),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _addresses.isNotEmpty && !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add location'),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_outlined, size: 56),
          const SizedBox(height: 12),
          const Text('No saved locations yet'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add a location'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
