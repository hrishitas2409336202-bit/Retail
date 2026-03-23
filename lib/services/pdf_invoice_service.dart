import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';

class PdfInvoiceService {
  /// Generates the PDF document as bytes for preview or saving
  static Future<Uint8List> generateInvoice(Sale sale, String storeName, String currency, double taxRate) async {
    print("PDF: Generating Premium Document for ${sale.id}");
    
    // Use 'Rs.' for maximum compatibility in PDF viewers/printers
    final String pdfCurrency = (currency == '₹' || currency.contains('₹')) ? 'Rs. ' : '$currency ';

    // Load Noto Sans for consistent Unicode support across all devices
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();

    final doc = pw.Document();

    // Calculations
    double subTotal = sale.total / (1 + (taxRate / 100));
    double taxAmount = sale.total - subTotal;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) => pw.Column(
          children: [
            // 1. PREMIUM HEADER SECTION WITH GRADIENT SIMULATION
            pw.Container(
              height: 180,
              width: double.infinity,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColor.fromInt(0xFF0F172A), PdfColor.fromInt(0xFF1E293B)],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // Monogram Logo Placeholder
                      pw.Container(
                        width: 40, height: 40,
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blueAccent700,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text(storeName.substring(0, 1), 
                            style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.white)),
                        ),
                      ),
                      pw.Text(storeName.toUpperCase(), 
                        style: pw.TextStyle(font: fontBold, fontSize: 28, color: PdfColors.white)),
                      pw.SizedBox(height: 16),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.greenAccent700,
                          borderRadius: pw.BorderRadius.circular(20),
                        ),
                        child: pw.Text('PAID • ${(sale.paymentMethod == 'UPI' || sale.paymentMethod == 'Online') ? 'ONLINE' : sale.paymentMethod.toUpperCase()}', 
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('TAX INVOICE', 
                        style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blue200, letterSpacing: 1.2)),
                      pw.Text('#${sale.id}', 
                        style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColors.white)),
                      pw.SizedBox(height: 12),
                      pw.Text('DATE & TIME', 
                        style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey500)),
                      pw.Text(sale.date.toString().split('.')[0], 
                        style: pw.TextStyle(font: fontRegular, fontSize: 11, color: PdfColors.grey300)),
                    ],
                  ),
                ],
              ),
            ),

            // 2. MAIN CONTENT AREA
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Customer Detail Section
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('Valued Customer', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.black)),
                          pw.Text('In-Store Transaction', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('STATUS:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('COMPLETED', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green700)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // Stylish Header for Table
                  pw.Container(
                    width: double.infinity,
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF1F5F9),
                      borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
                    ),
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 4, child: pw.Text('DESCRIPTION', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800))),
                        pw.Expanded(flex: 1, child: pw.Text('QTY', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800))),
                        pw.Expanded(flex: 2, child: pw.Text('UNIT PRICE', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800))),
                        pw.Expanded(flex: 2, child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800))),
                      ],
                    ),
                  ),

                  // Table Rows with Subtle Borders
                  ...sale.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final index = entry.key;
                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 1 ? const PdfColor.fromInt(0xFFF8FAFC) : PdfColors.white,
                        border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5)),
                      ),
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 4, child: pw.Text(item.name, style: pw.TextStyle(font: fontRegular, fontSize: 11))),
                          pw.Expanded(flex: 1, child: pw.Text('${item.qty}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 11))),
                          pw.Expanded(flex: 2, child: pw.Text('$pdfCurrency${item.price.toInt()}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 11))),
                          pw.Expanded(flex: 2, child: pw.Text('$pdfCurrency${(item.qty * item.price).toInt()}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 11))),
                        ],
                      ),
                    );
                  }).toList(),

                  pw.SizedBox(height: 40),
                  
                  // Summary and Verification Section
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('AUTHENTICITY:', style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey700)),
                            pw.SizedBox(height: 8),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(8),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey100),
                                borderRadius: pw.BorderRadius.circular(12),
                              ),
                              child: pw.Column(
                                children: [
                                  pw.BarcodeWidget(
                                    barcode: pw.Barcode.qrCode(),
                                    data: "https://rq.link/v?s=${sale.id}&t=${sale.date.millisecondsSinceEpoch}",
                                    width: 70,
                                    height: 70,
                                    color: PdfColors.black,
                                  ),
                                  pw.SizedBox(height: 6),
                                  pw.Text('Scan to Verify', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          children: [
                            _pTotalRow('Subtotal Amount', '$pdfCurrency${subTotal.toInt()}', fontRegular),
                            pw.SizedBox(height: 8),
                            _pTotalRow('Tax (${taxRate.toInt()}%)', '$pdfCurrency${taxAmount.toInt()}', fontRegular),
                            pw.SizedBox(height: 20),
                            pw.Container(
                              padding: const pw.EdgeInsets.all(16),
                              decoration: const pw.BoxDecoration(
                                gradient: pw.LinearGradient(
                                  colors: [PdfColor.fromInt(0xFFF1F5F9), PdfColor.fromInt(0xFFE2E8F0)],
                                ),
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                              ),
                              child: pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('NET TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColor.fromInt(0xFF0F172A))),
                                  pw.Text('$pdfCurrency${sale.total.toInt()}', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColor.fromInt(0xFF0F172A))),
                                ],
                              ),
                            ),
                            if (sale.paymentMethod == 'Cash') ...[
                              pw.SizedBox(height: 16),
                              _pTotalRow('Cash Received', '$pdfCurrency${sale.amountReceived.toInt()}', fontRegular, small: true),
                              _pTotalRow('Change Return', '$pdfCurrency${sale.changeReturned.toInt()}', fontBold, small: true, color: PdfColors.green800),
                            ],
                          ],
                        ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            // 3. PREMIUM FOOTER SECTION
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 30),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 1)),
              ),
              child: pw.Column(
                children: [
                  pw.Text('Thank you for choosing $storeName!', 
                    style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromInt(0xFF0F172A))),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    width: 200, height: 0.5,
                    color: PdfColors.grey300,
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('This is a digitally generated invoice. No signature is required.', 
                    style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Directly sends the PDF to the system print dialog
  static Future<void> printInvoice(Sale sale, String storeName, String currency, double taxRate) async {
    try {
      final bytes = await generateInvoice(sale, storeName, currency, taxRate);
      print("PDF: Triggering System Print Dialog...");
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Invoice_${sale.id}',
      );
    } catch (e, stack) {
      print("CRITICAL PDF ERROR: $e");
      print(stack);
    }
  }

  static pw.Widget _pTotalRow(String label, String value, pw.Font font, {bool small = false, PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: small ? 9 : 11, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: small ? 9 : 11, color: color)),
        ],
      ),
    );
  }
}


