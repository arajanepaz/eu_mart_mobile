import 'package:flutter/material.dart';

class ManageCashiersScreen extends StatelessWidget {
  const ManageCashiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Manage Cashiers"),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add Cashier - Coming Soon")),
          );
        },
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text("No cashiers yet"),
              subtitle: const Text("Tap the + button to add a cashier."),
            ),
          ),
        ],
      ),
    );
  }
}
