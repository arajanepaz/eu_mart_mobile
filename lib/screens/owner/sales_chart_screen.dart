import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChartScreen extends StatelessWidget {
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('createdAt')
            .snapshots(),
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

          final Map<int, double> salesByDay = {};

          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final createdAt = data['createdAt'];
            final total = (data['total'] as num?)?.toDouble() ?? 0;

            if (createdAt is Timestamp) {
              final date = createdAt.toDate();
              salesByDay[date.day] = (salesByDay[date.day] ?? 0) + total;
            }
          }

          final sortedDays = salesByDay.keys.toList()..sort();

          final spots = sortedDays.map((day) {
            return FlSpot(day.toDouble(), salesByDay[day] ?? 0);
          }).toList();

          if (spots.isEmpty) {
            return const Center(
              child: Text(
                'No sales data available.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Daily Sales Chart',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sales grouped by day of the current data set.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 25, 18, 18),
                  child: SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),

                        borderData: FlBorderData(show: true),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            axisNameWidget: const Text('Day'),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 11),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            axisNameWidget: const Text('Sales'),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '₱${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 4,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: const Text(
                    'Total Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${docs.length}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
