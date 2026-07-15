import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CashierTransactionHistoryScreen extends StatelessWidget {
  const CashierTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: currentUser == null
          ? const Center(child: Text('No logged-in user.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('processedById', isEqualTo: currentUser.uid)
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
                        'Error loading transactions:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aDate = aData['createdAt'] as Timestamp?;
                  final bDate = bData['createdAt'] as Timestamp?;

                  if (aDate == null || bDate == null) {
                    return 0;
                  }

                  return bDate.compareTo(aDate);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No transactions processed yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final total = (data['total'] as num?)?.toDouble() ?? 0;

                    final cash = (data['cash'] as num?)?.toDouble() ?? 0;

                    final change = (data['change'] as num?)?.toDouble() ?? 0;

                    final createdAt = data['createdAt'] as Timestamp?;

                    final dateText = createdAt == null
                        ? 'Date unavailable'
                        : createdAt.toDate().toString();

                    final items = data['items'] as List<dynamic>? ?? [];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(
                            Icons.receipt_long,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        title: Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$dateText\n'
                          'Cash: ₱${cash.toStringAsFixed(2)} | '
                          'Change: ₱${change.toStringAsFixed(2)}',
                        ),
                        children: [
                          const Divider(height: 1),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(15),
                              child: Text('No item details available.'),
                            )
                          else
                            ...items.map((item) {
                              final itemData = item as Map<String, dynamic>;

                              final productName =
                                  (itemData['productName'] ?? 'Unknown')
                                      .toString();

                              final quantity =
                                  (itemData['quantity'] as num?)?.toInt() ?? 0;

                              final subtotal =
                                  (itemData['subtotal'] as num?)?.toDouble() ??
                                  0;

                              return ListTile(
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
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
