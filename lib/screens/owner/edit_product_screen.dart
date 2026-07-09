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

  bool loading = false;

  @override
  void initState() {
    super.initState();

    barcodeController = TextEditingController(text: widget.product["barcode"]);

    productController = TextEditingController(
      text: widget.product["productName"],
    );

    categoryController = TextEditingController(
      text: widget.product["category"],
    );

    buyingController = TextEditingController(
      text: widget.product["buyingPrice"].toString(),
    );

    sellingController = TextEditingController(
      text: widget.product["sellingPrice"].toString(),
    );

    stockController = TextEditingController(
      text: widget.product["stock"].toString(),
    );

    supplierController = TextEditingController(
      text: widget.product["supplier"],
    );
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

  Future<void> updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection("products")
          .doc(widget.documentId)
          .update({
            "barcode": barcodeController.text.trim(),
            "productName": productController.text.trim(),
            "category": categoryController.text.trim(),
            "buyingPrice": double.tryParse(buyingController.text.trim()) ?? 0,
            "sellingPrice": double.tryParse(sellingController.text.trim()) ?? 0,
            "stock": int.tryParse(stockController.text.trim()) ?? 0,
            "supplier": supplierController.text.trim(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
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
              decoration: const InputDecoration(
                labelText: "Barcode",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: productController,
              decoration: const InputDecoration(
                labelText: "Product Name",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: buyingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Buying Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: sellingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Selling Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextFormField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: "Supplier",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: loading ? null : updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "UPDATE PRODUCT",
                        style: TextStyle(
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
