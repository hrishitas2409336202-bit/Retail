import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final Map<String, bool> _sendingState = {};

  Future<void> _handleSend(BuildContext context, String productId, String productName) async {
    setState(() => _sendingState[productId] = true);
    
    // Simulate API call to supplier
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _sendingState[productId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Purchase Order for $productName sent to supplier successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final orders = state.generatePurchaseOrders();

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Auto Purchase Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.checkCircle, size: 64, color: Colors.green.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('All stock levels are optimal.', style: TextStyle(color: AppTheme.textBody(context), fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final p = order['product'];
                final isUrgent = order['priority'] == 'Urgent';
                final isSending = _sendingState[p.id] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isUrgent ? Colors.red.withOpacity(0.4) : AppTheme.divider(context),
                      width: isUrgent ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Column(
                      children: [
                        // Header with gradient
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUrgent 
                                ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.02)]
                                : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.02)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(p.emoji, style: const TextStyle(fontSize: 32)),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textHeading(context))),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isUrgent ? Colors.red : Colors.blue).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Stock: ${p.stock} units',
                                        style: TextStyle(
                                          fontSize: 10, 
                                          fontWeight: FontWeight.bold,
                                          color: isUrgent ? Colors.red : Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUrgent)
                                const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoColumn(context, 'REORDER QUANTITY', '${order['recommended']} Units', LucideIcons.packagePlus),
                                  _infoColumn(context, 'ESTIMATED COST', '${state.currency}${(order['estCost'] as double).toInt()}', LucideIcons.indianRupee, isAccent: true),
                                ],
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: isSending ? null : () => _handleSend(context, p.id, p.name),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 54),
                                  backgroundColor: isUrgent ? Colors.redAccent : AppTheme.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: isSending 
                                  ? const SizedBox(
                                      height: 20, 
                                      width: 20, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.truck, size: 18),
                                        const SizedBox(width: 12),
                                        Text(
                                          'SEND TO SUPPLIER', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                        ),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          border: Border(top: BorderSide(color: AppTheme.divider(context))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Investment', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '${state.currency}${orders.fold<double>(0, (sum, item) => sum + item['estCost']).toInt()}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('AUTO-REORDER ALL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String label, String value, IconData icon, {bool isAccent = false}) {
    return Column(
      crossAxisAlignment: isAccent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAccent) Icon(icon, size: 12, color: Colors.grey),
            if (!isAccent) const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            if (isAccent) const SizedBox(width: 4),
            if (isAccent) Icon(icon, size: 12, color: AppTheme.accent),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: isAccent ? AppTheme.accent : AppTheme.textHeading(context)
          )
        ),
      ],
    );
  }
}

