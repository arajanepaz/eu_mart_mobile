import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../services/transaction_service.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TransactionService transactionService = TransactionService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController cashController = TextEditingController();

  final List<CartItem> cart = [];
  String search = '';

  double get total {
    double sum = 0;
    for (final item in cart) {
      sum += item.subtotal;
    }
    return sum;
  }

  double get cash {
    return double.tryParse(cashController.text.trim()) ?? 0;
  }

  double get change {
    if (cash < total) return 0;
    return cash - total;
  }

  void addToCart({
    required String id,
    required String productName,
    required double price,
  }) {
    final index = cart.indexWhere((item) => item.id == id);

    setState(() {
      if (index == -1) {
        cart.add(CartItem(id: id, productName: productName, price: price));
      } else {
        cart[index].quantity++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void increaseQty(int index) {
    setState(() {
      cart[index].quantity++;
    });
  }

  void decreaseQty(int index) {
    setState(() {
      if (cart[index].quantity <= 1) {
        cart.removeAt(index);
      } else {
        cart[index].quantity--;
      }
    });
  }

  Future<void> payNow() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty.')));
      return;
    }

    if (cash < total) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Insufficient cash.')));
      return;
    }

    try {
      await transactionService.saveTransaction(
        cart: cart,
        total: total,
        cash: cash,
        change: change,
      );

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        cart.clear();
        cashController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction completed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: cart.isEmpty
                        ? const Center(child: Text('No items in cart'))
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final item = cart[index];

                              return Card(
                                child: ListTile(
                                  title: Text(item.productName),
                                  subtitle: Text(
                                    '₱${item.subtotal.toStringAsFixed(2)}',
                                  ),
                                  leading: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      decreaseQty(index);
                                      setBottomState(() {});
                                    },
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.quantity.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: Colors.green,
                                        ),
                                        onPressed: () {
                                          increaseQty(index);
                                          setBottomState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cash Received',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setBottomState(() {});
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₱${change.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                      ),
                      onPressed: payNow,
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> filterProducts(List<QueryDocumentSnapshot> docs) {
    if (search.isEmpty) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final productName = (data['productName'] ?? '').toString().toLowerCase();
      final barcode = (data['barcode'] ?? '').toString().toLowerCase();

      return productName.contains(search) || barcode.contains(search);
    }).toList();
  }

  Widget buildProductList(List<QueryDocumentSnapshot> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final data = product.data() as Map<String, dynamic>;

        final id = product.id;
        final productName = (data['productName'] ?? 'No name').toString();
        final price = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final barcode = (data['barcode'] ?? '').toString();

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.inventory_2, color: Colors.blue),
            ),
            title: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₱${price.toStringAsFixed(2)} | Stock: $stock'),
                if (barcode.isNotEmpty)
                  Text(
                    'Barcode: $barcode',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: stock <= 0
                  ? null
                  : () {
                      addToCart(id: id, productName: productName, price: price);
                    },
              child: const Text('ADD'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('New Transaction'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: openCart,
        icon: const Icon(Icons.shopping_cart),
        label: Text('Cart (${cart.length})'),
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
              stream: firestore.collection('products').snapshots(),
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

                final docs = snapshot.data?.docs ?? [];
                final products = filterProducts(docs);

                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return buildProductList(products);
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
    cashController.dispose();
    super.dispose();
  }
}
