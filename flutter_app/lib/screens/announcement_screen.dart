import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class AnnouncementScreen extends StatefulWidget {
  final ApiService apiService;

  const AnnouncementScreen({super.key, required this.apiService});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final announcements = await widget.apiService.getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements;
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

  void _showAnnouncementDialog({Announcement? announcement}) {
    final isEditing = announcement != null;
    final titleCtl = TextEditingController(text: announcement?.title ?? '');
    final contentCtl = TextEditingController(text: announcement?.content ?? '');
    String selectedStatus = announcement?.status ?? 'DRAFT';
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Announcement' : 'Create Announcement'),
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
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'Title*'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Content*'),
                ),
                const SizedBox(height: 12),
                if (isEditing)
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                      DropdownMenuItem(value: 'PUBLISHED', child: Text('Published')),
                      DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedStatus = val ?? 'DRAFT'),
                  ),
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
                      final title = titleCtl.text.trim();
                      final content = contentCtl.text.trim();
                      if (title.isEmpty || content.isEmpty) {
                        setDialogState(() => dialogError = 'Title and content are required');
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final body = {
                        'title': title,
                        'content': content,
                        if (isEditing) 'status': selectedStatus,
                      };

                      try {
                        if (isEditing) {
                          await widget.apiService.updateAnnouncement(announcement!.id, body);
                        } else {
                          await widget.apiService.createAnnouncement(body);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadAnnouncements();
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
                  : Text(isEditing ? 'Update Announcement' : 'Create Announcement'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteAnnouncement(announcement.id);
        if (mounted) {
          _loadAnnouncements();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Announcement "${announcement.title}" deleted'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete announcement: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
        onPressed: () => _showAnnouncementDialog(),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _announcements.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null && _announcements.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to Load Announcements',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadAnnouncements,
      );
    }

    if (_announcements.isEmpty) {
      return EmptyState(
        icon: Icons.campaign_outlined,
        title: 'No Announcements Yet',
        message: 'Create announcements to keep your customers informed about new arrivals, offers, and updates.',
        actionLabel: 'Create Announcement',
        onAction: () => _showAnnouncementDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          final isPublished = announcement.status == 'PUBLISHED';

          Color statusColor;
          String statusLabel;
          switch (announcement.status) {
            case 'PUBLISHED':
              statusColor = Colors.green;
              statusLabel = 'PUBLISHED';
              break;
            case 'DRAFT':
              statusColor = Colors.blue;
              statusLabel = 'DRAFT';
              break;
            case 'ARCHIVED':
              statusColor = Colors.grey;
              statusLabel = 'ARCHIVED';
              break;
            default:
              statusColor = Colors.grey;
              statusLabel = announcement.status;
          }

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.campaign, color: statusColor, size: 24),
              ),
              title: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Created: ${_formatDateTime(announcement.createdAt)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAnnouncementDialog(announcement: announcement);
                      } else if (value == 'delete') {
                        _deleteAnnouncement(announcement);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(announcement.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: _infoChip(
                              'Status',
                              statusLabel,
                              isPublished ? Icons.public : Icons.drafts,
                              statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _infoChip(
                              'Created',
                              _formatDateTime(announcement.createdAt),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      if (announcement.updatedAt != announcement.createdAt) ...[
                        const SizedBox(height: 8),
                        _infoChip(
                          'Updated',
                          _formatDateTime(announcement.updatedAt),
                          Icons.update,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(String label, String value, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}