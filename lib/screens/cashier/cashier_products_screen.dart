import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CashierProductsScreen extends StatefulWidget {
  const CashierProductsScreen({super.key});

  @override
  State<CashierProductsScreen> createState() => _CashierProductsScreenState();
}

class _CashierProductsScreenState extends State<CashierProductsScreen> {
  final TextEditingController searchController = TextEditingController();

  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('View Products'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search Product or Barcode',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final products = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final productName = (data['productName'] ?? '')
                      .toString()
                      .toLowerCase();

                  final barcode = (data['barcode'] ?? '')
                      .toString()
                      .toLowerCase();

                  if (search.isEmpty) {
                    return true;
                  }

                  return productName.contains(search) ||
                      barcode.contains(search);
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data = products[index].data() as Map<String, dynamic>;

                    final productName =
                        (data['productName'] ?? 'Unknown Product').toString();

                    final barcode = (data['barcode'] ?? '').toString();

                    final category = (data['category'] ?? '').toString();

                    final price =
                        (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                    final stock = (data['stock'] as num?)?.toInt() ?? 0;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.inventory_2,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '₱${price.toStringAsFixed(2)} | Stock: $stock',
                                  ),
                                  if (category.isNotEmpty)
                                    Text(
                                      'Category: $category',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  if (barcode.isNotEmpty)
                                    Text(
                                      'Barcode: $barcode',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
