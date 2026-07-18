import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../about/about_system_screen.dart';
import '../auth/login_screen.dart';
import '../owner/notifications_screen.dart';
import '../pos/new_transaction_screen.dart';
import '../profile/my_account_screen.dart';
import 'cashier_products_screen.dart';
import 'cashier_transaction_history_screen.dart';

class CashierDashboard extends StatelessWidget {
  const CashierDashboard({super.key});

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
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
              CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.logout, color: Color(0xFF1565C0)),
              ),
              SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(fontSize: 16, height: 1.4),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final bool confirmed = await _showLogoutConfirmation(context);

    if (!confirmed) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to logout: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
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
              CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.exit_to_app, color: Colors.orange),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Exit Application',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to exit the application?',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _handleBackButton(BuildContext context) async {
    final bool shouldExit = await _showExitConfirmation(context);

    if (shouldExit) {
      await SystemNavigator.pop();
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.pop(context);

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF1565C0)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String email = currentUser?.email ?? 'cashier@eumart.com';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 25, 22, 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Image.asset(
                      'assets/images/eu_mart_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.store,
                          size: 50,
                          color: Color(0xFF1565C0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'EÜ MART',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: Colors.white70,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Cashier Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  _drawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.person_outline,
                    title: 'My Account',
                    onTap: () {
                      _openPage(context, const MyAccountScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      _openPage(context, const NotificationsScreen());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.info_outline,
                    title: 'About the System',
                    onTap: () {
                      _openPage(context, const AboutSystemScreen());
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Divider(),
                  ),
                  _drawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _logout(context);
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'EÜ MART Version 1.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<Map<String, dynamic>> _cashierStats() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return Stream.value({
        'todaySales': 0.0,
        'todayTransactions': 0,
        'totalTransactions': 0,
        'averageTransaction': 0.0,
      });
    }

    return FirebaseFirestore.instance
        .collection('transactions')
        .where('processedById', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final DateTime now = DateTime.now();
          final DateTime today = DateTime(now.year, now.month, now.day);

          double todaySales = 0;
          double totalSales = 0;
          int todayTransactions = 0;
          int totalTransactions = 0;

          for (final document in snapshot.docs) {
            final Map<String, dynamic> data = document.data();

            final double total = (data['total'] as num?)?.toDouble() ?? 0;

            totalSales += total;
            totalTransactions++;

            DateTime? createdAt;
            final dynamic createdAtValue = data['createdAt'];

            if (createdAtValue is Timestamp) {
              createdAt = createdAtValue.toDate();
            } else if (createdAtValue is String) {
              createdAt = DateTime.tryParse(createdAtValue);
            }

            if (createdAt != null) {
              final DateTime transactionDate = DateTime(
                createdAt.year,
                createdAt.month,
                createdAt.day,
              );

              if (transactionDate == today) {
                todaySales += total;
                todayTransactions++;
              }
            }
          }

          final double averageTransaction = totalTransactions == 0
              ? 0
              : totalSales / totalTransactions;

          return {
            'todaySales': todaySales,
            'todayTransactions': todayTransactions,
            'totalTransactions': totalTransactions,
            'averageTransaction': averageTransaction,
          };
        });
  }

  Widget _summaryCard({
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
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
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

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 31),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _performanceCard({
    required double todaySales,
    required int todayTransactions,
    required double averageTransaction,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.trending_up, color: Colors.green),
                ),
                SizedBox(width: 12),
                Text(
                  'Today\'s Performance',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _performanceValue(
                    label: 'Sales',
                    value: '₱${todaySales.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _performanceValue(
                    label: 'Transactions',
                    value: '$todayTransactions',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _performanceValue(
                    label: 'Average',
                    value: '₱${averageTransaction.toStringAsFixed(2)}',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _performanceValue({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackButton(context);
      },
      child: Scaffold(
        drawer: _buildDrawer(context),
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          title: const Text(
            'EÜ MART - CASHIER',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: _cashierStats(),
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
                    'Unable to load cashier dashboard.\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final data = snapshot.data ?? <String, dynamic>{};

            final double todaySales =
                (data['todaySales'] as num?)?.toDouble() ?? 0;

            final int todayTransactions =
                (data['todayTransactions'] as num?)?.toInt() ?? 0;

            final int totalTransactions =
                (data['totalTransactions'] as num?)?.toInt() ?? 0;

            final double averageTransaction =
                (data['averageTransaction'] as num?)?.toDouble() ?? 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Cashier 👋',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Process customer purchases quickly and accurately.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 22),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _summaryCard(
                        title: 'Today\'s Sales',
                        value: '₱${todaySales.toStringAsFixed(2)}',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                      _summaryCard(
                        title: 'Today\'s Transactions',
                        value: '$todayTransactions',
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                      ),
                      _summaryCard(
                        title: 'Total Transactions',
                        value: '$totalTransactions',
                        icon: Icons.history,
                        color: Colors.blue,
                      ),
                      _summaryCard(
                        title: 'Account Role',
                        value: 'Cashier',
                        icon: Icons.badge,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _performanceCard(
                    todaySales: todaySales,
                    todayTransactions: todayTransactions,
                    averageTransaction: averageTransaction,
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                    children: [
                      _menuCard(
                        title: 'New Transaction',
                        subtitle: 'Process a new customer purchase',
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
                      _menuCard(
                        title: 'View Products',
                        subtitle: 'Search and check available stocks',
                        icon: Icons.inventory_2,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CashierProductsScreen(),
                            ),
                          );
                        },
                      ),
                      _menuCard(
                        title: 'Transaction History',
                        subtitle: 'Review your completed transactions',
                        icon: Icons.receipt_long,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CashierTransactionHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _menuCard(
                        title: 'Notifications',
                        subtitle: 'View stock and expiration alerts',
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
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
