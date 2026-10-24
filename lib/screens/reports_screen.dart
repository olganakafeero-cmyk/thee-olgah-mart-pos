import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double todayTotal = 0;
  int todayCount = 0;
  List<Map<String, dynamic>> days = [];
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> topProducts = [];
  List<Product> lowStock = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    final today = await DbHelper.instance.getTodaySummary();
    final d = await DbHelper.instance.getSalesByDay();
    final p = await DbHelper.instance.getSalesByPayment();
    final t = await DbHelper.instance.getTopProducts();
    final low = await DbHelper.instance.getLowStockProducts();
    setState(() {
      todayTotal = (today['total'] as num).toDouble();
      todayCount = (today['count'] as num).toInt();
      days = d.reversed.toList();
      payments = p;
      topProducts = t;
      lowStock = low;
    });
  }


  Widget lowStockBanner() {
    final scheme = Theme.of(context).colorScheme;

    if (lowStock.isEmpty) {
      return Card(
        color: scheme.primaryContainer,
        child: ListTile(
          leading: Icon(Icons.check_circle, color: scheme.primary),
          title: Text(
            'All products are well stocked',
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
      );
    }

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: scheme.error),
                const SizedBox(width: 8),
                Text(
                  'Low stock alert (${lowStock.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lowStock.map(
                  (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                    Text(
                      p.stock == 0 ? 'OUT OF STOCK' : 'Only ${p.stock} left',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget summaryCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadReports),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          lowStockBanner(),
          const SizedBox(height: 8),
          Row(
            children: [
              summaryCard("Today's sales", todayTotal.toStringAsFixed(0)),
              summaryCard('Transactions', '$todayCount'),
            ],
          ),
          sectionTitle('Last 7 days'),
          SizedBox(
            height: 220,
            child: days.isEmpty
                ? const Center(child: Text('No sales yet'))
                : BarChart(
              BarChartData(
                barGroups: [
                  for (int i = 0; i < days.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (days[i]['total'] as num).toDouble(),
                          width: 18,
                            color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: true, reservedSize: 50),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox();
                        }
                        final day = days[i]['day'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            day.substring(5),
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
          sectionTitle('Sales by payment method'),
          if (payments.isEmpty) const Text('No sales yet'),
          ...payments.map(
                (p) => ListTile(
              leading: const Icon(Icons.payments),
              title: Text(p['payment_method'] as String),
              subtitle: Text('${p['count']} sales'),
              trailing: Text(
                (p['total'] as num).toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          sectionTitle('Top products'),
          if (topProducts.isEmpty) const Text('No sales yet'),
          ...topProducts.map(
                (t) => ListTile(
              leading: const Icon(Icons.star),
              title: Text(t['name'] as String),
              subtitle: Text('${t['qty']} sold'),
              trailing: Text(
                (t['revenue'] as num).toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}