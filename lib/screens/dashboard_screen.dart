import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';

/// Sales Dashboard - Home screen with key metrics and quick stats
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.darkSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
            if (scaffoldState != null) {
              scaffoldState.openDrawer();
            }
          },
        ),
        title: Row(
          children: [
            Icon(
              Icons.dashboard,
              color: AppConstants.primaryOrange,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text(
              'Dashboard',
              style: AppConstants.headingMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Show profile
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppConstants.primaryOrange,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Key Metrics
              const Text(
                'Today\'s Overview',
                style: AppConstants.headingSmall,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildMetricsGrid(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Sales Chart
              const Text(
                'Sales This Week',
                style: AppConstants.headingSmall,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildSalesChart(),
              const SizedBox(height: AppConstants.paddingLarge),

              // Top Selling Items
              const Text(
                'Top Selling Items',
                style: AppConstants.headingSmall,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              _buildTopSellingItems(),
            ],
          ),
        ),
      ),
    );
  }

  /// Welcome section with date
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryOrange,
            AppConstants.accentOrange,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatDate(DateTime.now()),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Metrics grid with key stats
  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppConstants.paddingMedium,
      crossAxisSpacing: AppConstants.paddingMedium,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: 'Total Sales',
          value: '\$2,450',
          icon: Icons.attach_money,
          color: AppConstants.successGreen,
        ),
        StatCard(
          title: 'Orders',
          value: '42',
          icon: Icons.shopping_bag,
          color: AppConstants.primaryOrange,
        ),
        StatCard(
          title: 'Avg. Order',
          value: '\$58.33',
          icon: Icons.trending_up,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Active Tables',
          value: '8/15',
          icon: Icons.table_restaurant,
          color: AppConstants.warningYellow,
        ),
      ],
    );
  }

  /// Sales chart widget
  Widget _buildSalesChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: AppConstants.dividerColor,
          width: 1,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppConstants.dividerColor,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: AppConstants.bodySmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < days.length) {
                    return Text(
                      days[value.toInt()],
                      style: AppConstants.bodySmall,
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 1200),
                const FlSpot(1, 1500),
                const FlSpot(2, 1350),
                const FlSpot(3, 1800),
                const FlSpot(4, 2100),
                const FlSpot(5, 1950),
                const FlSpot(6, 2450),
              ],
              isCurved: true,
              color: AppConstants.primaryOrange,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppConstants.primaryOrange.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top selling items list
  Widget _buildTopSellingItems() {
    final items = [
      {'name': 'Margherita Pizza', 'sales': 45, 'revenue': 675.0},
      {'name': 'Caesar Salad', 'sales': 32, 'revenue': 384.0},
      {'name': 'Pasta Carbonara', 'sales': 28, 'revenue': 476.0},
      {'name': 'Iced Coffee', 'sales': 56, 'revenue': 224.0},
      {'name': 'Tiramisu', 'sales': 22, 'revenue': 198.0},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: AppConstants.dividerColor,
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          color: AppConstants.dividerColor,
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppConstants.primaryOrange.withOpacity(0.2),
              child: Text(
                '${index + 1}',
                style: AppConstants.bodyMedium.copyWith(
                  color: AppConstants.primaryOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item['name'] as String,
              style: AppConstants.bodyLarge,
            ),
            subtitle: Text(
              '${item['sales']} sold',
              style: AppConstants.bodySmall,
            ),
            trailing: Text(
              Formatters.formatCurrency(item['revenue'] as double),
              style: AppConstants.bodyLarge.copyWith(
                color: AppConstants.successGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Refresh data
  Future<void> _refreshData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data
    });
  }
}
