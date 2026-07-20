import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../about/about_system_screen.dart';
import '../auth/login_screen.dart';
import '../pos/new_transaction_screen.dart';
import '../profile/my_account_screen.dart';
import '../settings/settings_screen.dart';
import 'inventory_screen.dart';
import 'manage_cashiers_screen.dart';
import 'notifications_screen.dart';
import 'owner_transaction_history_screen.dart';
import 'reports_screen.dart';
import 'sales_chart_screen.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

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

  Stream<Map<String, dynamic>> _dashboardData() {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .asyncMap((productsSnapshot) async {
          final DateTime now = DateTime.now();
          final DateTime today = DateTime(now.year, now.month, now.day);

          int lowStock = 0;
          int expiredProducts = 0;
          int expiringSoon = 0;

          for (final product in productsSnapshot.docs) {
            final data = product.data();

            final int stock = (data['stock'] as num?)?.toInt() ?? 0;

            if (stock <= 10) {
              lowStock++;
            }

            final DateTime? expirationDate = _readDate(data['expirationDate']);

            if (expirationDate != null) {
              final DateTime expiryDay = DateTime(
                expirationDate.year,
                expirationDate.month,
                expirationDate.day,
              );

              final int daysRemaining = expiryDay.difference(today).inDays;

              if (daysRemaining < 0) {
                expiredProducts++;
              } else if (daysRemaining <= 7) {
                expiringSoon++;
              }
            }
          }

          final transactionsSnapshot = await FirebaseFirestore.instance
              .collection('transactions')
              .get();

          final feedbackSnapshot = await FirebaseFirestore.instance
              .collection('customer_feedback')
              .get();

          double totalSales = 0;
          double todaySales = 0;
          int todayTransactions = 0;
          double totalRating = 0;
          int pendingFeedback = 0;

          for (final transaction in transactionsSnapshot.docs) {
            final data = transaction.data();

            final double transactionTotal =
                (data['total'] as num?)?.toDouble() ?? 0;

            totalSales += transactionTotal;

            final DateTime? createdAt = _readDate(data['createdAt']);

            if (createdAt != null && _isSameDay(createdAt, today)) {
              todaySales += transactionTotal;
              todayTransactions++;
            }
          }

          for (final feedback in feedbackSnapshot.docs) {
            final data = feedback.data();

            totalRating += (data['rating'] as num?)?.toDouble() ?? 0;

            final String status = (data['status'] ?? 'Pending').toString();

            if (status.toLowerCase() == 'pending') {
              pendingFeedback++;
            }
          }

          final double averageRating = feedbackSnapshot.docs.isEmpty
              ? 0
              : totalRating / feedbackSnapshot.docs.length;

          return {
            'totalProducts': productsSnapshot.docs.length,
            'lowStock': lowStock,
            'expiredProducts': expiredProducts,
            'expiringSoon': expiringSoon,
            'totalSales': totalSales,
            'todaySales': todaySales,
            'transactions': transactionsSnapshot.docs.length,
            'todayTransactions': todayTransactions,
            'totalFeedback': feedbackSnapshot.docs.length,
            'pendingFeedback': pendingFeedback,
            'averageRating': averageRating,
          };
        });
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
    final String email = currentUser?.email ?? 'owner@eumart.com';

    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                22,
                isLandscape ? 12 : 25,
                22,
                isLandscape ? 12 : 25,
              ),
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
                    width: isLandscape ? 70 : 110,
                    height: isLandscape ? 70 : 110,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Image.asset(
                      'assets/images/eu_mart_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 8 : 18),
                  Text(
                    'EÜ MART',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isLandscape ? 20 : 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 5 : 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white70,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Owner Account',
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

            const SizedBox(height: 8),

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
              icon: Icons.people_alt_outlined,
              title: 'Manage Cashiers',
              onTap: () {
                _openPage(context, const ManageCashiersScreen());
              },
            ),
            _drawerItem(
              icon: Icons.receipt_long,
              title: 'Transaction History',
              onTap: () {
                _openPage(context, const OwnerTransactionHistoryScreen());
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
              icon: Icons.reviews_outlined,
              title: 'Customer Feedback',
              onTap: () {
                _openPage(context, const OwnerCustomerFeedbackScreen());
              },
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                _openPage(context, const SettingsScreen());
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'EÜ MART Version 1.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
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
                          fontSize: 19,
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
      ),
    );
  }

  Widget _quickAction({
    required String title,
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analyticsValue({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _salesOverviewCard(
    BuildContext context, {
    required double totalSales,
    required double todaySales,
    required int transactions,
    required int todayTransactions,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.analytics_outlined, color: Colors.green),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sales Overview',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesChartScreen(),
                      ),
                    );
                  },
                  child: const Text('View Chart'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _analyticsValue(
                    title: 'Today',
                    value: '₱${todaySales.toStringAsFixed(2)}',
                    subtitle: '$todayTransactions transactions',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _analyticsValue(
                    title: 'Overall',
                    value: '₱${totalSales.toStringAsFixed(2)}',
                    subtitle: '$transactions transactions',
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

  Widget _feedbackOverviewCard(
    BuildContext context, {
    required int totalFeedback,
    required int pendingFeedback,
    required double averageRating,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const OwnerCustomerFeedbackScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF8E1),
                child: Icon(Icons.star, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Satisfaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      averageRating == 0
                          ? 'No ratings yet'
                          : '${averageRating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalFeedback total • $pendingFeedback pending',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge({
    required int count,
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (count > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notificationBadge(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _countBadge(
          count: count,
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        );
      },
    );
  }

  Widget _transactionBadge(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count = docs
            .where((doc) => doc.data()['isViewedByOwner'] != true)
            .length;

        return _countBadge(
          count: count,
          icon: Icons.receipt_long_outlined,
          tooltip: 'New transactions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OwnerTransactionHistoryScreen(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'EÜ MART',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _transactionBadge(context),
          _notificationBadge(context),
          const SizedBox(width: 6),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dashboardData(),
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
                  'Unable to load dashboard.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};

          final int totalProducts =
              (data['totalProducts'] as num?)?.toInt() ?? 0;

          final int lowStock = (data['lowStock'] as num?)?.toInt() ?? 0;

          final int expiredProducts =
              (data['expiredProducts'] as num?)?.toInt() ?? 0;

          final int expiringSoon = (data['expiringSoon'] as num?)?.toInt() ?? 0;

          final double totalSales =
              (data['totalSales'] as num?)?.toDouble() ?? 0;

          final double todaySales =
              (data['todaySales'] as num?)?.toDouble() ?? 0;

          final int transactions = (data['transactions'] as num?)?.toInt() ?? 0;

          final int todayTransactions =
              (data['todayTransactions'] as num?)?.toInt() ?? 0;

          final int totalFeedback =
              (data['totalFeedback'] as num?)?.toInt() ?? 0;

          final int pendingFeedback =
              (data['pendingFeedback'] as num?)?.toInt() ?? 0;

          final double averageRating =
              (data['averageRating'] as num?)?.toDouble() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Owner 👋',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Here is your store overview.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _summaryCard(
                      title: 'Products',
                      value: '$totalProducts',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const InventoryScreen(initialFilter: 'all'),
                          ),
                        );
                      },
                    ),
                    _summaryCard(
                      title: 'Low Stock',
                      value: '$lowStock',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(
                              initialFilter: 'lowStock',
                            ),
                          ),
                        );
                      },
                    ),
                    _summaryCard(
                      title: 'Expired',
                      value: '$expiredProducts',
                      icon: Icons.error_outline,
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const InventoryScreen(initialFilter: 'expired'),
                          ),
                        );
                      },
                    ),
                    _summaryCard(
                      title: 'Expiring Soon',
                      value: '$expiringSoon',
                      icon: Icons.schedule,
                      color: Colors.deepOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(
                              initialFilter: 'expiringSoon',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _salesOverviewCard(
                  context,
                  totalSales: totalSales,
                  todaySales: todaySales,
                  transactions: transactions,
                  todayTransactions: todayTransactions,
                ),
                const SizedBox(height: 14),
                _feedbackOverviewCard(
                  context,
                  totalFeedback: totalFeedback,
                  pendingFeedback: pendingFeedback,
                  averageRating: averageRating,
                ),
                const SizedBox(height: 25),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.68,
                  children: [
                    _quickAction(
                      title: 'Inventory',
                      icon: Icons.inventory_2,
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
                    _quickAction(
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
                    _quickAction(
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
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OwnerCustomerFeedbackScreen extends StatefulWidget {
  const OwnerCustomerFeedbackScreen({super.key});

  @override
  State<OwnerCustomerFeedbackScreen> createState() =>
      _OwnerCustomerFeedbackScreenState();
}

class _OwnerCustomerFeedbackScreenState
    extends State<OwnerCustomerFeedbackScreen> {
  String selectedStatus = 'All';

  Future<void> _updateStatus(String documentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('customer_feedback')
          .doc(documentId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feedback marked as $newStatus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update feedback: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'Date unavailable';
    }

    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  Widget _statusChip(String label) {
    final bool selected = selectedStatus == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      onSelected: (_) {
        setState(() {
          selectedStatus = label;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Customer Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('customer_feedback')
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
                  'Unable to load customer feedback.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];

          docs.sort((a, b) {
            final DateTime? first = (a.data()['createdAt'] as Timestamp?)
                ?.toDate();
            final DateTime? second = (b.data()['createdAt'] as Timestamp?)
                ?.toDate();

            if (first == null && second == null) return 0;
            if (first == null) return 1;
            if (second == null) return -1;

            return second.compareTo(first);
          });

          final filteredDocs = docs.where((doc) {
            if (selectedStatus == 'All') return true;

            final String status = (doc.data()['status'] ?? 'Pending')
                .toString();

            return status.toLowerCase() == selectedStatus.toLowerCase();
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No customer feedback yet.',
                style: TextStyle(color: Colors.grey, fontSize: 17),
              ),
            );
          }

          return Column(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusChip('All'),
                    const SizedBox(width: 8),
                    _statusChip('Pending'),
                    const SizedBox(width: 8),
                    _statusChip('In Progress'),
                    const SizedBox(width: 8),
                    _statusChip('Resolved'),
                  ],
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                        child: Text('No feedback found for this status.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final document = filteredDocs[index];
                          final data = document.data();

                          final String name =
                              (data['customerName'] ?? 'Anonymous').toString();

                          final String type = (data['feedbackType'] ?? 'Other')
                              .toString();

                          final String message = (data['message'] ?? '')
                              .toString();

                          final String receiptNumber =
                              (data['receiptNumber'] ?? '').toString();

                          final String status = (data['status'] ?? 'Pending')
                              .toString();

                          final int rating =
                              (data['rating'] as num?)?.toInt() ?? 0;

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.withValues(
                                  alpha: 0.16,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$type • ${_formatDate(data['createdAt'])}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              children: [
                                const Divider(),
                                Row(
                                  children: List.generate(
                                    5,
                                    (starIndex) => Icon(
                                      starIndex < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                if (receiptNumber.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Receipt: $receiptNumber',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        _updateStatus(
                                          document.id,
                                          'In Progress',
                                        );
                                      },
                                      child: const Text('In Progress'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        _updateStatus(document.id, 'Resolved');
                                      },
                                      child: const Text('Resolve'),
                                    ),
                                  ],
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
}
