import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../services/admin_reports_service.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  final _service = AdminReportsService();
  late final TabController _tabs;

  List<AdminReport> _reports = [];
  List<AdminRating> _ratings = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getReports(),
        _service.getRatings(),
      ]);
      if (!mounted) return;
      setState(() {
        _reports = results[0] as List<AdminReport>;
        _ratings = results[1] as List<AdminRating>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 401) {
        await AuthService().logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Ratings',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Reports (${_reports.length})'),
            Tab(text: 'Ratings (${_ratings.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildReports(),
                    _buildRatings(),
                  ],
                ),
    );
  }

  Widget _buildReports() {
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports submitted yet'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = _reports[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.type.toLowerCase() == 'meal'
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: r.type.toLowerCase() == 'meal'
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Order #${r.orderId}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      Text(r.status,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: r.status.toLowerCase() == 'pending'
                                  ? AppColors.error
                                  : AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.description,
                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (r.mealName != null)
                        Chip(
                          label: Text('Meal: ${r.mealName}',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (r.restaurantName != null)
                        Chip(
                          label: Text('Restaurant: ${r.restaurantName}',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text('By: ${r.orderUser}',
                            style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_formatDate(r.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatings() {
    if (_ratings.isEmpty) {
      return const Center(child: Text('No ratings submitted yet'));
    }
    final avg = _ratings.isEmpty
        ? 0.0
        : _ratings.fold<int>(0, (s, r) => s + r.score) / _ratings.length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF9A4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('${_ratings.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      const Text('Ratings',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white38),
                Expanded(
                  child: Column(
                    children: [
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      const Text('Average',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white38),
                Expanded(
                  child: Column(
                    children: [
                      Text(_money(_ratings.fold<double>(0, (s, r) => s + r.totalPrice)),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                      const Text('Total value',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._ratings.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                                i < r.score ? Icons.star : Icons.star_border,
                                size: 18,
                                color: i < r.score
                                    ? const Color(0xFFFFB300)
                                    : Colors.grey,
                              )),
                          const SizedBox(width: 8),
                          Text(r.orderUser,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(_money(r.totalPrice),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.comment!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87)),
                      ],
                      const SizedBox(height: 4),
                      Text('Order #${r.orderId} · ${_formatDate(r.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildError() {
    final isExpired = _error is ApiException && (_error as ApiException).statusCode == 401;
    final message = _error is ApiException ? (_error as ApiException).message : 'Unexpected error';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isExpired
                ? () async {
                    await AuthService().logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                : _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isExpired ? 'Log in again' : 'Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }
}
