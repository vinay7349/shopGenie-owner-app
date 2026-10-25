import 'package:flutter/material.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class WorkerManagementScreen extends StatefulWidget {
  final ApiService apiService;

  const WorkerManagementScreen({super.key, required this.apiService});

  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  List<Worker> _workers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final workers = await widget.apiService.getWorkers();
      if (mounted) {
        setState(() {
          _workers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showWorkerDialog({Worker? worker}) {
    final isEditing = worker != null;
    final usernameCtl = TextEditingController(text: worker?.username ?? '');
    final emailCtl = TextEditingController(text: worker?.email ?? '');
    final firstNameCtl = TextEditingController(text: worker?.firstName ?? '');
    final lastNameCtl = TextEditingController(text: worker?.lastName ?? '');
    final passCtl = TextEditingController();
    bool isActive = worker?.isWorkerActive ?? true;
    bool canViewInvoices = worker?.canViewInvoices ?? true;
    bool canConfirmBills = worker?.canConfirmBills ?? true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Worker' : 'Add New Worker'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(dialogError!, style: const TextStyle(color: AppTheme.errorRed)),
                  ),
                if (!isEditing) ...[
                  TextField(
                    controller: usernameCtl,
                    decoration: const InputDecoration(labelText: 'Username*'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtl,
                    decoration: const InputDecoration(labelText: 'Email*'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password* (min 8 chars)'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: firstNameCtl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameCtl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                const SizedBox(height: 12),
                if (isEditing) ...[
                  const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Active Worker'),
                    subtitle: const Text('Worker can log in and access assigned features'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                    activeColor: AppTheme.primaryGreen,
                  ),
                  SwitchListTile(
                    title: const Text('View Invoices'),
                    subtitle: const Text('Allow viewing invoice history and details'),
                    value: canViewInvoices,
                    onChanged: (val) => setDialogState(() => canViewInvoices = val),
                    activeColor: AppTheme.primaryGreen,
                  ),
                  SwitchListTile(
                    title: const Text('Confirm Bills'),
                    subtitle: const Text('Allow creating and confirming customer bills'),
                    value: canConfirmBills,
                    onChanged: (val) => setDialogState(() => canConfirmBills = val),
                    activeColor: AppTheme.primaryGreen,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!isEditing) {
                        final username = usernameCtl.text.trim();
                        final email = emailCtl.text.trim();
                        final pass = passCtl.text.trim();
                        if (username.isEmpty || email.isEmpty || pass.isEmpty) {
                          setDialogState(() => dialogError = 'All fields are required');
                          return;
                        }
                        if (pass.length < 8) {
                          setDialogState(() => dialogError = 'Password must be at least 8 characters');
                          return;
                        }
                      }

                      setDialogState(() => isSubmitting = true);

                      final body = <String, dynamic>{
                        if (!isEditing) 'username': usernameCtl.text.trim(),
                        if (!isEditing) 'email': emailCtl.text.trim(),
                        if (!isEditing) 'password': passCtl.text.trim(),
                        'first_name': firstNameCtl.text.trim(),
                        'last_name': lastNameCtl.text.trim(),
                        if (isEditing) 'is_worker_active': isActive,
                        if (isEditing) 'can_view_invoices': canViewInvoices,
                        if (isEditing) 'can_confirm_bills': canConfirmBills,
                      };

                      try {
                        if (isEditing) {
                          await widget.apiService.updateWorker(worker!.id, body);
                        } else {
                          await widget.apiService.createWorker(body);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadWorkers();
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            isSubmitting = false;
                            dialogError = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'Update Worker' : 'Create Worker'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWorker(Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Worker'),
        content: Text('Are you sure you want to remove "${worker.displayName}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteWorker(worker.id);
        if (mounted) {
          _loadWorkers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Worker "${worker.displayName}" removed'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove worker: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(Worker worker) async {
    try {
      await widget.apiService.updateWorker(worker.id, {'is_worker_active': !worker.isWorkerActive});
      if (mounted) {
        _loadWorkers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadWorkers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
        onPressed: () => _showWorkerDialog(),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _workers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null && _workers.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to Load Workers',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadWorkers,
      );
    }

    if (_workers.isEmpty) {
      return EmptyState(
        icon: Icons.badge_outlined,
        title: 'No Workers Yet',
        message: 'Add workers to help manage your shop. They can assist with billing, inventory, and customer service.',
        actionLabel: 'Add Worker',
        onAction: () => _showWorkerDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkers,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _workers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final worker = _workers[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: worker.isWorkerActive ? AppTheme.paleMint : Colors.grey.shade200,
                    child: Icon(Icons.badge, color: worker.isWorkerActive ? AppTheme.primaryGreen : Colors.grey, size: 24),
                  ),
                  title: Text(
                    worker.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.email),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _statusChip('Active', worker.isWorkerActive, worker.isWorkerActive ? Colors.green : Colors.grey),
                          const SizedBox(width: 8),
                          _statusChip('View Invoices', worker.canViewInvoices, worker.canViewInvoices ? Colors.blue : Colors.grey),
                          const SizedBox(width: 8),
                          _statusChip('Confirm Bills', worker.canConfirmBills, worker.canConfirmBills ? Colors.orange : Colors.grey),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showWorkerDialog(worker: worker);
                      } else if (value == 'delete') {
                        _deleteWorker(worker);
                      } else if (value == 'toggle') {
                        _toggleActive(worker);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit Permissions')])),
                      const PopupMenuItem(value: 'toggle', child: Row(children: [Icon(Icons.power_settings_new), SizedBox(width: 8), Text('Toggle Active')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ),
                if (worker.dateJoined != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Added: ${_formatDate(worker.dateJoined!)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? color : Colors.grey),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? color : Colors.grey),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}