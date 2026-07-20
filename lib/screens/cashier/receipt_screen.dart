import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/cart_item.dart';

class ReceiptScreen extends StatelessWidget {
  final List<CartItem> cart;
  final double total;
  final double cash;
  final double change;
  final String transactionId;
  final DateTime transactionDate;

  const ReceiptScreen({
    super.key,
    required this.cart,
    required this.total,
    required this.cash,
    required this.change,
    required this.transactionId,
    required this.transactionDate,
  });

  String get receiptNumber => transactionId;

  Future<Uint8List> generatePdf() async {
    final logoBytes = await rootBundle.load('assets/images/eu_mart_logo.png');

    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Image(logoImage, width: 75, height: 75),

                    pw.SizedBox(height: 8),

                    pw.Text(
                      'EU MART',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      'Point of Sale & Inventory System',
                      style: const pw.TextStyle(fontSize: 11),
                    ),

                    pw.SizedBox(height: 10),

                    pw.Text(
                      'OFFICIAL RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'Receipt No.: $receiptNumber',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 4),

              pw.Text(
                'Date: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(transactionDate)}',
              ),

              pw.SizedBox(height: 15),

              pw.Divider(),

              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      receiptCell('Product', bold: true),
                      receiptCell('Qty', bold: true),
                      receiptCell('Price', bold: true),
                      receiptCell('Subtotal', bold: true),
                    ],
                  ),

                  ...cart.map(
                    (item) => pw.TableRow(
                      children: [
                        receiptCell(
                          item.promoFreeUnits > 0
                              ? '${item.productName} (${item.promoLabel})'
                              : item.productName,
                        ),
                        receiptCell(
                          item.promoFreeUnits > 0
                              ? '${item.quantity} + ${item.promoFreeUnits} free'
                              : '${item.quantity}',
                        ),
                        receiptCell(
                          'P${item.effectiveUnitPrice.toStringAsFixed(2)}',
                        ),
                        receiptCell('P${item.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              amountRow('Total', total, bold: true),

              amountRow('Cash', cash),

              amountRow('Change', change),

              pw.SizedBox(height: 15),

              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    'PAID',
                    style: pw.TextStyle(
                      color: PdfColors.green800,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for shopping at EU MART!',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(
                      'Please come again.',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget receiptCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget amountRow(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),

          pw.SizedBox(
            width: 100,
            child: pw.Text(
              'P${value.toStringAsFixed(2)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget receiptAmountRow(
    String label,
    double value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          Text(
            '₱${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: bold ? 18 : 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'MMMM dd, yyyy - hh:mm a',
    ).format(transactionDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Receipt'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/eu_mart_logo.png',
                    width: 95,
                    height: 95,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'EÜ MART',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Point of Sale & Inventory System',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'OFFICIAL RECEIPT',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Receipt No.: $receiptNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Date: $formattedDate'),
                  ),

                  const SizedBox(height: 15),

                  const Divider(),

                  ...cart.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  '${item.quantity} × ₱${item.effectiveUnitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                if (item.promoActive &&
                                    item.promoLabel.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    item.promoFreeUnits > 0
                                        ? '${item.promoLabel} • ${item.promoFreeUnits} free item(s)'
                                        : item.promoLabel,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Text(
                            '₱${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(),

                  receiptAmountRow(
                    'TOTAL',
                    total,
                    bold: true,
                    color: Colors.green,
                  ),

                  receiptAmountRow('CASH', cash),

                  receiptAmountRow(
                    'CHANGE',
                    change,
                    bold: true,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PAID',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Thank you for shopping at EÜ MART!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Please come again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Printing.layoutPdf(onLayout: (_) => generatePdf());
              },
              icon: const Icon(Icons.print),
              label: const Text('PRINT / SAVE PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final pdfBytes = await generatePdf();

                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: 'EU_MART_Receipt_$receiptNumber.pdf',
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('SHARE PDF'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: TextButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('DONE'),
            ),
          ),
        ],
      ),
    );
  }
}
