import 'dart:async';
import 'dart:math';

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
  final List<String> recentSearches = [];

  String search = '';
  bool isProcessing = false;
  Timer? _searchDebounce;

  double get total => cart.fold(0, (sum, item) => sum + item.subtotal);

  double get cash => double.tryParse(cashController.text.trim()) ?? 0;

  double get change => cash >= total ? cash - total : 0;

  int get cartItemCount => cart.fold(0, (sum, item) => sum + item.quantity);

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => search = value.trim().toLowerCase());
    });
  }

  void _saveRecentSearch(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    recentSearches.removeWhere(
      (item) => item.toLowerCase() == clean.toLowerCase(),
    );
    recentSearches.insert(0, clean);
    if (recentSearches.length > 5) recentSearches.removeLast();
  }

  void _selectRecentSearch(String value) {
    searchController.text = value;
    setState(() => search = value.trim().toLowerCase());
  }

  void _clearSearch() {
    searchController.clear();
    setState(() => search = '');
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
      setState(() => cart[index].quantity++);
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

    if (scannedCode == null || scannedCode.trim().isEmpty) return;
    final cleanCode = scannedCode.trim();

    if (!mounted) return;
    searchController.text = cleanCode;
    setState(() => search = cleanCode.toLowerCase());

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode $cleanCode was not found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final product = snapshot.docs.first;
      final data = product.data();

      addToCart(
        id: product.id,
        productName: (data['productName'] ?? 'Unknown Product').toString(),
        price: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
        stock: (data['stock'] as num?)?.toInt() ?? 0,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void increaseQty(int index) {
    if (index < 0 || index >= cart.length) return;
    setState(() => cart[index].quantity++);
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
      setState(() => isProcessing = true);

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
    } catch (error) {
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction failed: $error'),
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
                      onChanged: (_) => setBottomState(() {}),
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

  List<_ProductSearchResult> _rankProducts(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final query = search.trim().toLowerCase();
    final products = docs.map(_productFromDocument).toList();

    if (query.isEmpty) {
      return products
          .map(
            (product) => _ProductSearchResult(
              product: product,
              score: 0,
              matchLabel: '',
            ),
          )
          .toList();
    }

    final ranked = <_ProductSearchResult>[];
    for (final product in products) {
      final result = _calculateSearchScore(product, query);
      if (result.score >= 28) ranked.add(result);
    }

    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  _ProductData _productFromDocument(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _ProductData(
      id: doc.id,
      productName: (data['productName'] ?? 'Unknown Product').toString(),
      barcode: (data['barcode'] ?? '').toString(),
      brand: (data['brand'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }

  _ProductSearchResult _calculateSearchScore(
    _ProductData product,
    String query,
  ) {
    final name = _normalize(product.productName);
    final brand = _normalize(product.brand);
    final category = _normalize(product.category);
    final barcode = product.barcode.toLowerCase();
    final normalizedQuery = _normalize(query);

    double score;
    String label;

    if (barcode == query || barcode == normalizedQuery) {
      score = 100;
      label = 'Barcode Match';
    } else if (name == normalizedQuery) {
      score = 98;
      label = 'Exact Match';
    } else if (name.startsWith(normalizedQuery)) {
      score = 92;
      label = 'Starts With';
    } else if (name.contains(normalizedQuery)) {
      score = 88;
      label = 'Name Match';
    } else if (brand == normalizedQuery && brand.isNotEmpty) {
      score = 84;
      label = 'Brand Match';
    } else if (category == normalizedQuery && category.isNotEmpty) {
      score = 80;
      label = 'Category Match';
    } else if (brand.contains(normalizedQuery) && brand.isNotEmpty) {
      score = 75;
      label = 'Brand Match';
    } else if (category.contains(normalizedQuery) && category.isNotEmpty) {
      score = 72;
      label = 'Category Match';
    } else {
      final nameSimilarity = _similarity(name, normalizedQuery);
      final brandSimilarity = brand.isEmpty
          ? 0
          : _similarity(brand, normalizedQuery);
      final categorySimilarity = category.isEmpty
          ? 0
          : _similarity(category, normalizedQuery);
      score =
          max(nameSimilarity, max(brandSimilarity, categorySimilarity)) * 100;

      if (score >= 70) {
        label = 'Possible Typo Match';
      } else if (score >= 50) {
        label = 'Suggested Match';
      } else {
        label = 'Related Match';
      }

      final queryWords = normalizedQuery.split(' ');
      final nameWords = name.split(' ');
      int matchedWords = 0;

      for (final queryWord in queryWords) {
        if (queryWord.isEmpty) continue;
        for (final nameWord in nameWords) {
          if (_similarity(queryWord, nameWord) >= 0.65) {
            matchedWords++;
            break;
          }
        }
      }

      if (queryWords.isNotEmpty) {
        score += (matchedWords / queryWords.length) * 18;
      }
      score = min(score, 79);
    }

    return _ProductSearchResult(
      product: product,
      score: score,
      matchLabel: label,
    );
  }

  List<_ProductData> _buildSuggestions(
    List<_ProductSearchResult> rankedResults,
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    if (rankedResults.isEmpty) return [];
    final best = rankedResults.first.product;
    final allProducts = docs.map(_productFromDocument).toList();

    final suggestions = allProducts.where((product) {
      if (product.id == best.id || product.stock <= 0) return false;
      final sameCategory =
          best.category.isNotEmpty &&
          product.category.toLowerCase() == best.category.toLowerCase();
      final sameBrand =
          best.brand.isNotEmpty &&
          product.brand.toLowerCase() == best.brand.toLowerCase();
      return sameCategory || sameBrand;
    }).toList();

    suggestions.sort((a, b) {
      final aScore =
          (a.category.toLowerCase() == best.category.toLowerCase() ? 2 : 0) +
          (a.brand.toLowerCase() == best.brand.toLowerCase() ? 1 : 0);
      final bScore =
          (b.category.toLowerCase() == best.category.toLowerCase() ? 2 : 0) +
          (b.brand.toLowerCase() == best.brand.toLowerCase() ? 1 : 0);
      return bScore.compareTo(aScore);
    });

    return suggestions.take(5).toList();
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _similarity(String first, String second) {
    if (first.isEmpty && second.isEmpty) return 1;
    if (first.isEmpty || second.isEmpty) return 0;
    final distance = _levenshteinDistance(first, second);
    return 1 - (distance / max(first.length, second.length));
  }

  int _levenshteinDistance(String first, String second) {
    final matrix = List.generate(
      first.length + 1,
      (_) => List<int>.filled(second.length + 1, 0),
    );

    for (int i = 0; i <= first.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= second.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= first.length; i++) {
      for (int j = 1; j <= second.length; j++) {
        final cost = first[i - 1] == second[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          matrix[i - 1][j] + 1,
          min(matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost),
        );
      }
    }

    return matrix[first.length][second.length];
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search product, brand, category, or barcode',
              prefixIcon: const Icon(Icons.auto_awesome),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: _clearSearch,
                    ),
                  IconButton(
                    tooltip: 'Scan barcode',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: scanBarcode,
                  ),
                ],
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _handleSearchChanged(value);
            },
            onSubmitted: (value) {
              _saveRecentSearch(value);
              setState(() => search = value.trim().toLowerCase());
            },
          ),
          if (recentSearches.isNotEmpty && search.isEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Recent:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...recentSearches.map(
                    (item) => ActionChip(
                      label: Text(item),
                      avatar: const Icon(Icons.history, size: 16),
                      onPressed: () => _selectRecentSearch(item),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductImage(_ProductData product) {
    if (product.imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          product.imageUrl,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        ),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF1565C0),
        size: 31,
      ),
    );
  }

  Widget _buildProductCard({
    required _ProductData product,
    String? badge,
    double? matchScore,
    bool highlighted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highlighted ? 5 : 2,
      color: highlighted ? const Color(0xFFFFF8E1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlighted
            ? const BorderSide(color: Colors.amber, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildProductImage(product),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? Colors.amber.shade100
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        matchScore == null
                            ? badge
                            : '$badge • ${matchScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: highlighted
                              ? Colors.orange.shade900
                              : const Color(0xFF1565C0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '₱${product.sellingPrice.toStringAsFixed(2)} • Stock: ${product.stock}',
                    style: TextStyle(
                      color: product.stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.brand.isNotEmpty ||
                      product.category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (product.brand.isNotEmpty) product.brand,
                        if (product.category.isNotEmpty) product.category,
                      ].join(' • '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (product.barcode.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Barcode: ${product.barcode}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 75,
              height: 42,
              child: ElevatedButton(
                onPressed: product.stock > 0
                    ? () {
                        addToCart(
                          id: product.id,
                          productName: product.productName,
                          price: product.sellingPrice,
                          stock: product.stock,
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  product.stock > 0 ? 'ADD' : 'OUT',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedProductCard(_ProductData product) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: product.stock > 0
              ? () {
                  addToCart(
                    id: product.id,
                    productName: product.productName,
                    price: product.sellingPrice,
                    stock: product.stock,
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(product),
                const SizedBox(height: 10),
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '₱${product.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.stock > 0
                      ? 'Stock: ${product.stock}'
                      : 'Out of stock',
                  style: TextStyle(
                    color: product.stock > 0 ? Colors.grey : Colors.red,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<QueryDocumentSnapshot<Object?>> docs) {
    final rankedResults = _rankProducts(docs);

    if (search.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildSectionTitle('Available Products', Icons.inventory_2_outlined),
          ...rankedResults.map(
            (result) => _buildProductCard(product: result.product),
          ),
          const SizedBox(height: 90),
        ],
      );
    }

    if (rankedResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 70, color: Colors.grey),
              const SizedBox(height: 15),
              const Text(
                'No close match found',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 7),
              Text(
                'Try another spelling, product brand, category, or barcode.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final bestMatch = rankedResults.first;
    final suggestions = _buildSuggestions(rankedResults, docs);
    final remainingResults = rankedResults.skip(1).take(15).toList();

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildSectionTitle('AI Best Match', Icons.auto_awesome),
        _buildProductCard(
          product: bestMatch.product,
          badge: bestMatch.matchLabel,
          matchScore: bestMatch.score,
          highlighted: true,
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSectionTitle('Suggested Products', Icons.lightbulb_outline),
          SizedBox(
            height: 205,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _buildSuggestedProductCard(suggestions[index]),
            ),
          ),
        ],
        if (remainingResults.isNotEmpty) ...[
          const SizedBox(height: 18),
          _buildSectionTitle('More Results', Icons.search),
          ...remainingResults.map(
            (result) => _buildProductCard(
              product: result.product,
              badge: result.matchLabel,
              matchScore: result.score,
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
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
        label: Text('Cart ($cartItemCount)'),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Object?>>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
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

                final docs =
                    snapshot.data?.docs ?? <QueryDocumentSnapshot<Object?>>[];
                return _buildSearchResults(docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    cashController.dispose();
    super.dispose();
  }
}

class _ProductData {
  const _ProductData({
    required this.id,
    required this.productName,
    required this.barcode,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.sellingPrice,
    required this.stock,
  });

  final String id;
  final String productName;
  final String barcode;
  final String brand;
  final String category;
  final String imageUrl;
  final double sellingPrice;
  final int stock;
}

class _ProductSearchResult {
  const _ProductSearchResult({
    required this.product,
    required this.score,
    required this.matchLabel,
  });

  final _ProductData product;
  final double score;
  final String matchLabel;
}
