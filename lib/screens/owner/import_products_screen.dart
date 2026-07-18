import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportProductsScreen extends StatefulWidget {
  const ImportProductsScreen({super.key});

  @override
  State<ImportProductsScreen> createState() => _ImportProductsScreenState();
}

class _ImportProductsScreenState extends State<ImportProductsScreen> {
  String? selectedFileName;
  List<List<dynamic>> csvRows = [];

  bool isImporting = false;
  int successCount = 0;
  int failedCount = 0;

  final List<String> requiredHeaders = [
    'barcode',
    'productName',
    'category',
    'buyingPrice',
    'sellingPrice',
    'stock',
    'supplier',
    'expirationDate',
  ];

  Future<void> chooseCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      final Uint8List? bytes = file.bytes;

      if (bytes == null) {
        throw Exception('Unable to read the selected file.');
      }

      String csvText = utf8.decode(bytes, allowMalformed: true);

      csvText = csvText.replaceFirst('\uFEFF', '');

      final rows = csv.decode(csvText);

      if (rows.isEmpty) {
        throw Exception('The CSV file is empty.');
      }

      final headers = rows.first
          .map((value) => value.toString().trim())
          .toList();

      for (final requiredHeader in requiredHeaders) {
        if (!headers.contains(requiredHeader)) {
          throw Exception('Missing required column: $requiredHeader');
        }
      }

      setState(() {
        selectedFileName = file.name;
        csvRows = rows;
        successCount = 0;
        failedCount = 0;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${rows.length - 1} products found in ${file.name}.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime? parseExpirationDate(String value) {
    final String cleanedValue = value.trim();

    if (cleanedValue.isEmpty) {
      return null;
    }

    final DateTime? isoDate = DateTime.tryParse(cleanedValue);

    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final List<String> slashParts = cleanedValue.split('/');

    if (slashParts.length == 3) {
      final int? first = int.tryParse(slashParts[0]);
      final int? second = int.tryParse(slashParts[1]);
      final int? year = int.tryParse(slashParts[2]);

      if (first != null && second != null && year != null) {
        // Expected alternative format: MM/DD/YYYY
        try {
          return DateTime(year, first, second);
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  Future<void> importProducts() async {
    if (csvRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a valid CSV file first.')),
      );
      return;
    }

    setState(() {
      isImporting = true;
      successCount = 0;
      failedCount = 0;
    });

    try {
      final headers = csvRows.first
          .map((value) => value.toString().trim())
          .toList();

      final int barcodeIndex = headers.indexOf('barcode');
      final int productNameIndex = headers.indexOf('productName');
      final int categoryIndex = headers.indexOf('category');
      final int buyingPriceIndex = headers.indexOf('buyingPrice');
      final int sellingPriceIndex = headers.indexOf('sellingPrice');
      final int stockIndex = headers.indexOf('stock');
      final int supplierIndex = headers.indexOf('supplier');
      final int expirationDateIndex = headers.indexOf('expirationDate');

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      WriteBatch batch = firestore.batch();
      int batchWriteCount = 0;

      for (int rowIndex = 1; rowIndex < csvRows.length; rowIndex++) {
        try {
          final List<dynamic> row = csvRows[rowIndex];

          if (row.every((value) => value.toString().trim().isEmpty)) {
            continue;
          }

          String readValue(int index) {
            if (index < 0 || index >= row.length) {
              return '';
            }

            return row[index].toString().trim();
          }

          final String barcode = readValue(barcodeIndex);
          final String productName = readValue(productNameIndex);
          final String category = readValue(categoryIndex);
          final String supplier = readValue(supplierIndex);

          final double? buyingPrice = double.tryParse(
            readValue(buyingPriceIndex),
          );

          final double? sellingPrice = double.tryParse(
            readValue(sellingPriceIndex),
          );

          final int? stock = double.tryParse(readValue(stockIndex))?.toInt();

          final DateTime? expirationDate = parseExpirationDate(
            readValue(expirationDateIndex),
          );

          if (barcode.isEmpty ||
              productName.isEmpty ||
              buyingPrice == null ||
              sellingPrice == null ||
              stock == null ||
              expirationDate == null) {
            failedCount++;
            continue;
          }

          final String safeBarcode = barcode.replaceAll(
            RegExp(r'[^a-zA-Z0-9_-]'),
            '_',
          );

          final DocumentReference<Map<String, dynamic>> productRef = firestore
              .collection('products')
              .doc('barcode_$safeBarcode');

          batch.set(productRef, {
            'barcode': barcode,
            'productName': productName,
            'category': category,
            'buyingPrice': buyingPrice,
            'sellingPrice': sellingPrice,
            'stock': stock,
            'supplier': supplier,
            'expirationDate': Timestamp.fromDate(expirationDate),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          batchWriteCount++;
          successCount++;

          if (batchWriteCount >= 400) {
            await batch.commit();

            batch = firestore.batch();
            batchWriteCount = 0;
          }
        } catch (_) {
          failedCount++;
        }
      }

      if (batchWriteCount > 0) {
        await batch.commit();
      }

      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Import Completed'),
            content: Text(
              'Successfully imported: $successCount\n'
              'Failed rows: $failedCount',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int productCount = csvRows.isEmpty ? 0 : csvRows.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Import Products'),
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
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file,
                    size: 70,
                    color: Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Bulk Product Import',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a CSV UTF-8 file containing your products.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          selectedFileName ?? 'No CSV file selected',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (productCount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$productCount products ready to import',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isImporting ? null : chooseCsvFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('CHOOSE CSV FILE'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isImporting ? null : importProducts,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                      icon: isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        isImporting ? 'IMPORTING...' : 'IMPORT PRODUCTS',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required CSV columns',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'barcode, productName, category, '
                    'buyingPrice, sellingPrice, stock, '
                    'supplier, expirationDate',
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Expiration date format: YYYY-MM-DD',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
