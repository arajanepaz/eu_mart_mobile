import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductMetadataMigrationScreen extends StatefulWidget {
  const ProductMetadataMigrationScreen({super.key});

  @override
  State<ProductMetadataMigrationScreen> createState() =>
      _ProductMetadataMigrationScreenState();
}

class _ProductMetadataMigrationScreenState
    extends State<ProductMetadataMigrationScreen> {
  bool _loading = true;
  bool _running = false;

  int _totalProducts = 0;
  int _missingBrand = 0;
  int _missingCategory = 0;
  int _missingImageUrl = 0;
  int _updatedProducts = 0;

  String _statusMessage = 'Checking product records...';

  final CollectionReference<Map<String, dynamic>> _productsRef =
      FirebaseFirestore.instance.collection('products');

  @override
  void initState() {
    super.initState();
    _scanProducts();
  }

  Future<void> _scanProducts() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Checking product records...';
    });

    try {
      final snapshot = await _productsRef.get();

      int missingBrand = 0;
      int missingCategory = 0;
      int missingImageUrl = 0;

      for (final document in snapshot.docs) {
        final data = document.data();

        if (_isMissing(data['brand'])) {
          missingBrand++;
        }

        if (_isMissing(data['category'])) {
          missingCategory++;
        }

        if (!data.containsKey('imageUrl')) {
          missingImageUrl++;
        }
      }

      if (!mounted) return;

      setState(() {
        _totalProducts = snapshot.docs.length;
        _missingBrand = missingBrand;
        _missingCategory = missingCategory;
        _missingImageUrl = missingImageUrl;
        _loading = false;
        _statusMessage = 'Product scan completed.';
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _statusMessage =
            'Unable to scan products: ${error.message ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _statusMessage = 'Unable to scan products: $error';
      });
    }
  }

  Future<void> _runMigration() async {
    final bool confirmed = await _showConfirmationDialog();

    if (!confirmed) return;

    setState(() {
      _running = true;
      _updatedProducts = 0;
      _statusMessage = 'Updating product metadata...';
    });

    try {
      final snapshot = await _productsRef.get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int operationsInBatch = 0;
      int updatedProducts = 0;

      for (final document in snapshot.docs) {
        final data = document.data();
        final productName = (data['productName'] ?? data['name'] ?? '')
            .toString()
            .trim();

        final Map<String, dynamic> updates = {};

        if (_isMissing(data['brand'])) {
          updates['brand'] = _detectBrand(productName);
        }

        if (_isMissing(data['category'])) {
          updates['category'] = _detectCategory(productName);
        }

        if (!data.containsKey('imageUrl')) {
          updates['imageUrl'] = '';
        }

        if (updates.isEmpty) {
          continue;
        }

        updates['metadataUpdatedAt'] = FieldValue.serverTimestamp();

        batch.update(document.reference, updates);
        operationsInBatch++;
        updatedProducts++;

        if (operationsInBatch >= 450) {
          await batch.commit();

          batch = FirebaseFirestore.instance.batch();
          operationsInBatch = 0;

          if (mounted) {
            setState(() {
              _updatedProducts = updatedProducts;
              _statusMessage =
                  'Updated $updatedProducts of ${snapshot.docs.length} products...';
            });
          }
        }
      }

      if (operationsInBatch > 0) {
        await batch.commit();
      }

      if (!mounted) return;

      setState(() {
        _updatedProducts = updatedProducts;
        _running = false;
        _statusMessage =
            'Migration completed. $updatedProducts product records were updated.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed: $updatedProducts products were updated.'),
          backgroundColor: Colors.green,
        ),
      );

      await _scanProducts();
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _running = false;
        _statusMessage = 'Migration failed: ${error.message ?? error.code}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: ${error.message ?? error.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _running = false;
        _statusMessage = 'Migration failed: $error';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isMissing(dynamic value) {
    return value == null || value.toString().trim().isEmpty;
  }

  String _detectBrand(String productName) {
    final lowerName = productName.toLowerCase();

    final Map<String, String> knownBrands = {
      'coca cola': 'Coca-Cola',
      'coca-cola': 'Coca-Cola',
      'coke': 'Coca-Cola',
      'sprite': 'Coca-Cola',
      'royal': 'Coca-Cola',
      'minute maid': 'Minute Maid',
      'pepsi': 'Pepsi',
      'mountain dew': 'Mountain Dew',
      'mirinda': 'Mirinda',
      '7up': '7UP',
      'red bull': 'Red Bull',
      'cobra': 'Cobra',
      'sting': 'Sting',
      'nestle': 'Nestlé',
      'nescafe': 'Nescafé',
      'milo': 'Milo',
      'bear brand': 'Bear Brand',
      'birch tree': 'Birch Tree',
      'alaska': 'Alaska',
      'magnolia': 'Magnolia',
      'selecta': 'Selecta',
      'lucky me': 'Lucky Me',
      'payless': 'Payless',
      'nissin': 'Nissin',
      'indomie': 'Indomie',
      'piattos': 'Piattos',
      'nova': 'Nova',
      'chippy': 'Chippy',
      'mang juan': 'Mang Juan',
      'clover': 'Clover',
      'lays': 'Lay\'s',
      'pringles': 'Pringles',
      'skyflakes': 'SkyFlakes',
      'rebisco': 'Rebisco',
      'fibisco': 'Fibisco',
      'oreo': 'Oreo',
      'cream-o': 'Cream-O',
      'fita': 'Fita',
      'magic flakes': 'Magic Flakes',
      '555': '555',
      'century': 'Century',
      'argentina': 'Argentina',
      'purefoods': 'Purefoods',
      'san marino': 'San Marino',
      'mega': 'Mega',
      'del monte': 'Del Monte',
      'ufc': 'UFC',
      'silver swan': 'Silver Swan',
      'datu puti': 'Datu Puti',
      'knorr': 'Knorr',
      'maggi': 'Maggi',
      'eden': 'Eden',
      'cheez whiz': 'Cheez Whiz',
      'lady\'s choice': 'Lady\'s Choice',
      'safeguard': 'Safeguard',
      'dove': 'Dove',
      'palmolive': 'Palmolive',
      'head and shoulders': 'Head & Shoulders',
      'sunsilk': 'Sunsilk',
      'creamsilk': 'Cream Silk',
      'colgate': 'Colgate',
      'closeup': 'Closeup',
      'joy': 'Joy',
      'surf': 'Surf',
      'tide': 'Tide',
      'ariel': 'Ariel',
      'downy': 'Downy',
      'zonrox': 'Zonrox',
    };

    for (final entry in knownBrands.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    final cleaned = productName
        .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ\s&-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) {
      return 'Unbranded';
    }

    final words = cleaned.split(' ');

    if (words.length >= 2 && words.first.length <= 3 && words[1].length <= 3) {
      return '${words[0]} ${words[1]}';
    }

    return words.first;
  }

  String _detectCategory(String productName) {
    final name = productName.toLowerCase();

    final List<_CategoryRule> rules = [
      _CategoryRule('Soft Drinks', [
        'coke',
        'coca cola',
        'sprite',
        'royal',
        'pepsi',
        'mountain dew',
        'mirinda',
        '7up',
        'softdrink',
        'soft drink',
        'soda',
      ]),
      _CategoryRule('Energy Drinks', [
        'red bull',
        'cobra',
        'sting',
        'energy drink',
      ]),
      _CategoryRule('Water', [
        'mineral water',
        'purified water',
        'bottled water',
        'wilkins',
        'nature spring',
        'absolute',
      ]),
      _CategoryRule('Juice', [
        'juice',
        'zesto',
        'minute maid',
        'del monte juice',
      ]),
      _CategoryRule('Coffee', [
        'coffee',
        'nescafe',
        'kopiko',
        'great taste',
        'san mig coffee',
      ]),
      _CategoryRule('Milk and Dairy', [
        'milk',
        'milo',
        'bear brand',
        'birch tree',
        'alaska',
        'yogurt',
        'cheese',
        'eden',
      ]),
      _CategoryRule('Instant Noodles', [
        'noodle',
        'pancit canton',
        'lucky me',
        'payless',
        'nissin',
        'indomie',
        'ramen',
      ]),
      _CategoryRule('Snacks', [
        'chips',
        'piattos',
        'nova',
        'chippy',
        'mang juan',
        'clover',
        'lays',
        'pringles',
        'cracker nuts',
        'cornick',
      ]),
      _CategoryRule('Biscuits', [
        'biscuit',
        'cracker',
        'skyflakes',
        'rebisco',
        'fibisco',
        'oreo',
        'cream-o',
        'fita',
        'magic flakes',
        'wafer',
        'cookie',
      ]),
      _CategoryRule('Canned Goods', [
        'corned beef',
        'sardines',
        'tuna',
        'luncheon meat',
        'meat loaf',
        'canned',
        '555',
        'century',
        'argentina',
        'purefoods',
        'san marino',
        'mega',
      ]),
      _CategoryRule('Condiments', [
        'soy sauce',
        'vinegar',
        'ketchup',
        'mayonnaise',
        'fish sauce',
        'patis',
        'suka',
        'toyo',
        'datu puti',
        'silver swan',
        'ufc',
        'seasoning',
        'knorr',
        'maggi',
      ]),
      _CategoryRule('Rice and Grains', [
        'rice',
        'bigas',
        'oats',
        'oatmeal',
        'corn',
      ]),
      _CategoryRule('Frozen Foods', [
        'frozen',
        'hotdog',
        'tocino',
        'longganisa',
        'nuggets',
        'ham',
      ]),
      _CategoryRule('Personal Care', [
        'soap',
        'shampoo',
        'conditioner',
        'toothpaste',
        'toothbrush',
        'deodorant',
        'lotion',
        'safeguard',
        'dove',
        'palmolive',
        'sunsilk',
        'creamsilk',
        'colgate',
        'closeup',
      ]),
      _CategoryRule('Household Supplies', [
        'dishwashing',
        'detergent',
        'fabric conditioner',
        'bleach',
        'cleaner',
        'trash bag',
        'tissue',
        'paper towel',
        'joy',
        'surf',
        'tide',
        'ariel',
        'downy',
        'zonrox',
      ]),
      _CategoryRule('Baby Care', [
        'diaper',
        'baby wipes',
        'baby powder',
        'baby soap',
        'baby shampoo',
      ]),
      _CategoryRule('Bread and Bakery', [
        'bread',
        'loaf',
        'pandesal',
        'cake',
        'cupcake',
      ]),
      _CategoryRule('Candy and Chocolate', [
        'candy',
        'chocolate',
        'lollipop',
        'gum',
        'mentos',
      ]),
    ];

    for (final rule in rules) {
      for (final keyword in rule.keywords) {
        if (name.contains(keyword)) {
          return rule.category;
        }
      }
    }

    return 'Others';
  }

  Future<bool> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.auto_fix_high, color: Color(0xFF1565C0)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update Product Metadata',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'This tool will add missing brand, category, and imageUrl fields. '
            'Existing non-empty brand and category values will not be replaced. '
            'Automatically detected values may need manual review afterward.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Update'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _summaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool nothingToUpdate =
        !_loading &&
        _missingBrand == 0 &&
        _missingCategory == 0 &&
        _missingImageUrl == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Product Metadata Setup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Scan again',
            onPressed: _running ? null : _scanProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Database Check',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Adds missing brand, category, and imageUrl fields to existing products.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _summaryCard(
                        title: 'Total Products',
                        value: _totalProducts,
                        icon: Icons.inventory_2,
                        color: Colors.blue,
                      ),
                      _summaryCard(
                        title: 'Missing Brand',
                        value: _missingBrand,
                        icon: Icons.business,
                        color: Colors.orange,
                      ),
                      _summaryCard(
                        title: 'Missing Category',
                        value: _missingCategory,
                        icon: Icons.category,
                        color: Colors.purple,
                      ),
                      _summaryCard(
                        title: 'Missing Image URL',
                        value: _missingImageUrl,
                        icon: Icons.image_outlined,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF1565C0),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'How it works',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            '• Detects a likely brand using the product name.\n'
                            '• Detects a likely category using grocery keywords.\n'
                            '• Adds imageUrl as an empty string when missing.\n'
                            '• Keeps existing non-empty brand and category values.\n'
                            '• Uses safe Firestore batch sizes for large collections.',
                            style: TextStyle(fontSize: 15, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: const Text(
                              'Important: Automatically detected brand and category values '
                              'are estimates. Review products marked as "Others" or "Unbranded" '
                              'after the update.',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color:
                          _statusMessage.toLowerCase().contains('failed') ||
                              _statusMessage.toLowerCase().contains('unable')
                          ? Colors.red.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (_running)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        else
                          Icon(
                            nothingToUpdate ? Icons.check_circle : Icons.info,
                            color: nothingToUpdate
                                ? Colors.green
                                : const Color(0xFF1565C0),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_running) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _totalProducts == 0
                          ? null
                          : _updatedProducts / _totalProducts,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _running || nothingToUpdate
                          ? null
                          : _runMigration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _running
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              nothingToUpdate
                                  ? Icons.check
                                  : Icons.auto_fix_high,
                            ),
                      label: Text(
                        _running
                            ? 'UPDATING PRODUCTS...'
                            : nothingToUpdate
                            ? 'ALL PRODUCTS ARE READY'
                            : 'ADD MISSING METADATA',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
    );
  }
}

class _CategoryRule {
  const _CategoryRule(this.category, this.keywords);

  final String category;
  final List<String> keywords;
}
