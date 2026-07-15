import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'import_products_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController searchController = TextEditingController();

  String search = '';

  Future<void> confirmDelete({
    required String documentId,
    required String productName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete $productName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportProductsScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        tooltip: 'Add Product',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search product or barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            search = '';
                          });
                        },
                      ),
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

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading products:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final products = snapshot.data?.docs ?? [];

                  final filteredProducts = products.where((doc) {
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
                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No products found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      final data = product.data() as Map<String, dynamic>;

                      final productName =
                          (data['productName'] ?? 'Unknown Product').toString();

                      final barcode = (data['barcode'] ?? '').toString();

                      final category = (data['category'] ?? '').toString();

                      final supplier = (data['supplier'] ?? '').toString();

                      final buyingPrice =
                          (data['buyingPrice'] as num?)?.toDouble() ?? 0;

                      final sellingPrice =
                          (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                      final stock = (data['stock'] as num?)?.toInt() ?? 0;

                      final bool isLowStock = stock <= 5;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Colors.blue,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 5),

                                        Text(
                                          category.isEmpty
                                              ? 'Uncategorized'
                                              : category,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isLowStock ? 'Low Stock' : 'In Stock',
                                      style: TextStyle(
                                        color: isLowStock
                                            ? Colors.red.shade800
                                            : Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              const Divider(),

                              const SizedBox(height: 8),

                              Text(
                                'Barcode: ${barcode.isEmpty ? 'N/A' : barcode}',
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Buying Price: ₱${buyingPrice.toStringAsFixed(2)}',
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Selling Price: ₱${sellingPrice.toStringAsFixed(2)}',
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Stock: $stock',
                                style: TextStyle(
                                  color: isLowStock
                                      ? Colors.red
                                      : Colors.black87,
                                  fontWeight: isLowStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                'Supplier: ${supplier.isEmpty ? 'N/A' : supplier}',
                              ),

                              const SizedBox(height: 15),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    label: const Text('Edit'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProductScreen(
                                            documentId: product.id,
                                            product: data,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    label: const Text('Delete'),
                                    onPressed: () {
                                      confirmDelete(
                                        documentId: product.id,
                                        productName: productName,
                                      );
                                    },
                                  ),
                                ],
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
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
