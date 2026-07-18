import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  DateTime? parseExpirationDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      final date = value.toDate();

      return DateTime(date.year, date.month, date.day);
    }

    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is String) {
      final parsedDate = DateTime.tryParse(value.trim());

      if (parsedDate != null) {
        return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      }
    }

    return null;
  }

  int daysFromToday(DateTime expirationDate) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final expiry = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    return expiry.difference(today).inDays;
  }

  String expirationMessage(int daysRemaining) {
    if (daysRemaining < -1) {
      return 'Expired ${daysRemaining.abs()} days ago';
    }

    if (daysRemaining == -1) {
      return 'Expired yesterday';
    }

    if (daysRemaining == 0) {
      return 'Expires today';
    }

    if (daysRemaining == 1) {
      return 'Expires tomorrow';
    }

    return 'Expires in $daysRemaining days';
  }

  String formatDate(DateTime date) {
    final monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  Widget sectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget expirationCard({
    required String productName,
    required DateTime expirationDate,
    required int daysRemaining,
  }) {
    Color color;
    IconData icon;
    String status;

    if (daysRemaining < 0) {
      color = Colors.red;
      icon = Icons.error;
      status = 'EXPIRED';
    } else if (daysRemaining == 0) {
      color = Colors.deepOrange;
      icon = Icons.today;
      status = 'EXPIRES TODAY';
    } else if (daysRemaining <= 7) {
      color = Colors.orange;
      icon = Icons.warning_amber_rounded;
      status = 'EXPIRING SOON';
    } else {
      color = Colors.amber.shade800;
      icon = Icons.schedule;
      status = 'EXPIRING WITHIN 30 DAYS';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    expirationMessage(daysRemaining),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expiration date: ${formatDate(expirationDate)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget stockCard({required String productName, required int stock}) {
    final bool isOutOfStock = stock <= 0;

    final Color color = isOutOfStock ? Colors.red : Colors.orange.shade800;

    final String message = isOutOfStock
        ? 'Product is out of stock.'
        : 'Only $stock item${stock == 1 ? '' : 's'} remaining. Reorder soon.';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(13),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            isOutOfStock
                ? Icons.remove_shopping_cart
                : Icons.inventory_2_outlined,
            color: color,
          ),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            message,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
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
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
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
                  'Unable to load notifications.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final List<Map<String, dynamic>> expiredProducts = [];

          final List<Map<String, dynamic>> expiringToday = [];

          final List<Map<String, dynamic>> expiringWithinSevenDays = [];

          final List<Map<String, dynamic>> expiringWithinThirtyDays = [];

          final List<Map<String, dynamic>> stockAlerts = [];

          for (final document in documents) {
            final data = document.data();

            final String productName =
                (data['productName'] ?? 'Unknown Product').toString();

            final int stock = (data['stock'] as num?)?.toInt() ?? 0;

            if (stock <= 10) {
              stockAlerts.add({'productName': productName, 'stock': stock});
            }

            final DateTime? expirationDate = parseExpirationDate(
              data['expirationDate'],
            );

            if (expirationDate == null) {
              continue;
            }

            final int daysRemaining = daysFromToday(expirationDate);

            final productAlert = <String, dynamic>{
              'productName': productName,
              'expirationDate': expirationDate,
              'daysRemaining': daysRemaining,
            };

            if (daysRemaining < 0) {
              expiredProducts.add(productAlert);
            } else if (daysRemaining == 0) {
              expiringToday.add(productAlert);
            } else if (daysRemaining <= 7) {
              expiringWithinSevenDays.add(productAlert);
            } else if (daysRemaining <= 30) {
              expiringWithinThirtyDays.add(productAlert);
            }
          }

          expiredProducts.sort(
            (a, b) => (a['daysRemaining'] as int).compareTo(
              b['daysRemaining'] as int,
            ),
          );

          expiringWithinSevenDays.sort(
            (a, b) => (a['daysRemaining'] as int).compareTo(
              b['daysRemaining'] as int,
            ),
          );

          expiringWithinThirtyDays.sort(
            (a, b) => (a['daysRemaining'] as int).compareTo(
              b['daysRemaining'] as int,
            ),
          );

          stockAlerts.sort(
            (a, b) => (a['stock'] as int).compareTo(b['stock'] as int),
          );

          final bool hasNotifications =
              expiredProducts.isNotEmpty ||
              expiringToday.isNotEmpty ||
              expiringWithinSevenDays.isNotEmpty ||
              expiringWithinThirtyDays.isNotEmpty ||
              stockAlerts.isNotEmpty;

          if (!hasNotifications) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'No notifications.',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'All products have safe stock and expiration dates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (expiredProducts.isNotEmpty) ...[
                sectionHeader(
                  title: 'Expired Products',
                  icon: Icons.error,
                  color: Colors.red,
                  count: expiredProducts.length,
                ),
                ...expiredProducts.map(
                  (product) => expirationCard(
                    productName: product['productName'] as String,
                    expirationDate: product['expirationDate'] as DateTime,
                    daysRemaining: product['daysRemaining'] as int,
                  ),
                ),
              ],

              if (expiringToday.isNotEmpty) ...[
                sectionHeader(
                  title: 'Expiring Today',
                  icon: Icons.today,
                  color: Colors.deepOrange,
                  count: expiringToday.length,
                ),
                ...expiringToday.map(
                  (product) => expirationCard(
                    productName: product['productName'] as String,
                    expirationDate: product['expirationDate'] as DateTime,
                    daysRemaining: product['daysRemaining'] as int,
                  ),
                ),
              ],

              if (expiringWithinSevenDays.isNotEmpty) ...[
                sectionHeader(
                  title: 'Expiring Within 7 Days',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.orange,
                  count: expiringWithinSevenDays.length,
                ),
                ...expiringWithinSevenDays.map(
                  (product) => expirationCard(
                    productName: product['productName'] as String,
                    expirationDate: product['expirationDate'] as DateTime,
                    daysRemaining: product['daysRemaining'] as int,
                  ),
                ),
              ],

              if (expiringWithinThirtyDays.isNotEmpty) ...[
                sectionHeader(
                  title: 'Expiring Within 30 Days',
                  icon: Icons.schedule,
                  color: Colors.amber.shade800,
                  count: expiringWithinThirtyDays.length,
                ),
                ...expiringWithinThirtyDays.map(
                  (product) => expirationCard(
                    productName: product['productName'] as String,
                    expirationDate: product['expirationDate'] as DateTime,
                    daysRemaining: product['daysRemaining'] as int,
                  ),
                ),
              ],

              if (stockAlerts.isNotEmpty) ...[
                sectionHeader(
                  title: 'Stock Alerts',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blueGrey,
                  count: stockAlerts.length,
                ),
                ...stockAlerts.map(
                  (product) => stockCard(
                    productName: product['productName'] as String,
                    stock: product['stock'] as int,
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
