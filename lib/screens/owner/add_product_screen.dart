import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final barcodeController = TextEditingController();
  final productNameController = TextEditingController();
  final buyingPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final stockController = TextEditingController();
  final supplierController = TextEditingController();

  bool isLoading = false;

  String selectedCategory = "Beverages";

  final List<String> categories = [
    "Beverages",
    "Canned Goods",
    "Snacks",
    "Dairy",
    "Frozen Foods",
    "Rice",
    "Noodles",
    "Personal Care",
    "Household",
    "Others",
  ];

  Future<void> saveProduct() async {
    if (barcodeController.text.isEmpty ||
        productNameController.text.isEmpty ||
        buyingPriceController.text.isEmpty ||
        sellingPriceController.text.isEmpty ||
        stockController.text.isEmpty ||
        supplierController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance.collection("products").add({
        "barcode": barcodeController.text.trim(),

        "productName": productNameController.text.trim(),

        "category": selectedCategory,

        "buyingPrice": double.parse(buyingPriceController.text),

        "sellingPrice": double.parse(sellingPriceController.text),

        "stock": int.parse(stockController.text),

        "supplier": supplierController.text.trim(),

        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product added successfully.")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: const Color(0xff1565C0),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(
                labelText: "Barcode",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: productNameController,
              decoration: const InputDecoration(
                labelText: "Product Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: buyingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Buying Price",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: sellingPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Selling Price",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Stock",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: "Supplier",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
              ),
            ),

            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE PRODUCT",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    barcodeController.dispose();
    productNameController.dispose();
    buyingPriceController.dispose();
    sellingPriceController.dispose();
    stockController.dispose();
    supplierController.dispose();
    super.dispose();
  }
}
