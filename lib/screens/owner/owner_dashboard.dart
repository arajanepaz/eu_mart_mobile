import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../pos/new_transaction_screen.dart';
import 'inventory_screen.dart';
import 'manage_cashiers_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';
import 'sales_chart_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Stream<Map<String, dynamic>> dashboardData() {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .asyncMap((productsSnapshot) async {
          final products = productsSnapshot.docs;

          final totalProducts = products.length;

          final lowStock = products.where((doc) {
            final data = doc.data();
            final stock = (data['stock'] as num?)?.toInt() ?? 0;
            return stock <= 5;
          }).length;

          final transactionsSnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .get();

          double totalSales = 0;

          for (final doc in transactionsSnapshot.docs) {
            final data = doc.data();
            totalSales += (data['total'] as num?)?.toDouble() ?? 0;
          }

          return {
            'totalProducts': totalProducts,
            'lowStock': lowStock,
            'totalSales': totalSales,
            'transactions': transactionsSnapshot.docs.length,
          };
        });
  }

  Widget summaryCard({
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
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
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

  Widget dashboardButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'EU MART',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: dashboardData(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          final totalProducts = data['totalProducts'] ?? 0;
          final lowStock = data['lowStock'] ?? 0;
          final totalSales = (data['totalSales'] as num?)?.toDouble() ?? 0;
          final transactions = data['transactions'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Owner 👋',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage your store efficiently.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    summaryCard(
                      title: 'Products',
                      value: '$totalProducts',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    summaryCard(
                      title: 'Low Stock',
                      value: '$lowStock',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                    summaryCard(
                      title: 'Total Sales',
                      value: '₱${totalSales.toStringAsFixed(2)}',
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                    summaryCard(
                      title: 'Transactions',
                      value: '$transactions',
                      icon: Icons.receipt_long,
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'System Features',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    dashboardButton(
                      title: 'Product Search',
                      icon: Icons.search,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(),
                          ),
                        );
                      },
                    ),
                    dashboardButton(
                      title: 'Transaction',
                      icon: Icons.point_of_sale,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NewTransactionScreen(),
                          ),
                        );
                      },
                    ),
                    dashboardButton(
                      title: 'Reports',
                      icon: Icons.bar_chart,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        );
                      },
                    ),
                    dashboardButton(
                      title: 'Notifications',
                      icon: Icons.notifications,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    dashboardButton(
                      title: 'Manage Cashiers',
                      icon: Icons.people,
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageCashiersScreen(),
                          ),
                        );
                      },
                    ),
                    dashboardButton(
                      title: 'Sales Chart',
                      icon: Icons.show_chart,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SalesChartScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
