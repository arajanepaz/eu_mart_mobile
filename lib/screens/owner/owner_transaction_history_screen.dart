import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OwnerTransactionHistoryScreen extends StatefulWidget {
  const OwnerTransactionHistoryScreen({super.key});

  @override
  State<OwnerTransactionHistoryScreen> createState() =>
      _OwnerTransactionHistoryScreenState();
}

class _OwnerTransactionHistoryScreenState
    extends State<OwnerTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _markTransactionsViewed();
  }

  Future<void> _markTransactionsViewed() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .get();

    final unread = snapshot.docs
        .where((doc) => doc.data()['isViewedByOwner'] != true)
        .toList();

    if (unread.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isViewedByOwner': true});
    }
    await batch.commit();
  }

  bool _matchesDateFilter(DateTime? date) {
    if (_selectedFilter == 'All') return true;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (_selectedFilter == 'Today') {
      return transactionDate == today;
    }

    if (_selectedFilter == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return !transactionDate.isBefore(startOfWeek) &&
          !transactionDate.isAfter(endOfWeek);
    }

    if (_selectedFilter == 'This Month') {
      return transactionDate.year == now.year &&
          transactionDate.month == now.month;
    }

    return true;
  }

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _confirmDeleteTransaction({
    required String documentId,
    required String receiptNumber,
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
              Expanded(child: Text('Delete Transaction')),
            ],
          ),
          content: Text(
            'Are you sure you want to delete transaction "$receiptNumber"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
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
          .collection('transactions')
          .doc(documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete transaction: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _filterChip(String label) {
    final bool selected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Owner Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load transactions.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];

          docs.sort((a, b) {
            final first = _readDate(a.data()['createdAt']);
            final second = _readDate(b.data()['createdAt']);
            if (first == null && second == null) return 0;
            if (first == null) return 1;
            if (second == null) return -1;
            return second.compareTo(first);
          });

          final filteredDocs = docs.where((doc) {
            final data = doc.data();

            final receiptNumber = _readString(data, [
              'receiptNumber',
              'transactionNumber',
            ], fallback: doc.id).toLowerCase();

            final cashier = _readString(data, [
              'processedByName',
              'processedByEmail',
              'cashierName',
              'cashierEmail',
            ], fallback: 'Unknown cashier').toLowerCase();

            final createdAt = _readDate(data['createdAt']);

            final matchesSearch =
                _searchQuery.isEmpty ||
                receiptNumber.contains(_searchQuery) ||
                cashier.contains(_searchQuery);

            return matchesSearch && _matchesDateFilter(createdAt);
          }).toList();

          double totalSales = 0;
          for (final doc in filteredDocs) {
            totalSales += (doc.data()['total'] as num?)?.toDouble() ?? 0;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Total Sales',
                            value: '₱${totalSales.toStringAsFixed(2)}',
                            icon: Icons.payments,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            title: 'Transactions',
                            value: '${filteredDocs.length}',
                            icon: Icons.receipt_long,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search receipt or cashier',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All'),
                          const SizedBox(width: 8),
                          _filterChip('Today'),
                          const SizedBox(width: 8),
                          _filterChip('This Week'),
                          const SizedBox(width: 8),
                          _filterChip('This Month'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 75,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No transactions found.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final document = filteredDocs[index];
                          final data = document.data();

                          final total =
                              (data['total'] as num?)?.toDouble() ?? 0;
                          final cash = (data['cash'] as num?)?.toDouble() ?? 0;
                          final change =
                              (data['change'] as num?)?.toDouble() ?? 0;
                          final createdAt = _readDate(data['createdAt']);
                          final bool isNew = data['isViewedByOwner'] != true;

                          final dateText = createdAt == null
                              ? 'Date unavailable'
                              : DateFormat(
                                  'MMM d, yyyy • h:mm a',
                                ).format(createdAt);

                          final shortDocumentId = document.id.length > 6
                              ? document.id.substring(0, 6)
                              : document.id;

                          final receiptNumber = _readString(
                            data,
                            ['receiptNumber', 'transactionNumber'],
                            fallback:
                                'Receipt #${shortDocumentId.toUpperCase()}',
                          );
                          final cashier = _readString(data, [
                            'processedByName',
                            'processedByEmail',
                            'cashierName',
                            'cashierEmail',
                          ], fallback: 'Unknown cashier');

                          final items = data['items'] as List<dynamic>? ?? [];

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                14,
                                0,
                                14,
                                14,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      receiptNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text('$cashier\n$dateText'),
                              ),
                              children: [
                                const Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Cash: ₱${cash.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Change: ₱${change.toStringAsFixed(2)}',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (items.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('No item details available.'),
                                  )
                                else
                                  ...items.map((item) {
                                    final itemData =
                                        item as Map<String, dynamic>;
                                    final productName =
                                        (itemData['productName'] ??
                                                'Unknown Product')
                                            .toString();
                                    final quantity =
                                        (itemData['quantity'] as num?)
                                            ?.toInt() ??
                                        0;
                                    final subtotal =
                                        (itemData['subtotal'] as num?)
                                            ?.toDouble() ??
                                        0;

                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(productName),
                                      subtitle: Text('Quantity: $quantity'),
                                      trailing: Text(
                                        '₱${subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                const Divider(),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _confirmDeleteTransaction(
                                        documentId: document.id,
                                        receiptNumber: receiptNumber,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'Delete Transaction',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
