import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'invoice_pdf_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoiceScreen extends StatelessWidget {
  final Sale sale;

  const InvoiceScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');
    
    // Calculate subtotal and tax
    double subTotal = sale.total / (1 + (state.taxRate / 100));
    double taxAmount = sale.total - subTotal;

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Digital Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Animation/Icon
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green,
              child: Icon(LucideIcons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 32),

            // The Receipt Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.divider(context)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Receipt Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(state.storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const Text('Official Store Receipt', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _receiptInfo('DATE', formatter.format(sale.date)),
                            _receiptInfo('METHOD', sale.paymentMethod.toUpperCase()),
                            _receiptInfo('INVOICE', sale.id),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Dashed Divider
                  _dashedDivider(context),

                  // Items List
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ...sale.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('${item.qty} x ${state.currency}${item.price.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('${state.currency}${(item.qty * item.price).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  // Dashed Divider
                  _dashedDivider(context),

                  // Totals
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _totalRow('Subtotal', '${state.currency}${subTotal.toInt()}'),
                        const SizedBox(height: 8),
                        _totalRow('Tax (${state.taxRate.toInt()}%)', '${state.currency}${taxAmount.toInt()}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('${state.currency}${sale.total.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.primary)),
                          ],
                        ),
                        if (sale.paymentMethod == 'Cash') ...[
                          const SizedBox(height: 16),
                          _totalRow('Amount Received', '${state.currency}${sale.amountReceived.toInt()}'),
                          const SizedBox(height: 8),
                          _totalRow('Change Returned', '${state.currency}${sale.changeReturned.toInt()}'),
                        ],
                      ],
                    ),
                  ),

                  // Functional Verification QR Code
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.divider(context).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.divider(context).withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QrImageView(
                          data: () {
                            final code = sale.toCompactCode();
                            print("GENERATED QR: $code");
                            return code;
                          }(),
                          size: 140.0,
                          foregroundColor: AppTheme.textHeading(context).withOpacity(0.9),
                        ),
                        const SizedBox(height: 12),
                        const Text('Scan to Verify Receipt', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => InvoicePdfScreen(
                  sale: sale, 
                  storeName: state.storeName, 
                  currency: state.currency, 
                  taxRate: state.taxRate,
                ))),
                icon: const Icon(LucideIcons.printer),
                label: const Text('PRINT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _receiptInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _dashedDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(30, (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : AppTheme.divider(context),
            height: 1,
          ),
        )),
      ),
    );
  }
}

