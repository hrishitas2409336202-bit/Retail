import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../models/sale.dart';
import '../../services/pdf_invoice_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InvoicePdfScreen extends StatelessWidget {
  final Sale sale;
  final String storeName;
  final String currency;
  final double taxRate;

  const InvoicePdfScreen({
    super.key, 
    required this.sale, 
    required this.storeName, 
    required this.currency, 
    required this.taxRate
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dark Background for Preview
      appBar: AppBar(
        title: const Text('Export Invoice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PdfPreview(
        build: (format) => PdfInvoiceService.generateInvoice(
          sale, 
          storeName, 
          currency, 
          taxRate
        ),
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        pdfFileName: 'Invoice_${sale.id}.pdf',
        loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.white)),
        // Customizing the previewer for a premium look
        previewPageMargin: const EdgeInsets.all(20),
        useActions: true,
      ),
    );
  }
}

