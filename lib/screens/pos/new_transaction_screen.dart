import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../services/transaction_service.dart';
import '../cashier/receipt_screen.dart';
import 'barcode_scanner_screen.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController cashController = TextEditingController();

  final List<CartItem> cart = [];

  String search = '';
  bool isProcessing = false;

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
    if (cash >= total) {
      return cash - total;
    }

    return 0;
  }

  void addToCart({
    required String id,
    required String productName,
    required double price,
    required int stock,
  }) {
    final index = cart.indexWhere((item) => item.id == id);

    if (index == -1) {
      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This product is out of stock.')),
        );
        return;
      }

      setState(() {
        cart.add(CartItem(id: id, productName: productName, price: price));
      });
    } else {
      if (cart[index].quantity >= stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $stock stock available for $productName.'),
          ),
        );
        return;
      }

      setState(() {
        cart[index].quantity++;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName added to cart.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    final cleanCode = scannedCode.trim();

    if (!mounted) return;

    searchController.text = cleanCode;

    setState(() {
      search = cleanCode.toLowerCase();
    });

    try {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (productSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode $cleanCode was not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = productSnapshot.docs.first;
      final data = product.data();

      final productName = (data['productName'] ?? 'Unknown Product').toString();

      final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;

      final stock = (data['stock'] as num?)?.toInt() ?? 0;

      addToCart(
        id: product.id,
        productName: productName,
        price: sellingPrice,
        stock: stock,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void increaseQty(int index) {
    if (index < 0 || index >= cart.length) return;

    setState(() {
      cart[index].quantity++;
    });
  }

  void decreaseQty(int index) {
    if (index < 0 || index >= cart.length) return;

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
      setState(() {
        isProcessing = true;
      });

      final receiptItems = cart
          .map(
            (item) => CartItem(
              id: item.id,
              productName: item.productName,
              price: item.price,
              quantity: item.quantity,
            ),
          )
          .toList();

      final receiptTotal = total;
      final receiptCash = cash;
      final receiptChange = change;
      final transactionDate = DateTime.now();

      final transactionId = transactionDate.millisecondsSinceEpoch.toString();

      await TransactionService().saveTransaction(
        cart: cart,
        total: receiptTotal,
        cash: receiptCash,
        change: receiptChange,
      );

      if (!mounted) return;

      // Close the cart bottom sheet.
      Navigator.pop(context);

      setState(() {
        cart.clear();
        cashController.clear();
        searchController.clear();
        search = '';
        isProcessing = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            cart: receiptItems,
            total: receiptTotal,
            cash: receiptCash,
            change: receiptChange,
            transactionId: transactionId,
            transactionDate: transactionDate,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed: $e'),
          backgroundColor: Colors.red,
        ),
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
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return SafeArea(
              child: Padding(
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '₱${item.subtotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            decreaseQty(index);
                                            setBottomState(() {});
                                          },
                                        ),

                                        Text(
                                          item.quantity.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cash Received',
                        prefixIcon: Icon(Icons.payments),
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
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isProcessing ? null : payNow,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(
                          isProcessing ? 'PROCESSING...' : 'PAY NOW',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: scanBarcode,
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

                final filteredProducts = docs.where((doc) {
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
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];

                    final data = product.data() as Map<String, dynamic>;

                    final productName =
                        (data['productName'] ?? 'Unknown Product').toString();

                    final barcode = (data['barcode'] ?? '').toString();

                    final sellingPrice =
                        (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                    final stock = (data['stock'] as num?)?.toInt() ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
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
                                  const SizedBox(height: 6),
                                  Text(
                                    '₱${sellingPrice.toStringAsFixed(2)} | Stock: $stock',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Barcode: $barcode',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            SizedBox(
                              width: 75,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: stock > 0
                                    ? () {
                                        addToCart(
                                          id: product.id,
                                          productName: productName,
                                          price: sellingPrice,
                                          stock: stock,
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  stock > 0 ? 'ADD' : 'OUT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    cashController.dispose();
    super.dispose();
  }
}
