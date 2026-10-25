import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  final ApiService apiService;

  const InvoiceHistoryScreen({super.key, required this.apiService});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  List<dynamic> _invoices = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoices = await widget.apiService.getInvoices();
      if (mounted) {
        setState(() {
          _invoices = invoices;
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    if (amount is String) return '₹${double.tryParse(amount)?.toStringAsFixed(2) ?? '0.00'}';
    if (amount is num) return '₹${amount.toStringAsFixed(2)}';
    return '₹0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_error != null && _invoices.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to Load Invoices',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadInvoices,
      );
    }

    if (_invoices.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Invoices Yet',
        message: 'Completed bills will appear here.',
        actionLabel: 'Start Billing',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inv = _invoices[index];
          final id = inv['id']?.toString() ?? '';
          final totalAmount = inv['total_amount'] ?? 0;
          final status = inv['status']?.toString() ?? 'COMPLETED';
          final createdAt = inv['created_at']?.toString() ?? '';
          final idempotencyKey = inv['idempotency_key']?.toString() ?? '';

          Color statusColor = Colors.green;
          String statusLabel = 'COMPLETED';

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.paleMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.primaryGreen, size: 24),
              ),
              title: Text(
                'Invoice #$id',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${_formatDate(createdAt)}'),
                  Text('Total: ${_formatCurrency(totalAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  if (idempotencyKey.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Key: ${idempotencyKey.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(apiService: widget.apiService, invoiceId: int.tryParse(id) ?? 0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InvoiceDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.apiService, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await widget.apiService.getInvoice(widget.invoiceId);
      if (mounted) {
        setState(() {
          _invoice = Invoice.fromJson(data);
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    if (amount is String) return '₹${double.tryParse(amount)?.toStringAsFixed(2) ?? '0.00'}';
    if (amount is num) return '₹${amount.toStringAsFixed(2)}';
    return '₹0.00';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Detail')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to Load Invoice',
          message: _error!,
          actionLabel: 'Retry',
          onAction: _loadInvoice,
        ),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Detail')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Invoice Not Found',
          message: 'This invoice could not be loaded.',
        ),
      );
    }

    final inv = _invoice!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${inv.id}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInvoice,
        color: AppTheme.primaryGreen,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice #${inv.id}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inv.status,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Date', _formatDate(inv.createdAt)),
                    _infoRow('Idempotency Key', inv.idempotencyKey),
                    _infoRow('Shop ID', inv.shop.toString()),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items
            const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...inv.items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Qty: ${item.quantity.toStringAsFixed(3)}', style: const TextStyle(fontSize: 13)),
                            Text('₹${item.unitPrice.toStringAsFixed(2)} each', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Line Total:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),

            const SizedBox(height: 16),

            // Total
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppTheme.paleMint,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      _formatCurrency(inv.totalAmount),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}