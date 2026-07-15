import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageCashiersScreen extends StatelessWidget {
  const ManageCashiersScreen({super.key});

  Future<void> updateCashierStatus({
    required BuildContext context,
    required String documentId,
    required bool newStatus,
    required String cashierName,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .update({'isActive': newStatus});

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '$cashierName has been enabled.'
                : '$cashierName has been disabled.',
          ),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating cashier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> deleteCashier({
    required BuildContext context,
    required String documentId,
    required String cashierName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Cashier'),
          content: Text(
            'Are you sure you want to remove $cashierName from the cashier list?',
          ),
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cashier removed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing cashier: $e'),
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
        title: const Text('Manage Cashiers'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'cashier')
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
                  'Error loading cashiers:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No cashier accounts found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cashier = docs[index];
              final data = cashier.data() as Map<String, dynamic>;

              final name = (data['name'] ?? 'Cashier').toString();

              final email = (data['email'] ?? 'No email').toString();

              final isActive = data['isActive'] is bool
                  ? data['isActive'] as bool
                  : true;

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
                        radius: 28,
                        backgroundColor: isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          Icons.person,
                          color: isActive ? Colors.green : Colors.red,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              email,
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Disabled',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        children: [
                          Switch(
                            value: isActive,
                            activeThumbColor: Colors.green,
                            onChanged: (value) {
                              updateCashierStatus(
                                context: context,
                                documentId: cashier.id,
                                newStatus: value,
                                cashierName: name,
                              );
                            },
                          ),

                          IconButton(
                            tooltip: 'Remove cashier',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteCashier(
                                context: context,
                                documentId: cashier.id,
                                cashierName: name,
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
    );
  }
}
