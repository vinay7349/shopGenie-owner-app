import 'package:flutter/material.dart';
import '../../models.dart';
import '../../api_service.dart';
import '../../../widgets.dart';

class WorkerDashboardScreen extends StatelessWidget {
  final ApiService apiService;
  final User user;
  final void Function(int) onNavigate;

  const WorkerDashboardScreen({
    super.key,
    required this.apiService,
    required this.user,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return _WorkerDashboardView(
      apiService: apiService,
      user: user,
      onNavigate: onNavigate,
    );
  }
}

class _WorkerDashboardView extends StatelessWidget {
  final ApiService apiService;
  final User user;
  final void Function(int) onNavigate;

  const _WorkerDashboardView({
    required this.apiService,
    required this.user,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SGCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logged in as ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Assigned to: ', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Worker Permissions:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('POS Billing: ENABLED'),
              const Text('Product Catalog & Stock Search: ENABLED'),
              Text('Invoice History Access: '),
              const Text('Profit Reports & Cost Prices: HIDDEN (Enforced)'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SGButton(
          label: 'Open Quick Billing POS',
          icon: Icons.point_of_sale,
          onPressed: () => onNavigate(1),
          width: double.infinity,
        ),
      ],
    );
  }
}
