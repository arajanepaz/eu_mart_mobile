import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'import_products_screen.dart';

class InventoryScreen extends StatefulWidget {
  final String initialFilter;

  const InventoryScreen({super.key, this.initialFilter = 'all'});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController searchController = TextEditingController();

  String search = '';
  late String selectedFilter;
  bool _deletingAllProducts = false;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  String _filterTitle() {
    switch (selectedFilter) {
      case 'lowStock':
        return 'Low Stock Products';
      case 'expired':
        return 'Expired Products';
      case 'expiringSoon':
        return 'Expiring Soon';
      case 'recentlyUpdated':
        return 'Recently Updated';
      default:
        return 'All Products';
    }
  }

  Future<void> confirmDelete({
    required String documentId,
    required String productName,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('Delete Product')),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$productName"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
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
        SnackBar(
          content: Text('"$productName" was deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting product: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteAllProducts() async {
    final bool? firstConfirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text('Delete All Products')),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete ALL products from the inventory?\n\n'
            'This will permanently remove every product record.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (firstConfirmation != true || !mounted) return;

    final bool? finalConfirmation = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Final Confirmation',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'This action cannot be undone.\n\n'
            'Delete all products now?',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No, Go Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Yes, Delete All'),
            ),
          ],
        );
      },
    );

    if (finalConfirmation != true || !mounted) return;

    setState(() {
      _deletingAllProducts = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Deleting all products...\nPlease wait.')),
            ],
          ),
        );
      },
    );

    try {
      final CollectionReference<Map<String, dynamic>> productsCollection =
          FirebaseFirestore.instance.collection('products');

      int deletedCount = 0;

      while (true) {
        final QuerySnapshot<Map<String, dynamic>> snapshot =
            await productsCollection.limit(400).get();

        if (snapshot.docs.isEmpty) {
          break;
        }

        final WriteBatch batch = FirebaseFirestore.instance.batch();

        for (final document in snapshot.docs) {
          batch.delete(document.reference);
        }

        await batch.commit();

        deletedCount += snapshot.docs.length;
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deletedCount products were deleted successfully.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete all products: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingAllProducts = false;
        });
      }
    }
  }

  Color getStatusBackgroundColor({
    required bool isOutOfStock,
    required bool isLowStock,
  }) {
    if (isOutOfStock) {
      return Colors.red.shade100;
    }

    if (isLowStock) {
      return Colors.orange.shade100;
    }

    return Colors.green.shade100;
  }

  Color getStatusTextColor({
    required bool isOutOfStock,
    required bool isLowStock,
  }) {
    if (isOutOfStock) {
      return Colors.red.shade800;
    }

    if (isLowStock) {
      return Colors.orange.shade800;
    }

    return Colors.green.shade800;
  }

  String getStatusText({required bool isOutOfStock, required bool isLowStock}) {
    if (isOutOfStock) {
      return 'Out of Stock';
    }

    if (isLowStock) {
      return 'Low Stock';
    }

    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Inventory • ${_filterTitle()}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Delete All Products',
            icon: _deletingAllProducts
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_sweep),
            onPressed: _deletingAllProducts ? null : deleteAllProducts,
          ),
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: _deletingAllProducts
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportProductsScreen(),
                      ),
                    );
                  },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        tooltip: 'Add Product',
        onPressed: _deletingAllProducts
            ? null
            : () {
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
              enabled: !_deletingAllProducts,
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
                filled: true,
                fillColor: Colors.white,
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
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in const [
                    ('all', 'All'),
                    ('lowStock', 'Low Stock'),
                    ('expired', 'Expired'),
                    ('expiringSoon', 'Expiring Soon'),
                    ('recentlyUpdated', 'Recently Updated'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.$2),
                        selected: selectedFilter == filter.$1,
                        onSelected: (_) {
                          setState(() => selectedFilter = filter.$1);
                        },
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: selectedFilter == filter.$1
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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

                  final filteredProducts = products.where((document) {
                    final data = document.data() as Map<String, dynamic>;

                    final productName = (data['productName'] ?? '')
                        .toString()
                        .toLowerCase();

                    final barcode = (data['barcode'] ?? '')
                        .toString()
                        .toLowerCase();

                    final matchesSearch =
                        search.isEmpty ||
                        productName.contains(search) ||
                        barcode.contains(search);

                    if (!matchesSearch) return false;

                    final int stock = (data['stock'] as num?)?.toInt() ?? 0;
                    final DateTime? expiration = _readDate(
                      data['expirationDate'],
                    );
                    final DateTime? updatedAt = _readDate(data['updatedAt']);
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    switch (selectedFilter) {
                      case 'lowStock':
                        return stock <= 10;
                      case 'expired':
                        if (expiration == null) return false;
                        final expiryDay = DateTime(
                          expiration.year,
                          expiration.month,
                          expiration.day,
                        );
                        return expiryDay.isBefore(today);
                      case 'expiringSoon':
                        if (expiration == null) return false;
                        final expiryDay = DateTime(
                          expiration.year,
                          expiration.month,
                          expiration.day,
                        );
                        final days = expiryDay.difference(today).inDays;
                        return days >= 0 && days <= 7;
                      case 'recentlyUpdated':
                        if (updatedAt == null) return false;
                        return now.difference(updatedAt).inHours <= 24;
                      default:
                        return true;
                    }
                  }).toList();

                  if (filteredProducts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 70,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No products found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      final data = product.data() as Map<String, dynamic>;

                      final String productName =
                          (data['productName'] ?? 'Unknown Product').toString();

                      final String barcode = (data['barcode'] ?? '').toString();

                      final String category = (data['category'] ?? '')
                          .toString();

                      final String supplier = (data['supplier'] ?? '')
                          .toString();

                      final double buyingPrice =
                          (data['buyingPrice'] as num?)?.toDouble() ?? 0;

                      final double sellingPrice =
                          (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                      final int stock = (data['stock'] as num?)?.toInt() ?? 0;
                      final DateTime? updatedAt = _readDate(data['updatedAt']);
                      final bool recentlyUpdated =
                          updatedAt != null &&
                          DateTime.now().difference(updatedAt).inHours <= 24;
                      final String lastChangeType =
                          (data['lastChangeType'] ?? '').toString();

                      final bool isOutOfStock = stock <= 0;
                      final bool isLowStock = stock > 0 && stock <= 10;

                      final Color statusBackground = getStatusBackgroundColor(
                        isOutOfStock: isOutOfStock,
                        isLowStock: isLowStock,
                      );

                      final Color statusTextColor = getStatusTextColor(
                        isOutOfStock: isOutOfStock,
                        isLowStock: isLowStock,
                      );

                      final String statusText = getStatusText(
                        isOutOfStock: isOutOfStock,
                        isLowStock: isLowStock,
                      );

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
                                      color: statusBackground,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusTextColor,
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
                                  color: isOutOfStock
                                      ? Colors.red
                                      : isLowStock
                                      ? Colors.orange.shade800
                                      : Colors.black87,
                                  fontWeight: isOutOfStock || isLowStock
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (isOutOfStock) ...[
                                const SizedBox(height: 6),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Product unavailable',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (isLowStock) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange.shade800,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reorder soon',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                                    onPressed: _deletingAllProducts
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    EditProductScreen(
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
                                    onPressed: _deletingAllProducts
                                        ? null
                                        : () {
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
