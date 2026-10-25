import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class OfferScreen extends StatefulWidget {
  final ApiService apiService;

  const OfferScreen({super.key, required this.apiService});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  List<Offer> _offers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final offers = await widget.apiService.getOffers();
      if (mounted) {
        setState(() {
          _offers = offers;
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

  void _showOfferDialog({Offer? offer}) {
    final isEditing = offer != null;
    final titleCtl = TextEditingController(text: offer?.title ?? '');
    final descCtl = TextEditingController(text: offer?.description ?? '');
    final discCtl = TextEditingController(text: offer?.discountValue.toStringAsFixed(0) ?? '10');
    String selectedType = offer?.discountType ?? 'PERCENTAGE';
    String selectedScope = offer?.scope ?? 'STORE_WIDE';
    DateTime? startDate = offer?.startDate.isNotEmpty == true ? DateTime.tryParse(offer!.startDate) : DateTime.now();
    DateTime? endDate = offer?.endDate.isNotEmpty == true ? DateTime.tryParse(offer!.endDate) : DateTime.now().add(const Duration(days: 7));
    bool isActive = offer?.isActive ?? true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Offer' : 'Create New Offer'),
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
                  decoration: const InputDecoration(labelText: 'Offer Title*'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discCtl,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: selectedType == 'PERCENTAGE' ? 'Discount %*' : 'Discount Amount*',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'PERCENTAGE', child: Text('Percentage')),
                        DropdownMenuItem(value: 'FIXED', child: Text('Fixed')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedType = val ?? 'PERCENTAGE'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedScope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: const [
                    DropdownMenuItem(value: 'STORE_WIDE', child: Text('Store Wide')),
                    DropdownMenuItem(value: 'PRODUCT_SPECIFIC', child: Text('Product Specific')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedScope = val ?? 'STORE_WIDE'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Start Date*'),
                          child: Text(
                            startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Select date',
                            style: TextStyle(color: startDate != null ? Colors.black : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'End Date*'),
                          child: Text(
                            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Select date',
                            style: TextStyle(color: endDate != null ? Colors.black : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isEditing)
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                    activeColor: AppTheme.primaryGreen,
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
                      final discountVal = double.tryParse(discCtl.text.trim());
                      if (title.isEmpty) {
                        setDialogState(() => dialogError = 'Title is required');
                        return;
                      }
                      if (discountVal == null || discountVal <= 0) {
                        setDialogState(() => dialogError = 'Valid discount value is required');
                        return;
                      }
                      if (startDate == null || endDate == null) {
                        setDialogState(() => dialogError = 'Both start and end dates are required');
                        return;
                      }
                      if (endDate!.isBefore(startDate!)) {
                        setDialogState(() => dialogError = 'End date must be after start date');
                        return;
                      }
                      if (selectedType == 'PERCENTAGE' && discountVal > 100) {
                        setDialogState(() => dialogError = 'Percentage discount cannot exceed 100%');
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final body = {
                        'title': title,
                        'description': descCtl.text.trim(),
                        'discount_type': selectedType,
                        'discount_value': discountVal,
                        'scope': selectedScope,
                        'start_date': startDate!.toIso8601String(),
                        'end_date': endDate!.toIso8601String(),
                        'is_active': isActive,
                      };

                      try {
                        if (isEditing) {
                          await widget.apiService.updateOffer(offer!.id, body);
                        } else {
                          await widget.apiService.createOffer(body);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadOffers();
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
                  : Text(isEditing ? 'Update Offer' : 'Create Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOffer(Offer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
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
        await widget.apiService.deleteOffer(offer.id);
        if (mounted) {
          _loadOffers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Offer "${offer.title}" deleted'), backgroundColor: AppTheme.primaryGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete offer: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadOffers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Offer'),
        onPressed: () => _showOfferDialog(),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _offers.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null && _offers.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to Load Offers',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadOffers,
      );
    }

    if (_offers.isEmpty) {
      return EmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No Offers Yet',
        message: 'Create your first promotional offer to attract customers.',
        actionLabel: 'Create Offer',
        onAction: () => _showOfferDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOffers,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final isValid = offer.isValid;
          final isExpired = offer.endDate.isNotEmpty &&
              DateTime.tryParse(offer.endDate)!.isBefore(DateTime.now());
          final isUpcoming = offer.startDate.isNotEmpty &&
              DateTime.tryParse(offer.startDate)!.isAfter(DateTime.now());

          String statusLabel;
          Color statusColor;
          if (!offer.isActive) {
            statusLabel = 'INACTIVE';
            statusColor = Colors.grey;
          } else if (isUpcoming) {
            statusLabel = 'SCHEDULED';
            statusColor = Colors.blue;
          } else if (isExpired) {
            statusLabel = 'EXPIRED';
            statusColor = Colors.orange;
          } else if (isValid) {
            statusLabel = 'ACTIVE';
            statusColor = Colors.green;
          } else {
            statusLabel = 'INACTIVE';
            statusColor = Colors.grey;
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
                child: Icon(Icons.local_offer, color: statusColor, size: 24),
              ),
              title: Text(
                offer.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${offer.discountType == 'PERCENTAGE' ? '${offer.discountValue.toStringAsFixed(0)}%' : '₹${offer.discountValue.toStringAsFixed(0)}'} • ${offer.scope == 'STORE_WIDE' ? 'Store Wide' : 'Product Specific'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Valid: ${_formatDate(offer.startDate)} – ${_formatDate(offer.endDate)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
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
                        _showOfferDialog(offer: offer);
                      } else if (value == 'delete') {
                        _deleteOffer(offer);
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
                      if (offer.description.isNotEmpty) ...[
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(offer.description),
                        const SizedBox(height: 12),
                      ],
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: _infoChip(
                              'Type',
                              offer.discountType,
                              offer.discountType == 'PERCENTAGE' ? Icons.percent : Icons.attach_money,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _infoChip(
                              'Value',
                              offer.discountType == 'PERCENTAGE'
                                  ? '${offer.discountValue.toStringAsFixed(0)}%'
                                  : '₹${offer.discountValue.toStringAsFixed(0)}',
                              Icons.tag,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (offer.applicableProduct != null) ...[
                        const Text('Applicable Product', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(offer.productName ?? 'Unknown', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 12),
                      ],
                      _infoChip(
                        'Created',
                        _formatDateTime(offer.createdAt),
                        Icons.calendar_today,
                      ),
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

  Widget _infoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.paleMint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
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