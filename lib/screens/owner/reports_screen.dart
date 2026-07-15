import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  Widget reportCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

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

          final docs = snapshot.data?.docs ?? [];

          double totalSales = 0;
          double todaySales = 0;
          double weeklySales = 0;
          double monthlySales = 0;

          final Map<String, int> productSales = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final total = (data["total"] as num?)?.toDouble() ?? 0;
            totalSales += total;

            final createdAt = data["createdAt"];

            if (createdAt is Timestamp) {
              final date = createdAt.toDate();

              if (isSameDay(date, now)) {
                todaySales += total;
              }

              if (date.isAfter(weekAgo)) {
                weeklySales += total;
              }

              if (isSameMonth(date, now)) {
                monthlySales += total;
              }
            }

            final items = data["items"] as List<dynamic>? ?? [];

            for (final item in items) {
              final itemData = item as Map<String, dynamic>;
              final productName = (itemData["productName"] ?? "Unknown")
                  .toString();
              final quantity = (itemData["quantity"] as num?)?.toInt() ?? 0;

              productSales[productName] =
                  (productSales[productName] ?? 0) + quantity;
            }
          }

          String fastMoving = "No data";
          String slowMoving = "No data";
          String topSelling = "No data";

          if (productSales.isNotEmpty) {
            final sorted = productSales.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            fastMoving = "${sorted.first.key} (${sorted.first.value} sold)";
            slowMoving = "${sorted.last.key} (${sorted.last.value} sold)";
            topSelling = "${sorted.first.key} (${sorted.first.value} sold)";
          }

          return ListView(
            padding: const EdgeInsets.all(15),
            children: [
              reportCard(
                title: "Total Sales",
                value: "₱${totalSales.toStringAsFixed(2)}",
                icon: Icons.payments,
                color: Colors.green,
              ),
              reportCard(
                title: "Today's Sales",
                value: "₱${todaySales.toStringAsFixed(2)}",
                icon: Icons.today,
                color: Colors.blue,
              ),
              reportCard(
                title: "Weekly Sales",
                value: "₱${weeklySales.toStringAsFixed(2)}",
                icon: Icons.date_range,
                color: Colors.orange,
              ),
              reportCard(
                title: "Monthly Sales",
                value: "₱${monthlySales.toStringAsFixed(2)}",
                icon: Icons.calendar_month,
                color: Colors.purple,
              ),
              reportCard(
                title: "Transactions",
                value: "${docs.length}",
                icon: Icons.receipt_long,
                color: Colors.indigo,
              ),
              reportCard(
                title: "Top-Selling Product",
                value: topSelling,
                icon: Icons.star,
                color: Colors.amber,
              ),
              reportCard(
                title: "Fast-Moving Product",
                value: fastMoving,
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              reportCard(
                title: "Slow-Moving Product",
                value: slowMoving,
                icon: Icons.trending_down,
                color: Colors.red,
              ),

              const SizedBox(height: 15),

              const Text(
                "Transaction History",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              if (docs.isEmpty)
                const Center(child: Text("No transactions yet."))
              else
                ...docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final total = (data["total"] as num?)?.toDouble() ?? 0;
                  final cash = (data["cash"] as num?)?.toDouble() ?? 0;
                  final change = (data["change"] as num?)?.toDouble() ?? 0;

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
                }),
            ],
          );
        },
      ),
    );
  }
}
