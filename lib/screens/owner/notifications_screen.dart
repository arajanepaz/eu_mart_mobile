import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final lowStockProducts = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final stock = (data['stock'] as num?)?.toInt() ?? 0;
            return stock <= 5;
          }).toList();

          if (lowStockProducts.isEmpty) {
            return const Center(
              child: Text('No notifications.', style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final data =
                  lowStockProducts[index].data() as Map<String, dynamic>;

              final productName = (data['productName'] ?? 'Unknown Product')
                  .toString();

              final stock = (data['stock'] as num?)?.toInt() ?? 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Low stock: $stock remaining'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
