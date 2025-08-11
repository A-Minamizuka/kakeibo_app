import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支出分析'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final expenseData = provider.expenseByCategory;

          if (expenseData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'まだ支出データがありません',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '支出を追加するとグラフが表示されます',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 今月のサマリー
                _buildMonthlySummary(context, provider),
                const SizedBox(height: 24),

                // 円グラフ
                _buildPieChart(context, expenseData),
                const SizedBox(height: 24),

                // カテゴリ別詳細
                _buildCategoryDetails(context, expenseData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlySummary(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final formatter = NumberFormat('#,###');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今月のサマリー',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  '収入',
                  '¥${formatter.format(provider.thisMonthIncome)}',
                  Colors.green,
                  Icons.trending_up,
                ),
                _buildSummaryItem(
                  context,
                  '支出',
                  '¥${formatter.format(provider.thisMonthExpense)}',
                  Colors.red,
                  Icons.trending_down,
                ),
                _buildSummaryItem(
                  context,
                  '残高',
                  '¥${formatter.format(provider.thisMonthBalance)}',
                  provider.thisMonthBalance >= 0 ? Colors.blue : Colors.orange,
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> expenseData) {
    final total = expenseData.values.fold(0.0, (sum, amount) => sum + amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別支出',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _generatePieChartSections(expenseData, total),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(expenseData, total),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
    Map<String, double> expenseData,
    double total,
  ) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    int colorIndex = 0;
    return expenseData.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> expenseData, double total) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];

    int colorIndex = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: expenseData.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        final percentage = (entry.value / total * 100).toStringAsFixed(1);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('${entry.key} ($percentage%)'),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDetails(
    BuildContext context,
    Map<String, double> expenseData,
  ) {
    final formatter = NumberFormat('#,###');
    final total = expenseData.values.fold(0.0, (sum, amount) => sum + amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'カテゴリ別詳細',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...() {
              final sortedEntries = expenseData.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return sortedEntries.map((entry) {
                final percentage = (entry.value / total * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(entry.key)),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: entry.value / total,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.red.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '¥${formatter.format(entry.value)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            }(),
          ],
        ),
      ),
    );
  }
}
