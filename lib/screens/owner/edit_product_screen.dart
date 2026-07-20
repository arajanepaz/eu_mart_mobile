import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProductScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> product;

  const EditProductScreen({
    super.key,
    required this.documentId,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController barcodeController;
  late TextEditingController productController;
  late TextEditingController categoryController;
  late TextEditingController buyingController;
  late TextEditingController sellingController;
  late TextEditingController stockController;
  late TextEditingController supplierController;

  DateTime? selectedExpirationDate;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    barcodeController = TextEditingController(
      text: (widget.product['barcode'] ?? '').toString(),
    );
    productController = TextEditingController(
      text: (widget.product['productName'] ?? '').toString(),
    );
    categoryController = TextEditingController(
      text: (widget.product['category'] ?? '').toString(),
    );
    buyingController = TextEditingController(
      text: (widget.product['buyingPrice'] ?? 0).toString(),
    );
    sellingController = TextEditingController(
      text: (widget.product['sellingPrice'] ?? 0).toString(),
    );
    stockController = TextEditingController(
      text: (widget.product['stock'] ?? 0).toString(),
    );
    supplierController = TextEditingController(
      text: (widget.product['supplier'] ?? '').toString(),
    );

    final expiration = widget.product['expirationDate'];
    if (expiration is Timestamp) {
      selectedExpirationDate = expiration.toDate();
    } else if (expiration is DateTime) {
      selectedExpirationDate = expiration;
    } else if (expiration is String) {
      selectedExpirationDate = DateTime.tryParse(expiration);
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    productController.dispose();
    categoryController.dispose();
    buyingController.dispose();
    sellingController.dispose();
    stockController.dispose();
    supplierController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select expiration date';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedExpirationDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() => selectedExpirationDate = picked);
    }
  }

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final oldStock = (widget.product['stock'] as num?)?.toInt() ?? 0;
    final newStock = int.tryParse(stockController.text.trim()) ?? 0;

    DateTime? oldExpiration;
    final oldExpirationValue = widget.product['expirationDate'];
    if (oldExpirationValue is Timestamp) {
      oldExpiration = oldExpirationValue.toDate();
    } else if (oldExpirationValue is DateTime) {
      oldExpiration = oldExpirationValue;
    } else if (oldExpirationValue is String) {
      oldExpiration = DateTime.tryParse(oldExpirationValue);
    }

    final bool stockChanged = oldStock != newStock;
    final bool expirationChanged =
        oldExpiration?.year != selectedExpirationDate?.year ||
        oldExpiration?.month != selectedExpirationDate?.month ||
        oldExpiration?.day != selectedExpirationDate?.day;

    final bool restocked = newStock > oldStock;
    final String changeType = restocked
        ? 'restocked'
        : stockChanged
        ? 'stockUpdated'
        : expirationChanged
        ? 'expirationUpdated'
        : 'productUpdated';

    setState(() => loading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final productRef = firestore
          .collection('products')
          .doc(widget.documentId);
      final notificationRef = firestore.collection('notifications').doc();
      final batch = firestore.batch();

      batch.update(productRef, {
        'barcode': barcodeController.text.trim(),
        'productName': productController.text.trim(),
        'category': categoryController.text.trim(),
        'buyingPrice': double.tryParse(buyingController.text.trim()) ?? 0,
        'sellingPrice': double.tryParse(sellingController.text.trim()) ?? 0,
        'stock': newStock,
        'supplier': supplierController.text.trim(),
        'expirationDate': selectedExpirationDate == null
            ? null
            : Timestamp.fromDate(selectedExpirationDate!),
        'previousStock': oldStock,
        'lastChangeType': changeType,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final productName = productController.text.trim();
      final message = restocked
          ? '$productName was restocked from $oldStock to $newStock.'
          : stockChanged
          ? '$productName stock changed from $oldStock to $newStock.'
          : expirationChanged
          ? '$productName expiration date was updated.'
          : '$productName information was updated.';

      batch.set(notificationRef, {
        'title': restocked
            ? 'Product Restocked'
            : stockChanged
            ? 'Stock Updated'
            : expirationChanged
            ? 'Expiration Updated'
            : 'Product Updated',
        'message': message,
        'type': changeType,
        'productId': widget.documentId,
        'targetRole': 'all',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit / Restock Product'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: barcodeController,
              decoration: _decoration('Barcode', icon: Icons.qr_code),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: productController,
              decoration: _decoration('Product Name', icon: Icons.inventory_2),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: categoryController,
              decoration: _decoration('Category', icon: Icons.category),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: buyingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                'Buying Price',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: sellingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _decoration(
                'Selling Price',
                icon: Icons.sell_outlined,
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: _decoration('New Stock', icon: Icons.add_box),
              validator: (value) {
                final stock = int.tryParse(value ?? '');
                if (stock == null || stock < 0) {
                  return 'Enter a valid stock quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: _pickExpirationDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: _decoration(
                  'New Expiration Date',
                  icon: Icons.event,
                ),
                child: Text(_formatDate(selectedExpirationDate)),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: supplierController,
              decoration: _decoration(
                'Supplier',
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: loading ? null : updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  loading ? 'UPDATING...' : 'UPDATE / RESTOCK PRODUCT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
