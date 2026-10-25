import 'package:flutter/material.dart';
import '../../models.dart';
import '../../api_service.dart';
import '../../theme/app_theme.dart';
import '../../../widgets.dart';

class SettingsScreen extends StatelessWidget {
  final ApiService apiService;
  final User user;
  final ValueChanged<User> onUserUpdated;

  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsView(
      apiService: apiService,
      user: user,
      onUserUpdated: onUserUpdated,
    );
  }
}

class SettingsView extends StatefulWidget {
  final ApiService apiService;
  final User user;
  final ValueChanged<User> onUserUpdated;

  const SettingsView({
    super.key,
    required this.apiService,
    required this.user,
    required this.onUserUpdated,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late User _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _changePassword() async {
    final currentCtl = TextEditingController();
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();
    String? dialogError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
              SGTextField(
                controller: currentCtl,
                label: 'Current Password',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SGTextField(
                controller: newCtl,
                label: 'New Password*',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SGTextField(
                controller: confirmCtl,
                label: 'Confirm New Password*',
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (newCtl.text.isEmpty || confirmCtl.text.isEmpty || currentCtl.text.isEmpty) {
                  setDialogState(() => dialogError = 'All fields are required');
                  return;
                }
                if (newCtl.text != confirmCtl.text) {
                  setDialogState(() => dialogError = 'Passwords do not match');
                  return;
                }
                if (newCtl.text.length < 8) {
                  setDialogState(() => dialogError = 'Password must be at least 8 characters');
                  return;
                }

                // For now, we'll just show success since backend doesn't have password change endpoint
                // TODO: Implement password change when backend supports it
                Navigator.pop(ctx, true);
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password change requested. Backend support needed for full implementation.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account Section
        SGCardSection(
          title: 'Account',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                title: const Text('Profile'),
                subtitle: Text('${_user.username} (${_user.email})'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Could add profile editing here
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                title: const Text('Change Password'),
                subtitle: const Text('Update your login password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Security Section
        SGCardSection(
          title: 'Security',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security_outlined, color: AppTheme.primaryGreen),
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Add an extra layer of security (coming soon)'),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices_outlined, color: AppTheme.primaryGreen),
                title: const Text('Active Sessions'),
                subtitle: const Text('Manage logged-in devices (coming soon)'),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Preferences
        SGCardSection(
          title: 'App Preferences',
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined, color: AppTheme.primaryGreen),
                title: const Text('Notifications'),
                subtitle: const Text('Manage notification preferences (coming soon)'),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryGreen),
                title: const Text('Dark Mode'),
                subtitle: const Text('Follows system setting'),
                trailing: const Icon(Icons.chevron_right),
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Danger Zone
        SGCardSection(
          title: 'Danger Zone',
          trailing: const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 20),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                title: const Text('Logout', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                subtitle: const Text('Sign out of your account'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    // Navigate back to login by triggering logout in parent
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // App Info
        SGCard(
          child: Column(
            children: [
              const Icon(Icons.storefront_rounded, size: 48, color: AppTheme.primaryGreen),
              const SizedBox(height: 8),
              const Text('ShopGenie Owner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('© 2024 ShopGenie. All rights reserved.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }
}