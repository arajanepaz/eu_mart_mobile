import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("products").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lowStockProducts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stock = (data["stock"] as num?)?.toInt() ?? 0;
            return stock <= 5;
          }).toList();

          if (lowStockProducts.isEmpty) {
            return const Center(child: Text("No notifications."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final data =
                  lowStockProducts[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(data["productName"] ?? "Unknown Product"),
                  subtitle: Text("Low stock: ${data["stock"]} remaining"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
