import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Sales Reports"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          double totalSales = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalSales += (data["total"] as num?)?.toDouble() ?? 0;
          }

          return Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.payments, color: Colors.green),
                    title: const Text(
                      "Total Sales",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "₱${totalSales.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Card(
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.blue),
                    title: const Text(
                      "Transactions",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${docs.length}",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Transaction History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: docs.isEmpty
                      ? const Center(child: Text("No transactions yet."))
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data =
                                docs[index].data() as Map<String, dynamic>;

                            final total =
                                (data["total"] as num?)?.toDouble() ?? 0;

                            final cash =
                                (data["cash"] as num?)?.toDouble() ?? 0;

                            final change =
                                (data["change"] as num?)?.toDouble() ?? 0;

                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.shopping_cart),
                                ),
                                title: Text("₱${total.toStringAsFixed(2)}"),
                                subtitle: Text(
                                  "Cash: ₱${cash.toStringAsFixed(2)}\nChange: ₱${change.toStringAsFixed(2)}",
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
