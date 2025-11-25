import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analytics_calendar_model.dart';
import '../models/sales_data_model.dart';
import '../services/analytics_calendar_service.dart';
import '../services/transaction_service.dart';
import '../services/forecast_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/stat_card.dart';

/// Sales & Performance Analysis screen with AI forecasting
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _dayNames = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final ForecastService _forecastService = ForecastService();
  final AnalyticsCalendarService _analyticsCalendarService =
      AnalyticsCalendarService();
  late TabController _tabController;
  List<SalesForecast> _forecasts = [];
  List<String> _insights = [];
  bool _isLoading = true;
  WeatherCalendarMonth? _calendarMonth;
  List<EventImpact> _eventImpacts = [];
  bool _isCalendarLoading = true;
  bool _isImpactsLoading = true;
  String? _calendarError;
  String? _impactsError;

  // Date range filters
  String _selectedForecastRange = '7 Days';

  // Date range picker
  DateTime? _startDate;
  DateTime? _endDate;

  // Calendar navigation
  DateTime _selectedCalendarMonth = DateTime.now();
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _countFormatter = NumberFormat.decimalPattern();
  List<TransactionRecord> _filteredTransactions = [];
  double _totalRevenue = 0;
  int _totalOrders = 0;
  double _averageOrderValue = 0;
  double? _revenueChangePercent;
  double? _orderChangePercent;
  double? _aovChangePercent;
  double _peakHourRevenue = 0;
  String _peakHourWindowLabel = '—';
  List<_DailyRevenuePoint> _dailyRevenuePoints = [];
  double _salesTrendMaxY = 0;
  List<_CategoryBreakdown> _categoryBreakdown = [];
  int _maxCategoryQuantity = 0;
  List<_ChannelBreakdown> _channelBreakdown = [];
  List<_TopSeller> _topSellers = [];
  List<_PaymentBreakdown> _paymentBreakdown = [];
  double _totalPaymentRevenue = 0;
  List<int> _heatmapHours = [];
  List<List<double>> _heatmapValues = [];
  double _heatmapMaxValue = 0;
  String _heatmapSummary = 'No transactions yet.';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            final scaffoldState = context
                .findAncestorStateOfType<ScaffoldState>();
            if (scaffoldState != null) {
              scaffoldState.openDrawer();
            }
          },
        ),
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppConstants.primaryOrange),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text('Analytics', style: AppConstants.headingMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryOrange,
          labelColor: AppConstants.primaryOrange,
          unselectedLabelColor: AppConstants.textSecondary,
          tabs: const [
            Tab(text: 'Historical'),
            Tab(text: 'AI Forecast'),
            Tab(text: 'Comparison'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryOrange,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildForecastTab(),
                _buildComparisonTab(),
              ],
            ),
    );
  }

  /// Overview tab with historical data
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range selector
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppConstants.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _dateRangeText,
                        style: AppConstants.bodyMedium,
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        onPressed: _clearDates,
                        icon: const Icon(Icons.clear),
                        color: AppConstants.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickSingleDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Single Date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.darkSecondary,
                          foregroundColor: AppConstants.primaryOrange,
                          side: const BorderSide(
                            color: AppConstants.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: const Text('Date Range'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.darkSecondary,
                          foregroundColor: AppConstants.primaryOrange,
                          side: const BorderSide(
                            color: AppConstants.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Key metrics cards
          _buildMetricsCards(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Sales Trend Chart
          _buildSalesTrendSection(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Category Sales Distribution
          const Text(
            'Category Sales Distribution',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildCategorySalesDistribution(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Order Channel Distribution
          const Text(
            'Order Channel Distribution',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildOrderChannelDistribution(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Top 10 Best Sellers
          const Text('Top 10 Best Sellers', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildTopSellingItems(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Payment Method Distribution
          const Text(
            'Payment Method Distribution',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildPaymentMethodDistribution(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Peak Hours Heatmap
          const Text('Peak Hours Analysis', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildPeakHoursHeatmap(),
        ],
      ),
    );
  }

  /// Forecast tab with AI predictions
  Widget _buildForecastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Forecast header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppConstants.dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppConstants.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    const Expanded(
                      child: Text(
                        'AI Forecast Results',
                        style: AppConstants.headingSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Predictions based on weather, holidays, and past trends.',
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                // Forecast Range Toggle
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.darkSecondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                      border: Border.all(color: AppConstants.dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildForecastRangeButton('7 Days'),
                        _buildForecastRangeButton('14 Days'),
                        _buildForecastRangeButton('30 Days'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Forecast Accuracy Metrics
          _buildForecastAccuracyCard(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Forecast Summary Cards
          const Text('Forecast Summary', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildForecastSummaryCards(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Forecast Trend Chart (Projected vs Actual)
          const Text(
            'Projected vs Actual Sales',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildProjectedVsActualChart(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Weather and Holidays Calendar
          const Text(
            'Weather & Events Calendar',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildWeatherCalendar(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Event and Weather Impact Analysis
          const Text(
            'Event & Weather Impact Analysis',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildEventWeatherImpact(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Demand Forecasting by Category
          const Text(
            'Demand Forecasting by Category',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildCategoryDemandForecast(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Delivery vs Dine-In Forecast
          const Text(
            'Order Channel Forecast',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildOrderChannelForecast(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Menu Item Performance Predictions
          const Text(
            'Menu Item Performance Predictions',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildMenuItemPredictions(),
          const SizedBox(height: AppConstants.paddingLarge),

          // AI Insights (inline below charts)
          const Text('AI Insights', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildInlineInsights(),
        ],
      ),
    );
  }

  /// Insights tab with AI recommendations
  /// Metrics cards
  Widget _buildMetricsCards() {
    final totalRevenueText = Formatters.formatCurrency(_totalRevenue);
    final totalOrdersText = _countFormatter.format(_totalOrders);
    final averageOrderValueText = Formatters.formatCurrency(_averageOrderValue);
    final peakRevenueText = Formatters.formatCurrency(_peakHourRevenue);
    final peakDetail = _peakHourWindowLabel == '—'
        ? null
        : 'Peak: $_peakHourWindowLabel';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Revenue',
                value: totalRevenueText,
                icon: Icons.trending_up,
                color: AppConstants.successGreen,
                percentageChange: _formatDelta(_revenueChangePercent),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: StatCard(
                title: 'Total Orders',
                value: totalOrdersText,
                icon: Icons.receipt,
                color: AppConstants.primaryOrange,
                percentageChange: _formatDelta(_orderChangePercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Avg. Order Value',
                value: averageOrderValueText,
                icon: Icons.shopping_cart,
                color: Colors.blue,
                percentageChange: _formatDelta(_aovChangePercent),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: StatCard(
                title: 'Peak Hour Revenue',
                value: peakRevenueText,
                icon: Icons.access_time,
                color: AppConstants.warningYellow,
                percentageChange: peakDetail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Forecast Range toggle button
  Widget _buildForecastRangeButton(String range) {
    final isSelected = _selectedForecastRange == range;
    return GestureDetector(
      onTap: () async {
        if (_selectedForecastRange == range) {
          return;
        }
        setState(() {
          _selectedForecastRange = range;
        });
        final nowMonth = DateTime.now();
        try {
          await _reloadCalendarForMonth(
            DateTime(nowMonth.year, nowMonth.month, 1),
          );
        } catch (e) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to refresh calendar: $e'),
              backgroundColor: AppConstants.errorRed,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
        ),
        child: Text(
          range,
          style: AppConstants.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppConstants.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _reloadCalendarForMonth(DateTime month) async {
    setState(() {
      _selectedCalendarMonth = month;
      _isCalendarLoading = true;
      _isImpactsLoading = true;
      _calendarError = null;
      _impactsError = null;
    });

    try {
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 0);

      final calendar = await _analyticsCalendarService.fetchMonth(
        month,
        fallbackRangeDays: _selectedRangeInDays(),
      );
      final impacts = await _analyticsCalendarService.fetchImpacts(
        start: monthStart,
        end: monthEnd,
        fallbackRangeDays: _selectedRangeInDays(),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _calendarMonth = calendar;
        _eventImpacts = impacts;
        _isCalendarLoading = false;
        _isImpactsLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCalendarLoading = false;
        _isImpactsLoading = false;
        _calendarError = e.toString();
        _impactsError = e.toString();
      });
      rethrow;
    }
  }

  Future<void> _changeCalendarMonth(int offset) async {
    final newMonth = DateTime(
      _selectedCalendarMonth.year,
      _selectedCalendarMonth.month + offset,
      1,
    );
    try {
      await _reloadCalendarForMonth(newMonth);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load calendar data: $e'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  /// Sales Trend Section
  Widget _buildSalesTrendSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Sales Trend', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          // Chart
          SizedBox(height: 250, child: _buildSalesTrendChart()),
        ],
      ),
    );
  }

  /// Sales Trend Chart
  Widget _buildSalesTrendChart() {
    if (_dailyRevenuePoints.isEmpty) {
      return Center(
        child: Text(
          'No completed transactions for the selected range yet.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    final dateFormat = DateFormat('MMMd');
    for (var i = 0; i < _dailyRevenuePoints.length; i++) {
      final point = _dailyRevenuePoints[i];
      spots.add(FlSpot(i.toDouble(), point.revenue));
      labels.add(dateFormat.format(point.date));
    }

    final maxY = _salesTrendMaxY <= 0 ? 1000.0 : _salesTrendMaxY;
    final yInterval = _computeYAxisInterval(maxY);
    final bottomInterval = spots.length <= 1
        ? 1
        : math.max(1, (spots.length / 6).ceil());

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppConstants.darkSecondary.withOpacity(0.95),
            tooltipRoundedRadius: AppConstants.radiusSmall,
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorder: BorderSide(
              color: AppConstants.primaryOrange,
              width: 1,
            ),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.round();
                final label = (index >= 0 && index < labels.length)
                    ? labels[index]
                    : 'Day ${index + 1}';
                return LineTooltipItem(
                  '$label\n',
                  AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sales: ',
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.primaryOrange,
                      ),
                    ),
                    TextSpan(
                      text: Formatters.formatCurrency(spot.y),
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.dividerColor.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppConstants.dividerColor.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    Formatters.formatCurrency(value),
                    style: AppConstants.bodySmall.copyWith(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: bottomInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                if (value.toInt() < labels.length) {
                  return Text(
                    labels[value.toInt()],
                    style: AppConstants.bodySmall.copyWith(fontSize: 10),
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
            spots: spots,
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
    );
  }

  /// Forecast Summary Cards
  Widget _buildForecastSummaryCards() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Predicted Revenue',
                  '₱58,450',
                  '+29.2% vs Historical',
                  Icons.trending_up,
                  AppConstants.successGreen,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildSummaryCard(
                  'Predicted Orders',
                  '890',
                  '+22.8% vs Historical',
                  Icons.receipt,
                  AppConstants.primaryOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Predicted Avg. Order',
                  '₱65.67',
                  '+5.2% vs Historical',
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildSummaryCard(
                  'Recommended Action',
                  'Stock Up Pasta',
                  'Top predicted item',
                  Icons.inventory,
                  AppConstants.warningYellow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Text(
                  title,
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            value,
            style: AppConstants.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppConstants.bodySmall.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Weather and Events Calendar
  Widget _buildWeatherCalendar() {
    final firstDayOfMonth = DateTime(
      _selectedCalendarMonth.year,
      _selectedCalendarMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedCalendarMonth.year,
      _selectedCalendarMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final now = DateTime.now();

    Widget buildCalendarBody() {
      if (_isCalendarLoading) {
        return SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppConstants.primaryOrange),
                const SizedBox(height: AppConstants.paddingSmall),
                const Text(
                  'Loading calendar...',
                  style: AppConstants.bodySmall,
                ),
              ],
            ),
          ),
        );
      }

      if (_calendarError != null) {
        return SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppConstants.errorRed),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  _calendarError!,
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                ElevatedButton.icon(
                  onPressed: () => _changeCalendarMonth(0),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final hasRangeOverlap = _monthOverlapsForecastRange(
        _selectedCalendarMonth,
      );
      final calendar =
          _calendarMonth ??
          WeatherCalendarMonth(month: _selectedCalendarMonth, days: const []);

      if (calendar.isEmpty && hasRangeOverlap) {
        return SizedBox(
          height: 260,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, color: AppConstants.textSecondary),
                const SizedBox(height: AppConstants.paddingSmall),
                const Text(
                  'No calendar data for this month yet.',
                  style: AppConstants.bodySmall,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Add documents under analytics_calendar/<yyyy-MM> in Firestore to populate this view.',
                  style: AppConstants.bodySmall.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: List.generate((daysInMonth + startingWeekday) ~/ 7 + 1, (
          weekIndex,
        ) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber =
                    weekIndex * 7 + dayIndex - startingWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 70));
                }

                final currentDate = DateTime(
                  _selectedCalendarMonth.year,
                  _selectedCalendarMonth.month,
                  dayNumber,
                );
                final isToday =
                    currentDate.year == now.year &&
                    currentDate.month == now.month &&
                    currentDate.day == now.day;
                final isInForecastRange = _isWithinSelectedForecastRange(
                  currentDate,
                );
                final weatherDay = isInForecastRange
                    ? calendar.dayForNumber(dayNumber)
                    : null;
                final hasEvent = weatherDay?.hasEvent ?? false;
                final hasWeather = weatherDay != null;

                final backgroundColor = isToday
                    ? AppConstants.primaryOrange.withOpacity(0.2)
                    : hasEvent
                    ? AppConstants.primaryOrange.withOpacity(0.12)
                    : isInForecastRange
                    ? AppConstants.successGreen.withOpacity(0.08)
                    : AppConstants.darkSecondary.withOpacity(0.5);

                final borderColor = isToday
                    ? AppConstants.primaryOrange
                    : hasEvent
                    ? AppConstants.primaryOrange
                    : isInForecastRange
                    ? AppConstants.successGreen.withOpacity(0.6)
                    : AppConstants.dividerColor.withOpacity(0.3);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColor,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$dayNumber',
                          style: AppConstants.bodyMedium.copyWith(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isToday
                                ? AppConstants.primaryOrange
                                : AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        hasWeather && isInForecastRange
                            ? Text(
                                weatherDay?.emoji ?? '–',
                                style: const TextStyle(fontSize: 16),
                              )
                            : const SizedBox(height: 16),
                        const SizedBox(height: 2),
                        hasEvent && isInForecastRange
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppConstants.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: AppConstants.primaryOrange,
                ),
                onPressed: () => _changeCalendarMonth(-1),
                tooltip: 'Previous Month',
              ),
              Text(
                '${_getMonthName(_selectedCalendarMonth.month)} ${_selectedCalendarMonth.year}',
                style: AppConstants.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: AppConstants.primaryOrange,
                ),
                onPressed: () => _changeCalendarMonth(1),
                tooltip: 'Next Month',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.successGreen,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Forecast Range ($_selectedForecastRange)',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Holiday/Event',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((
              day,
            ) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppConstants.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          buildCalendarBody(),
        ],
      ),
    );
  }

  /// Helper method to get month name
  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  /// Event and Weather Impact Analysis
  Widget _buildEventWeatherImpact() {
    if (_isImpactsLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppConstants.primaryOrange),
              const SizedBox(height: AppConstants.paddingSmall),
              const Text(
                'Loading event impacts...',
                style: AppConstants.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    if (_impactsError != null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppConstants.errorRed),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              _impactsError!,
              style: AppConstants.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            ElevatedButton.icon(
              onPressed: () => _changeCalendarMonth(0),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryOrange,
              ),
            ),
          ],
        ),
      );
    }

    if (_eventImpacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note, color: AppConstants.textSecondary),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'No upcoming events found for this month.',
              style: AppConstants.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Add records in analytics_impacts with a date inside this month to see projections here.',
              style: AppConstants.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: _eventImpacts.map((impact) {
          final color = _eventImpactColor(impact);
          final impactPercent = _formatImpactPercent(impact.impactPercent);
          final expectedSales = impact.expectedSales;

          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.darkSecondary,
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatImpactDate(impact.date),
                            style: AppConstants.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                impact.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _buildImpactHeadline(impact),
                                  style: AppConstants.bodySmall.copyWith(
                                    color: AppConstants.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            impactPercent,
                            style: AppConstants.bodySmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expectedSales != null
                              ? Formatters.formatCurrency(expectedSales)
                              : '—',
                          style: AppConstants.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                if ((impact.recommendation ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            impact.recommendation!,
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Demand Forecasting by Category
  Widget _buildCategoryDemandForecast() {
    final categories = [
      {
        'name': 'Main Course',
        'predicted': 340,
        'historical': 280,
        'change': '+21%',
        'isIncrease': true,
        'color': AppConstants.primaryOrange,
        'icon': Icons.restaurant,
      },
      {
        'name': 'Beverages',
        'predicted': 210,
        'historical': 178,
        'change': '+18%',
        'isIncrease': true,
        'color': Colors.blue,
        'icon': Icons.local_cafe,
      },
      {
        'name': 'Appetizers',
        'predicted': 120,
        'historical': 105,
        'change': '+14%',
        'isIncrease': true,
        'color': AppConstants.successGreen,
        'icon': Icons.fastfood,
      },
      {
        'name': 'Desserts',
        'predicted': 85,
        'historical': 78,
        'change': '+9%',
        'isIncrease': true,
        'color': Colors.pink,
        'icon': Icons.cake,
      },
      {
        'name': 'Sides',
        'predicted': 65,
        'historical': 72,
        'change': '-10%',
        'isIncrease': false,
        'color': AppConstants.warningYellow,
        'icon': Icons.food_bank,
      },
    ];

    final maxValue = 340;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          ...categories.map((category) {
            final percentage = (category['predicted'] as int) / maxValue;
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (category['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: category['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['name'] as String,
                              style: AppConstants.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Historical: ${category['historical']} orders',
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${category['predicted']} orders',
                            style: AppConstants.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: category['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (category['isIncrease'] as bool
                                          ? AppConstants.successGreen
                                          : AppConstants.errorRed)
                                      .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category['isIncrease'] as bool
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: category['isIncrease'] as bool
                                      ? AppConstants.successGreen
                                      : AppConstants.errorRed,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  category['change'] as String,
                                  style: AppConstants.bodySmall.copyWith(
                                    color: category['isIncrease'] as bool
                                        ? AppConstants.successGreen
                                        : AppConstants.errorRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: AppConstants.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        category['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Order Channel Forecast (Delivery vs Dine-In)
  Widget _buildOrderChannelForecast() {
    final channels = [
      {
        'name': 'Dine-In',
        'percentage': 65,
        'orders': 540,
        'revenue': '₱33,800',
        'historical': '470 orders',
        'trend': '+15%',
        'color': AppConstants.primaryOrange,
        'icon': Icons.restaurant_menu,
        'peak': 'Sat-Sun Lunch & Dinner',
      },
      {
        'name': 'Takeout',
        'percentage': 25,
        'orders': 208,
        'revenue': '₱13,000',
        'historical': '181 orders',
        'trend': '+15%',
        'color': Colors.blue,
        'icon': Icons.shopping_bag,
        'peak': 'Weekday Lunch',
      },
      {
        'name': 'Delivery',
        'percentage': 10,
        'orders': 83,
        'revenue': '₱5,200',
        'historical': '74 orders',
        'trend': '+12%',
        'color': AppConstants.successGreen,
        'icon': Icons.delivery_dining,
        'peak': 'Rainy Days, Late Night',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Visual percentage bar
          Row(
            children: channels.map((channel) {
              final isFirst = channel == channels.first;
              final isLast = channel == channels.last;

              return Expanded(
                flex: channel['percentage'] as int,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: channel['color'] as Color,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                      bottomLeft: isFirst
                          ? const Radius.circular(8)
                          : Radius.zero,
                      topRight: isLast ? const Radius.circular(8) : Radius.zero,
                      bottomRight: isLast
                          ? const Radius.circular(8)
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${channel['percentage']}%',
                      style: AppConstants.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Channel details
          ...channels.map((channel) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.darkSecondary,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(
                  color: (channel['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (channel['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      channel['icon'] as IconData,
                      color: channel['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              channel['name'] as String,
                              style: AppConstants.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.successGreen.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                channel['trend'] as String,
                                style: AppConstants.bodySmall.copyWith(
                                  color: AppConstants.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Predicted: ${channel['orders']} orders • ${channel['revenue']}',
                          style: AppConstants.bodyMedium.copyWith(
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Historical: ${channel['historical']}',
                          style: AppConstants.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Peak: ${channel['peak']}',
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Menu Item Performance Predictions
  Widget _buildMenuItemPredictions() {
    final items = [
      {
        'category': 'Star Performers',
        'description': 'High demand expected',
        'color': AppConstants.successGreen,
        'items': [
          {'name': 'Pasta Carbonara', 'orders': 145, 'trend': '+22%'},
          {'name': 'Grilled Salmon', 'orders': 98, 'trend': '+18%'},
          {'name': 'Crispy Chicken', 'orders': 87, 'trend': '+15%'},
        ],
      },
      {
        'category': 'Rising Stars',
        'description': 'Growing popularity',
        'color': AppConstants.primaryOrange,
        'items': [
          {'name': 'Vegan Bowl', 'orders': 52, 'trend': '+35%'},
          {'name': 'Matcha Latte', 'orders': 48, 'trend': '+28%'},
          {'name': 'Korean BBQ', 'orders': 41, 'trend': '+25%'},
        ],
      },
      {
        'category': 'Declining Items',
        'description': 'Consider promotion or removal',
        'color': AppConstants.warningYellow,
        'items': [
          {'name': 'Fish & Chips', 'orders': 32, 'trend': '-15%'},
          {'name': 'Minestrone Soup', 'orders': 28, 'trend': '-20%'},
          {'name': 'Caesar Wrap', 'orders': 24, 'trend': '-12%'},
        ],
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: items.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: group['color'] as Color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['category'] as String,
                            style: AppConstants.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: group['color'] as Color,
                            ),
                          ),
                          Text(
                            group['description'] as String,
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                ...(group['items'] as List).map((item) {
                  final itemMap = item as Map<String, dynamic>;
                  final isNegative = (itemMap['trend'] as String).startsWith(
                    '-',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    decoration: BoxDecoration(
                      color: AppConstants.darkSecondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isNegative ? Icons.trending_down : Icons.trending_up,
                          color: group['color'] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            itemMap['name'] as String,
                            style: AppConstants.bodyMedium,
                          ),
                        ),
                        Text(
                          '${itemMap['orders']} orders',
                          style: AppConstants.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (group['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            itemMap['trend'] as String,
                            style: AppConstants.bodySmall.copyWith(
                              color: group['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Projected vs Actual Chart
  Widget _buildProjectedVsActualChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Actual Sales',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Projected Sales',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: 18000,
                minY: 0,
                // Interactive tooltips for forecast chart
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppConstants.darkSecondary.withOpacity(0.95),
                    tooltipRoundedRadius: AppConstants.radiusSmall,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: AppConstants.primaryOrange,
                      width: 1,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        final isActual = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${days[spot.x.toInt()]}\n',
                          AppConstants.bodySmall.copyWith(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${isActual ? "Actual" : "Projected"}: ',
                              style: AppConstants.bodySmall.copyWith(
                                color: isActual
                                    ? AppConstants.successGreen
                                    : AppConstants.primaryOrange,
                              ),
                            ),
                            TextSpan(
                              text: '₱${(spot.y / 1000).toStringAsFixed(1)}K',
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppConstants.dividerColor.withOpacity(0.3),
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
                      reservedSize: 50,
                      interval: 2000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₱${(value / 1000).toStringAsFixed(0)}K',
                          style: AppConstants.bodySmall.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        if (value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: AppConstants.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual Sales - mirroring Historical Sales Trend
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 8500),
                      const FlSpot(1, 10200),
                      const FlSpot(2, 9800),
                      const FlSpot(3, 12500),
                      const FlSpot(4, 15200),
                      const FlSpot(5, 14800),
                      const FlSpot(6, 16500),
                    ],
                    isCurved: true,
                    color: AppConstants.successGreen,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Projected Sales
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 8200),
                      const FlSpot(1, 9900),
                      const FlSpot(2, 10500),
                      const FlSpot(3, 12200),
                      const FlSpot(4, 15600),
                      const FlSpot(5, 15200),
                      const FlSpot(6, 17200),
                    ],
                    isCurved: true,
                    color: AppConstants.primaryOrange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    dashArray: [5, 5], // Dashed line for projected
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.primaryOrange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Forecast Accuracy Card
  Widget _buildForecastAccuracyCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: AppConstants.successGreen, size: 20),
              const SizedBox(width: AppConstants.paddingSmall),
              const Text(
                'Forecast Accuracy Metrics',
                style: AppConstants.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Accuracy',
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '87.3%',
                          style: AppConstants.headingMedium.copyWith(
                            color: AppConstants.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.successGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+2.1%',
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.873,
                      backgroundColor: AppConstants.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '92.1%',
                      style: AppConstants.headingMedium.copyWith(
                        color: AppConstants.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.921,
                      backgroundColor: AppConstants.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.successGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Divider(color: AppConstants.dividerColor),
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAccuracyMetric('Sales', '89%', AppConstants.primaryOrange),
              _buildAccuracyMetric('Traffic', '91%', Colors.blue),
              _buildAccuracyMetric(
                'Peak Hours',
                '85%',
                AppConstants.warningYellow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppConstants.bodyLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Category Sales Distribution (Historical)
  Widget _buildCategorySalesDistribution() {
    final palette = [
      AppConstants.primaryOrange,
      Colors.blue,
      AppConstants.successGreen,
      Colors.pink,
      AppConstants.warningYellow,
      Colors.purple,
      Colors.teal,
    ];

    if (_categoryBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Text(
          'No category sales recorded for the selected range.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final maxValue = _maxCategoryQuantity.clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          ..._categoryBreakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final color = palette[index % palette.length];
            final percentage = maxValue == 0
                ? 0.0
                : category.quantity / maxValue;
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.restaurant, color: color, size: 20),
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: AppConstants.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(category.revenue),
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_countFormatter.format(category.quantity)} items',
                        style: AppConstants.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      minHeight: 8,
                      backgroundColor: AppConstants.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Order Channel Distribution (Historical)
  Widget _buildOrderChannelDistribution() {
    if (_channelBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Text(
          'No order channel data for the selected range.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final palette = [
      AppConstants.primaryOrange,
      Colors.blue,
      AppConstants.successGreen,
      Colors.purple,
      Colors.teal,
      AppConstants.warningYellow,
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Visual percentage bar
          Row(
            children: _channelBreakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final channel = entry.value;
              final color = palette[index % palette.length];
              final share = channel.share;
              final flexValue = (share <= 0)
                  ? 1
                  : share.isFinite
                  ? share * 100
                  : 1;
              final flex = flexValue.clamp(1, 100).round();
              final isFirst = index == 0;
              final isLast = index == _channelBreakdown.length - 1;

              return Expanded(
                flex: flex,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirst ? const Radius.circular(8) : Radius.zero,
                      bottomLeft: isFirst
                          ? const Radius.circular(8)
                          : Radius.zero,
                      topRight: isLast ? const Radius.circular(8) : Radius.zero,
                      bottomRight: isLast
                          ? const Radius.circular(8)
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${(share * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: AppConstants.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Channel details
          ..._channelBreakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final channel = entry.value;
            final color = palette[index % palette.length];
            final icon = _channelIcon(channel.name);
            final peakText = channel.peakLabel == null
                ? 'Peak time unavailable'
                : 'Peak: ${channel.peakLabel}';
            final sharePercent = (channel.share * 100).clamp(0, 100);

            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.darkSecondary,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: AppConstants.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_countFormatter.format(channel.orders)} orders • ${Formatters.formatCurrency(channel.revenue)}',
                          style: AppConstants.bodyMedium.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppConstants.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              peakText,
                              style: AppConstants.bodySmall.copyWith(
                                color: AppConstants.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${sharePercent.toStringAsFixed(1)}%',
                        style: AppConstants.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(channel.revenue),
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Top Selling Items
  Widget _buildTopSellingItems() {
    if (_topSellers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Text(
          'No item performance data for the selected range.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final maxSold = _topSellers
        .fold<int>(0, (max, item) => math.max(max, item.quantity))
        .clamp(1, 1 << 30);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Item', style: AppConstants.bodySmall),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Qty Sold',
                  style: AppConstants.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(
                flex: 2,
                child: Text(
                  'Revenue',
                  style: AppConstants.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(color: AppConstants.dividerColor),
          // Items List
          ..._topSellers.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = maxSold == 0 ? 0.0 : item.quantity / maxSold;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? AppConstants.primaryOrange.withOpacity(0.2)
                              : AppConstants.darkSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: index < 3
                              ? Border.all(
                                  color: AppConstants.primaryOrange,
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppConstants.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: index < 3
                                  ? AppConstants.primaryOrange
                                  : AppConstants.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Item Name
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.name,
                          style: AppConstants.bodyMedium.copyWith(
                            fontWeight: index < 3
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Quantity
                      Expanded(
                        flex: 2,
                        child: Text(
                          _countFormatter.format(item.quantity),
                          style: AppConstants.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Revenue
                      Expanded(
                        flex: 2,
                        child: Text(
                          Formatters.formatCurrency(item.revenue),
                          style: AppConstants.bodyMedium.copyWith(
                            color: AppConstants.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress Bar
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppConstants.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index < 3
                          ? AppConstants.primaryOrange
                          : AppConstants.successGreen,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Payment Method Distribution
  Widget _buildPaymentMethodDistribution() {
    if (_paymentBreakdown.isEmpty || _totalPaymentRevenue <= 0) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Text(
          'No payment method data for the selected range.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final palette = [
      AppConstants.successGreen,
      Colors.blue,
      AppConstants.primaryOrange,
      AppConstants.warningYellow,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Pie chart representation using stacked bars
          Row(
            children: _paymentBreakdown.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final color = palette[index % palette.length];
              final percentage = _totalPaymentRevenue == 0
                  ? 0.0
                  : (data.amount / _totalPaymentRevenue);
              final isFirst = index == 0;
              final isLast = index == _paymentBreakdown.length - 1;

              return Expanded(
                flex: (percentage * 100).toInt(),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: isFirst
                        ? const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          )
                        : isLast
                        ? const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${(percentage * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: AppConstants.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          // Payment details
          ..._paymentBreakdown.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final color = palette[index % palette.length];
            final amount = data.amount;
            final percentage = _totalPaymentRevenue == 0
                ? 0.0
                : (amount / _totalPaymentRevenue) * 100;
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppConstants.paddingMedium,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(data.method, style: AppConstants.bodyMedium),
                  ),
                  Text(
                    '${_countFormatter.format(data.count)} orders',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Text(
                    Formatters.formatCurrency(amount),
                    style: AppConstants.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppConstants.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Peak Hours Heatmap
  Widget _buildPeakHoursHeatmap() {
    if (_heatmapHours.isEmpty || _heatmapValues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(color: AppConstants.dividerColor, width: 1),
        ),
        child: Text(
          'No hourly sales activity recorded for the selected range.',
          style: AppConstants.bodySmall.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      );
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = _heatmapMaxValue <= 0 ? 1 : _heatmapMaxValue;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Low',
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(i / 4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                'High',
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          // Day headers
          Row(
            children: [
              const SizedBox(width: 50), // Space for hour labels
              ...days
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppConstants.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
          const SizedBox(height: 8),
          // Heatmap grid
          ...List.generate(_heatmapHours.length, (hourIndex) {
            final hour = _heatmapHours[hourIndex];
            final hourLabel = _formatHourLabel(hour);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      hourLabel,
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                  ...List.generate(7, (dayIndex) {
                    final value = _heatmapValues[hourIndex][dayIndex];
                    final intensity = maxValue == 0 ? 0.0 : value / maxValue;

                    return Expanded(
                      child: Tooltip(
                        message:
                            '${days[dayIndex]} ${_formatHourRange(hour)}\n${Formatters.formatCurrency(value)}',
                        child: Container(
                          height: 24,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: _getHeatmapColor(intensity),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: AppConstants.paddingMedium),
          // Summary
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            decoration: BoxDecoration(
              color: AppConstants.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              border: Border.all(
                color: AppConstants.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppConstants.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _heatmapSummary,
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity < 0.2) return AppConstants.successGreen.withOpacity(0.2);
    if (intensity < 0.4) return AppConstants.successGreen.withOpacity(0.4);
    if (intensity < 0.6) return AppConstants.warningYellow.withOpacity(0.6);
    if (intensity < 0.8) return AppConstants.primaryOrange.withOpacity(0.7);
    return AppConstants.errorRed.withOpacity(0.8);
  }

  /// Inline AI Insights
  Widget _buildInlineInsights() {
    final insights = [
      {
        'text':
            'Schedule +2 servers for Saturday lunch (12-2PM). Expected 35% traffic increase.',
        'action': 'View Schedule',
        'icon': Icons.people,
        'color': AppConstants.primaryOrange,
        'priority': 'High',
      },
      {
        'text':
            'Order 30kg pasta by Thursday. Forecast shows 145 orders this weekend.',
        'action': 'Update Inventory',
        'icon': Icons.inventory_2,
        'color': AppConstants.warningYellow,
        'priority': 'High',
      },
      {
        'text':
            'Rain expected Friday. Promote comfort food combos - historically 22% sales boost.',
        'action': 'Create Promo',
        'icon': Icons.campaign,
        'color': Colors.blue,
        'priority': 'Medium',
      },
      {
        'text':
            'Dessert demand up 18% but stock low. Add Leche Flan to specials board.',
        'action': 'Add to Menu',
        'icon': Icons.cake,
        'color': AppConstants.successGreen,
        'priority': 'Medium',
      },
      {
        'text':
            'Monday typically slow. Run 20% lunch special to boost 11AM-1PM traffic.',
        'action': 'Set Discount',
        'icon': Icons.local_offer,
        'color': Colors.purple,
        'priority': 'Low',
      },
    ];

    return Column(
      children: insights.map((insight) {
        final priority = insight['priority'] as String;
        Color priorityColor = AppConstants.textSecondary;
        if (priority == 'High') {
          priorityColor = AppConstants.errorRed;
        } else if (priority == 'Medium') {
          priorityColor = AppConstants.warningYellow;
        }

        final borderColor = priority == 'High'
            ? AppConstants.primaryOrange.withOpacity(0.5)
            : AppConstants.dividerColor;

        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (insight['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      insight['icon'] as IconData,
                      color: insight['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight['text'] as String,
                          style: AppConstants.bodyMedium.copyWith(
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Priority: $priority',
                            style: AppConstants.bodySmall.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${insight['action']} feature coming soon!',
                        ),
                        backgroundColor: AppConstants.primaryOrange,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppConstants.primaryOrange,
                  ),
                  label: Text(
                    insight['action'] as String,
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Comparison Overlay Modal
  /// Comparison tab
  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(color: AppConstants.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: AppConstants.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingSmall),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historical vs Forecast Comparison',
                        style: AppConstants.headingSmall,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Compare actual performance with AI predictions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Key Metrics Comparison
          const Text(
            'Key Metrics Comparison',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildMetricsComparison(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Sales Trend Comparison Chart
          const Text(
            'Sales Trend: Historical vs Forecast',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildSalesTrendComparison(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Category Performance Comparison
          const Text(
            'Category Performance Comparison',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildCategoryComparison(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Channel Distribution Comparison
          const Text(
            'Order Channel Distribution',
            style: AppConstants.headingSmall,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildChannelComparison(),
          const SizedBox(height: AppConstants.paddingLarge),

          // Insights & Recommendations
          const Text('Key Insights', style: AppConstants.headingSmall),
          const SizedBox(height: AppConstants.paddingMedium),
          _buildComparisonInsights(),
        ],
      ),
    );
  }

  /// Metrics Comparison Cards
  Widget _buildMetricsComparison() {
    final metrics = [
      {
        'title': 'Total Revenue',
        'historical': '₱45,230',
        'forecast': '₱58,450',
        'difference': '+29.2%',
        'isIncrease': true,
        'icon': Icons.trending_up,
        'color': AppConstants.successGreen,
      },
      {
        'title': 'Total Orders',
        'historical': '725',
        'forecast': '890',
        'difference': '+22.8%',
        'isIncrease': true,
        'icon': Icons.receipt,
        'color': AppConstants.primaryOrange,
      },
      {
        'title': 'Avg. Order Value',
        'historical': '₱62.40',
        'forecast': '₱65.67',
        'difference': '+5.2%',
        'isIncrease': true,
        'icon': Icons.shopping_cart,
        'color': Colors.blue,
      },
    ];

    return Column(
      children: metrics.map((metric) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: AppConstants.dividerColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Icon(
                    metric['icon'] as IconData,
                    color: metric['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    metric['title'] as String,
                    style: AppConstants.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),

              // Values row
              Row(
                children: [
                  // Historical
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppConstants.darkSecondary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSmall,
                        ),
                        border: Border.all(
                          color: AppConstants.textSecondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historical',
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric['historical'] as String,
                            style: AppConstants.headingSmall.copyWith(
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Arrow and difference
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: AppConstants.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (metric['isIncrease'] as bool
                                        ? AppConstants.successGreen
                                        : Colors.red)
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                metric['isIncrease'] as bool
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: metric['isIncrease'] as bool
                                    ? AppConstants.successGreen
                                    : Colors.red,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                metric['difference'] as String,
                                style: AppConstants.bodySmall.copyWith(
                                  color: metric['isIncrease'] as bool
                                      ? AppConstants.successGreen
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Forecast
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSmall,
                        ),
                        border: Border.all(
                          color: AppConstants.primaryOrange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forecast',
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric['forecast'] as String,
                            style: AppConstants.headingSmall.copyWith(
                              color: AppConstants.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Sales Trend Comparison Chart
  Widget _buildSalesTrendComparison() {
    final historicalSpots = [
      const FlSpot(0, 8500),
      const FlSpot(1, 10200),
      const FlSpot(2, 9800),
      const FlSpot(3, 12500),
      const FlSpot(4, 15200),
      const FlSpot(5, 14800),
      const FlSpot(6, 16500),
    ];

    final forecastSpots = [
      const FlSpot(0, 8200),
      const FlSpot(1, 9900),
      const FlSpot(2, 10500),
      const FlSpot(3, 12200),
      const FlSpot(4, 15600),
      const FlSpot(5, 15200),
      const FlSpot(6, 17200),
    ];

    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppConstants.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Historical Sales',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Forecast Sales',
                    style: AppConstants.bodySmall.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: 18000,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2000,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppConstants.dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppConstants.dividerColor.withOpacity(0.3),
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
                      reservedSize: 50,
                      interval: 2000,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '₱${(value / 1000).toStringAsFixed(0)}K',
                            style: AppConstants.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: AppConstants.bodySmall.copyWith(
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Historical line
                  LineChartBarData(
                    spots: historicalSpots,
                    isCurved: true,
                    color: AppConstants.successGreen,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.successGreen.withOpacity(0.1),
                    ),
                  ),
                  // Forecast line
                  LineChartBarData(
                    spots: forecastSpots,
                    isCurved: true,
                    color: AppConstants.primaryOrange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    dashArray: [5, 5],
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.primaryOrange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Category Comparison
  Widget _buildCategoryComparison() {
    final categories = [
      {
        'name': 'Main Course',
        'historical': 280,
        'forecast': 340,
        'color': AppConstants.primaryOrange,
        'icon': Icons.restaurant,
      },
      {
        'name': 'Beverages',
        'historical': 178,
        'forecast': 210,
        'color': Colors.blue,
        'icon': Icons.local_cafe,
      },
      {
        'name': 'Appetizers',
        'historical': 105,
        'forecast': 120,
        'color': AppConstants.successGreen,
        'icon': Icons.fastfood,
      },
      {
        'name': 'Desserts',
        'historical': 78,
        'forecast': 85,
        'color': Colors.pink,
        'icon': Icons.cake,
      },
      {
        'name': 'Sides',
        'historical': 72,
        'forecast': 65,
        'color': AppConstants.warningYellow,
        'icon': Icons.food_bank,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: categories.map((category) {
          final historical = category['historical'] as int;
          final forecast = category['forecast'] as int;
          final change = ((forecast - historical) / historical * 100);
          final isIncrease = change > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: category['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        category['name'] as String,
                        style: AppConstants.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isIncrease
                                    ? AppConstants.successGreen
                                    : Colors.red)
                                .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncrease
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isIncrease
                                ? AppConstants.successGreen
                                : Colors.red,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${change.abs().toStringAsFixed(0)}%',
                            style: AppConstants.bodySmall.copyWith(
                              color: isIncrease
                                  ? AppConstants.successGreen
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historical: $historical orders',
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: historical / 340,
                              minHeight: 6,
                              backgroundColor: AppConstants.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forecast: $forecast orders',
                            style: AppConstants.bodySmall.copyWith(
                              color: AppConstants.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: forecast / 340,
                              minHeight: 6,
                              backgroundColor: AppConstants.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                category['color'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Channel Comparison
  Widget _buildChannelComparison() {
    final channels = [
      {
        'name': 'Dine-In',
        'historical': 470,
        'forecast': 540,
        'historicalPct': 65,
        'forecastPct': 65,
        'color': AppConstants.primaryOrange,
        'icon': Icons.restaurant_menu,
      },
      {
        'name': 'Takeout',
        'historical': 181,
        'forecast': 208,
        'historicalPct': 25,
        'forecastPct': 25,
        'color': Colors.blue,
        'icon': Icons.shopping_bag,
      },
      {
        'name': 'Delivery',
        'historical': 74,
        'forecast': 83,
        'historicalPct': 10,
        'forecastPct': 10,
        'color': AppConstants.successGreen,
        'icon': Icons.delivery_dining,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(color: AppConstants.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Historical bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historical Distribution',
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: channels.map((channel) {
                  final isFirst = channel == channels.first;
                  final isLast = channel == channels.last;

                  return Expanded(
                    flex: channel['historicalPct'] as int,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: (channel['color'] as Color).withOpacity(0.5),
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst
                              ? const Radius.circular(6)
                              : Radius.zero,
                          bottomLeft: isFirst
                              ? const Radius.circular(6)
                              : Radius.zero,
                          topRight: isLast
                              ? const Radius.circular(6)
                              : Radius.zero,
                          bottomRight: isLast
                              ? const Radius.circular(6)
                              : Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${channel['historicalPct']}%',
                          style: AppConstants.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Forecast bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forecast Distribution',
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.primaryOrange,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: channels.map((channel) {
                  final isFirst = channel == channels.first;
                  final isLast = channel == channels.last;

                  return Expanded(
                    flex: channel['forecastPct'] as int,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: channel['color'] as Color,
                        borderRadius: BorderRadius.only(
                          topLeft: isFirst
                              ? const Radius.circular(6)
                              : Radius.zero,
                          bottomLeft: isFirst
                              ? const Radius.circular(6)
                              : Radius.zero,
                          topRight: isLast
                              ? const Radius.circular(6)
                              : Radius.zero,
                          bottomRight: isLast
                              ? const Radius.circular(6)
                              : Radius.zero,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${channel['forecastPct']}%',
                          style: AppConstants.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          // Channel details
          ...channels.map((channel) {
            final historical = channel['historical'] as int;
            final forecast = channel['forecast'] as int;
            final change = ((forecast - historical) / historical * 100);

            return Container(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.darkSecondary,
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                border: Border.all(
                  color: (channel['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    channel['icon'] as IconData,
                    color: channel['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      channel['name'] as String,
                      style: AppConstants.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$historical → $forecast orders',
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${change.toStringAsFixed(0)}%',
                        style: AppConstants.bodySmall.copyWith(
                          color: AppConstants.successGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Comparison Insights
  Widget _buildComparisonInsights() {
    final insights = [
      {
        'icon': Icons.trending_up,
        'color': AppConstants.successGreen,
        'title': 'Strong Growth Projection',
        'description':
            'Revenue forecast shows a 29.2% increase, driven by upcoming events and weather patterns.',
      },
      {
        'icon': Icons.restaurant,
        'color': AppConstants.primaryOrange,
        'title': 'Main Course Surge',
        'description':
            'Main Course category expected to grow by 21%, suggesting increased demand for full meals.',
      },
      {
        'icon': Icons.delivery_dining,
        'color': Colors.blue,
        'title': 'Channel Consistency',
        'description':
            'Order channel distribution remains stable at 65-25-10, with growth across all channels.',
      },
      {
        'icon': Icons.lightbulb_outline,
        'color': AppConstants.warningYellow,
        'title': 'Recommended Actions',
        'description':
            'Stock up on Pasta ingredients. Add 2 servers for peak hours. Promote comfort food during rainy days.',
      },
    ];

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: (insight['color'] as Color).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (insight['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: insight['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'] as String,
                      style: AppConstants.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['description'] as String,
                      style: AppConstants.bodySmall.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Date range text
  String get _dateRangeText {
    if (_startDate == null)
      return 'Showing: ${Formatters.formatDate(DateTime.now())}';
    if (_endDate == null)
      return 'Showing: ${Formatters.formatDate(_startDate!)}';
    return 'Showing: ${Formatters.formatDate(_startDate!)} - ${Formatters.formatDate(_endDate!)}';
  }

  /// Pick date range
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(), // Restrict to present day and earlier
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppConstants.primaryOrange,
            onPrimary: Colors.white,
            surface: AppConstants.cardBackground,
            onSurface: AppConstants.textPrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  /// Pick single date
  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(), // Restrict to present day and earlier
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppConstants.primaryOrange,
            onPrimary: Colors.white,
            surface: AppConstants.cardBackground,
            onSurface: AppConstants.textPrimary,
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = null;
      });
    }
  }

  /// Clear dates
  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  /// Load analytics data
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _isCalendarLoading = true;
      _isImpactsLoading = true;
      _calendarError = null;
      _impactsError = null;
    });

    try {
      final now = DateTime.now();
      final forecastRange = Duration(days: _selectedRangeInDays());
      final forecastsFuture = _forecastService.getSalesForecast(
        startDate: now,
        endDate: now.add(forecastRange),
      );
      final insightsFuture = _forecastService.getSalesInsights();
      final transactionsFuture = _transactionService.fetchTransactions();

      final monthStart = DateTime(
        _selectedCalendarMonth.year,
        _selectedCalendarMonth.month,
        1,
      );
      final monthEnd = DateTime(
        _selectedCalendarMonth.year,
        _selectedCalendarMonth.month + 1,
        0,
      );

      final calendarFuture = _analyticsCalendarService.fetchMonth(
        _selectedCalendarMonth,
        fallbackRangeDays: _selectedRangeInDays(),
      );
      final impactsFuture = _analyticsCalendarService.fetchImpacts(
        start: monthStart,
        end: monthEnd,
        fallbackRangeDays: _selectedRangeInDays(),
      );

      final forecasts = await forecastsFuture;
      final insights = await insightsFuture;
      final calendar = await calendarFuture;
      final impacts = await impactsFuture;
      final transactions = await transactionsFuture;
      final analyticsSnapshot = _calculateHistoricalAnalytics(transactions);

      if (!mounted) {
        return;
      }

      setState(() {
        _forecasts = forecasts;
        _insights = insights;
        _calendarMonth = calendar;
        _eventImpacts = impacts;
        _applyAnalyticsSnapshot(analyticsSnapshot);
        _isLoading = false;
        _isCalendarLoading = false;
        _isImpactsLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCalendarLoading = false;
        _isImpactsLoading = false;
        _calendarError ??= e.toString();
        _impactsError ??= e.toString();
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading analytics: $e'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  int _selectedRangeInDays() {
    switch (_selectedForecastRange) {
      case '14 Days':
        return 14;
      case '30 Days':
        return 30;
      default:
        return 7;
    }
  }

  bool _isWithinSelectedForecastRange(DateTime date) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: _selectedRangeInDays() - 1));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  bool _monthOverlapsForecastRange(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    for (
      var current = first;
      !current.isAfter(last);
      current = current.add(const Duration(days: 1))
    ) {
      if (_isWithinSelectedForecastRange(current)) {
        return true;
      }
    }
    return false;
  }

  String _formatImpactDate(DateTime date) {
    final formatter = DateFormat('MMM dd (EEEE)');
    return formatter.format(date);
  }

  Color _eventImpactColor(EventImpact impact) {
    final percent = impact.impactPercent;
    if (percent == null) {
      return AppConstants.warningYellow;
    }
    if (percent > 0) {
      return AppConstants.successGreen;
    }
    if (percent < 0) {
      return AppConstants.errorRed;
    }
    return AppConstants.primaryOrange;
  }

  String _formatImpactPercent(double? value) {
    if (value == null) {
      return '—';
    }
    final rounded = value.abs().toStringAsFixed(0);
    if (value > 0) {
      return '+$rounded%';
    }
    if (value < 0) {
      return '-$rounded%';
    }
    return '0%';
  }

  String _buildImpactHeadline(EventImpact impact) {
    final pieces = <String>[];
    if (impact.eventName.trim().isNotEmpty) {
      pieces.add(impact.eventName.trim());
    }
    final eventType = (impact.eventType ?? '').trim();
    if (eventType.isNotEmpty) {
      pieces.add(eventType);
    }
    if (pieces.isEmpty) {
      pieces.add(impact.condition);
    }
    return pieces.join(' • ');
  }

  _HistoricalAnalyticsSnapshot _calculateHistoricalAnalytics(
    List<TransactionRecord> allTransactions,
  ) {
    final range = _resolveActiveDateRange();
    final filtered = <TransactionRecord>[];
    final previous = <TransactionRecord>[];

    for (final record in allTransactions) {
      final day = _dateOnly(record.timestamp);
      if (!day.isBefore(range.start) && !day.isAfter(range.end)) {
        filtered.add(record);
      } else if (!day.isBefore(range.previousStart) &&
          !day.isAfter(range.previousEnd)) {
        previous.add(record);
      }
    }

    final totalRevenue = filtered.fold<double>(
      0.0,
      (sum, record) => sum + record.saleAmount,
    );
    final totalOrders = filtered.length;
    final averageOrderValue = totalOrders == 0
        ? 0.0
        : totalRevenue / totalOrders;

    final previousRevenue = previous.fold<double>(
      0.0,
      (sum, record) => sum + record.saleAmount,
    );
    final previousOrders = previous.length;
    final previousAverageOrderValue = previousOrders == 0
        ? 0.0
        : previousRevenue / previousOrders;

    final revenueChangePercent = _percentChange(totalRevenue, previousRevenue);
    final orderChangePercent = _percentChange(
      totalOrders.toDouble(),
      previousOrders.toDouble(),
    );
    final aovChangePercent = _percentChange(
      averageOrderValue,
      previousAverageOrderValue,
    );

    final dailyTotals = <DateTime, double>{};
    for (final record in filtered) {
      final day = _dateOnly(record.timestamp);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + record.saleAmount;
    }

    final dailyPoints = <_DailyRevenuePoint>[];
    double maxDailyRevenue = 0;
    for (var i = 0; i < range.lengthInDays; i++) {
      final day = _dateOnly(range.start.add(Duration(days: i)));
      final revenue = dailyTotals[day] ?? 0;
      maxDailyRevenue = math.max(maxDailyRevenue, revenue);
      dailyPoints.add(_DailyRevenuePoint(date: day, revenue: revenue));
    }

    final salesTrendMaxY = maxDailyRevenue <= 0
        ? 0.0
        : _niceCeiling(maxDailyRevenue * 1.1);

    final categoryAggregates = <String, _CategoryAggregate>{};
    final itemAggregates = <String, _TopSellerAggregate>{};
    final paymentAggregates = <String, _PaymentAggregate>{};
    final channelAggregates = <String, _ChannelAccumulator>{};
    final heatmapMatrix = <int, List<double>>{};
    final hourBuckets = <int>{};
    double heatmapMaxValue = 0.0;
    double peakSlotValue = 0.0;
    int? peakSlotHour;
    int? peakSlotDay;

    for (final record in filtered) {
      final revenue = record.saleAmount;
      final dayIndex = (record.timestamp.weekday + 6) % 7;
      final hour = record.timestamp.hour;

      final row = heatmapMatrix.putIfAbsent(
        hour,
        () => List<double>.filled(7, 0.0),
      );
      row[dayIndex] += revenue;
      heatmapMaxValue = math.max(heatmapMaxValue, row[dayIndex]);
      if (row[dayIndex] > peakSlotValue) {
        peakSlotValue = row[dayIndex];
        peakSlotHour = hour;
        peakSlotDay = dayIndex;
      }
      hourBuckets.add(hour);

      final channelName = _resolveChannel(record);
      final channelAcc = channelAggregates.putIfAbsent(
        channelName,
        () => _ChannelAccumulator(),
      );
      channelAcc.revenue += revenue;
      channelAcc.orders += 1;
      final slotKey = '${dayIndex}_$hour';
      final slotValue = (channelAcc.slotTotals[slotKey] ?? 0) + revenue;
      channelAcc.slotTotals[slotKey] = slotValue;
      if (slotValue > channelAcc.bestSlotValue) {
        channelAcc.bestSlotValue = slotValue;
        channelAcc.bestHour = hour;
        channelAcc.bestDayIndex = dayIndex;
      }

      final paymentMethod = record.paymentMethod.trim().isEmpty
          ? 'Unknown'
          : record.paymentMethod.trim();
      final paymentAcc = paymentAggregates.putIfAbsent(
        paymentMethod,
        () => _PaymentAggregate(),
      );
      paymentAcc.count += 1;
      paymentAcc.amount += revenue;

      for (final item in record.items) {
        final rawCategory = (item.categoryLabel ?? item.category)?.trim();
        final categoryName = (rawCategory != null && rawCategory.isNotEmpty)
            ? rawCategory
            : 'Uncategorized';
        final categoryAcc = categoryAggregates.putIfAbsent(
          categoryName,
          () => _CategoryAggregate(),
        );
        categoryAcc.quantity += item.quantity;
        categoryAcc.revenue += item.totalPrice;

        final itemAcc = itemAggregates.putIfAbsent(
          item.name,
          () => _TopSellerAggregate(item.name),
        );
        itemAcc.quantity += item.quantity;
        itemAcc.revenue += item.totalPrice;
      }
    }

    final categoryBreakdown =
        categoryAggregates.entries
            .map(
              (entry) => _CategoryBreakdown(
                name: entry.key,
                quantity: entry.value.quantity,
                revenue: entry.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) {
            final revenueCompare = b.revenue.compareTo(a.revenue);
            return revenueCompare != 0
                ? revenueCompare
                : b.quantity.compareTo(a.quantity);
          });

    final maxCategoryQuantity = categoryBreakdown.isEmpty
        ? 0
        : categoryBreakdown.map((c) => c.quantity).reduce(math.max);

    final topSellers =
        itemAggregates.values
            .map(
              (value) => _TopSeller(
                name: value.name,
                quantity: value.quantity,
                revenue: value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) {
            final revenueCompare = b.revenue.compareTo(a.revenue);
            return revenueCompare != 0
                ? revenueCompare
                : b.quantity.compareTo(a.quantity);
          });
    if (topSellers.length > 10) {
      topSellers.removeRange(10, topSellers.length);
    }

    final paymentBreakdown =
        paymentAggregates.entries
            .map(
              (entry) => _PaymentBreakdown(
                method: entry.key,
                count: entry.value.count,
                amount: entry.value.amount,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalPaymentRevenue = paymentBreakdown.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final sortedHours = hourBuckets.toList()..sort();
    final heatmapValues = sortedHours
        .map(
          (hour) => List<double>.from(
            heatmapMatrix[hour] ?? List<double>.filled(7, 0.0),
          ),
        )
        .toList();

    final hasTransactions = filtered.isNotEmpty;
    final heatmapSummary = !hasTransactions
        ? 'No transactions yet.'
        : (peakSlotHour != null && peakSlotValue > 0)
        ? 'Busiest window: ${_dayNames[peakSlotDay ?? 0]} '
              '${_formatHourRange(peakSlotHour!)} '
              '(${Formatters.formatCurrency(peakSlotValue)})'
        : 'No significant peak detected in this range.';

    final channelBreakdown = channelAggregates.entries.map((entry) {
      final acc = entry.value;
      final share = totalRevenue <= 0
          ? 0.0
          : (acc.revenue / totalRevenue).clamp(0.0, 1.0);
      String? peakLabel;
      if (acc.bestHour != null && acc.bestSlotValue > 0) {
        final dayName = _dayNames[acc.bestDayIndex ?? 0];
        peakLabel = '$dayName ${_formatHourRange(acc.bestHour!)}';
      }
      return _ChannelBreakdown(
        name: entry.key,
        orders: acc.orders,
        revenue: acc.revenue,
        share: share,
        peakLabel: peakLabel,
      );
    }).toList()..sort((a, b) => b.revenue.compareTo(a.revenue));

    final peakHourRevenue = (peakSlotHour != null && peakSlotValue > 0)
        ? peakSlotValue
        : 0.0;
    final peakHourWindowLabel = (peakSlotHour != null && peakSlotValue > 0)
        ? '${_dayNames[peakSlotDay ?? 0]} ${_formatHourRange(peakSlotHour!)}'
        : '—';

    return _HistoricalAnalyticsSnapshot(
      filteredTransactions: filtered,
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      averageOrderValue: averageOrderValue,
      revenueChangePercent: revenueChangePercent,
      orderChangePercent: orderChangePercent,
      aovChangePercent: aovChangePercent,
      dailyRevenuePoints: dailyPoints,
      salesTrendMaxY: salesTrendMaxY,
      categoryBreakdown: categoryBreakdown,
      maxCategoryQuantity: maxCategoryQuantity,
      channelBreakdown: channelBreakdown,
      topSellers: topSellers,
      paymentBreakdown: paymentBreakdown,
      totalPaymentRevenue: totalPaymentRevenue,
      heatmapHours: sortedHours,
      heatmapValues: heatmapValues,
      heatmapMaxValue: heatmapMaxValue,
      heatmapSummary: heatmapSummary,
      peakHourRevenue: peakHourRevenue,
      peakHourWindowLabel: peakHourWindowLabel,
    );
  }

  void _applyAnalyticsSnapshot(_HistoricalAnalyticsSnapshot snapshot) {
    _filteredTransactions = snapshot.filteredTransactions;
    _totalRevenue = snapshot.totalRevenue;
    _totalOrders = snapshot.totalOrders;
    _averageOrderValue = snapshot.averageOrderValue;
    _revenueChangePercent = snapshot.revenueChangePercent;
    _orderChangePercent = snapshot.orderChangePercent;
    _aovChangePercent = snapshot.aovChangePercent;
    _dailyRevenuePoints = snapshot.dailyRevenuePoints;
    _salesTrendMaxY = snapshot.salesTrendMaxY;
    _categoryBreakdown = snapshot.categoryBreakdown;
    _maxCategoryQuantity = snapshot.maxCategoryQuantity;
    _channelBreakdown = snapshot.channelBreakdown;
    _topSellers = snapshot.topSellers;
    _paymentBreakdown = snapshot.paymentBreakdown;
    _totalPaymentRevenue = snapshot.totalPaymentRevenue;
    _heatmapHours = snapshot.heatmapHours;
    _heatmapValues = snapshot.heatmapValues;
    _heatmapMaxValue = snapshot.heatmapMaxValue;
    _heatmapSummary = snapshot.heatmapSummary;
    _peakHourRevenue = snapshot.peakHourRevenue;
    _peakHourWindowLabel = snapshot.peakHourWindowLabel;
  }

  _ResolvedDateRange _resolveActiveDateRange() {
    final today = DateTime.now();
    DateTime start = _startDate ?? today.subtract(const Duration(days: 6));
    DateTime end = _endDate ?? _startDate ?? today;

    start = _dateOnly(start);
    end = _dateOnly(end);

    if (start.isAfter(end)) {
      final temp = start;
      start = end;
      end = temp;
    }

    final lengthInDays = end.difference(start).inDays + 1;
    final previousEnd = start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(
      Duration(days: lengthInDays - 1),
    );

    return _ResolvedDateRange(
      start: start,
      end: end,
      previousStart: _dateOnly(previousStart),
      previousEnd: _dateOnly(previousEnd),
      lengthInDays: lengthInDays,
    );
  }

  double? _percentChange(double current, double previous) {
    if (current.isNaN || previous.isNaN) {
      return null;
    }
    if (current.isInfinite || previous.isInfinite) {
      return null;
    }
    if (previous.abs() < 0.0001) {
      if (current.abs() < 0.0001) {
        return 0;
      }
      return double.nan;
    }
    final delta = ((current - previous) / previous) * 100;
    if (delta.isNaN || delta.isInfinite) {
      return null;
    }
    return delta;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  double _niceCeiling(double value) {
    if (value <= 0) {
      return 0;
    }
    final log10 = math.log(value) / math.ln10;
    final magnitude = math.pow(10, log10.floor()).toDouble();
    final normalized = value / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  double _computeYAxisInterval(double maxY) {
    if (maxY <= 0) {
      return 100;
    }
    final target = maxY / 5;
    final magnitude = math
        .pow(10, (math.log(target) / math.ln10).floor())
        .toDouble();
    final normalized = target / magnitude;
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    final interval = niceNormalized * magnitude;
    return interval <= 0 ? 1 : interval;
  }

  String? _formatDelta(double? percent) {
    if (percent == null) {
      return null;
    }
    if (percent.isNaN) {
      return 'New';
    }
    if (percent.abs() < 0.05) {
      return '0%';
    }
    final precision = percent.abs() >= 10 ? 0 : 1;
    final sign = percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(precision)}%';
  }

  String _formatHourLabel(int hour) {
    final time = DateTime(0, 1, 1, hour);
    return DateFormat('h a').format(time);
  }

  String _formatHourRange(int hour) {
    final start = DateTime(0, 1, 1, hour);
    final end = start.add(const Duration(hours: 1));
    final startLabel = DateFormat('h a').format(start);
    final endLabel = DateFormat('h a').format(end);
    return '$startLabel - $endLabel';
  }

  String _normalizeChannelName(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.isEmpty) {
      return 'Dine-In';
    }
    if (lower.contains('dine') || lower.contains('table')) {
      return 'Dine-In';
    }
    if (lower.contains('take') ||
        lower.contains('to-go') ||
        lower.contains('carry')) {
      return 'Takeout';
    }
    if (lower.contains('deliver')) {
      return 'Delivery';
    }
    if (lower.contains('pickup') || lower.contains('pick-up')) {
      return 'Pickup';
    }
    if (lower.contains('online') ||
        lower.contains('web') ||
        lower.contains('app')) {
      return 'Online';
    }
    if (lower.contains('curb') || lower.contains('drive')) {
      return 'Curbside';
    }
    if (lower.contains('walk')) {
      return 'Walk-In';
    }
    if (lower.contains('kiosk')) {
      return 'Kiosk';
    }
    return value.trim();
  }

  String _resolveChannel(TransactionRecord record) {
    final metadata = record.metadata ?? {};
    final candidates = <String?>[
      metadata['channel']?.toString(),
      metadata['orderChannel']?.toString(),
      metadata['orderType']?.toString(),
      metadata['source']?.toString(),
      record.tableNumber,
    ];
    for (final candidate in candidates) {
      if (candidate == null) {
        continue;
      }
      final normalized = _normalizeChannelName(candidate);
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return 'Dine-In';
  }

  IconData _channelIcon(String channelName) {
    final lower = channelName.toLowerCase();
    if (lower.contains('dine')) {
      return Icons.restaurant_menu;
    }
    if (lower.contains('take')) {
      return Icons.shopping_bag;
    }
    if (lower.contains('deliver')) {
      return Icons.delivery_dining;
    }
    if (lower.contains('pickup')) {
      return Icons.storefront;
    }
    if (lower.contains('online') || lower.contains('app')) {
      return Icons.smartphone;
    }
    if (lower.contains('curb') || lower.contains('drive')) {
      return Icons.directions_car;
    }
    if (lower.contains('walk')) {
      return Icons.directions_walk;
    }
    if (lower.contains('kiosk')) {
      return Icons.point_of_sale;
    }
    return Icons.receipt_long;
  }

  /// Export report
  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export report feature coming soon!'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }
}

class _ResolvedDateRange {
  const _ResolvedDateRange({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
    required this.lengthInDays,
  });

  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;
  final int lengthInDays;
}

class _HistoricalAnalyticsSnapshot {
  _HistoricalAnalyticsSnapshot({
    required List<TransactionRecord> filteredTransactions,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.revenueChangePercent,
    required this.orderChangePercent,
    required this.aovChangePercent,
    required List<_DailyRevenuePoint> dailyRevenuePoints,
    required this.salesTrendMaxY,
    required List<_CategoryBreakdown> categoryBreakdown,
    required this.maxCategoryQuantity,
    required List<_ChannelBreakdown> channelBreakdown,
    required List<_TopSeller> topSellers,
    required List<_PaymentBreakdown> paymentBreakdown,
    required this.totalPaymentRevenue,
    required List<int> heatmapHours,
    required List<List<double>> heatmapValues,
    required this.heatmapMaxValue,
    required this.heatmapSummary,
    required this.peakHourRevenue,
    required this.peakHourWindowLabel,
  }) : filteredTransactions = List<TransactionRecord>.unmodifiable(
         filteredTransactions,
       ),
       dailyRevenuePoints = List<_DailyRevenuePoint>.unmodifiable(
         dailyRevenuePoints,
       ),
       categoryBreakdown = List<_CategoryBreakdown>.unmodifiable(
         categoryBreakdown,
       ),
       channelBreakdown = List<_ChannelBreakdown>.unmodifiable(
         channelBreakdown,
       ),
       topSellers = List<_TopSeller>.unmodifiable(topSellers),
       paymentBreakdown = List<_PaymentBreakdown>.unmodifiable(
         paymentBreakdown,
       ),
       heatmapHours = List<int>.unmodifiable(heatmapHours),
       heatmapValues = List<List<double>>.unmodifiable(
         heatmapValues.map((row) => List<double>.unmodifiable(row)),
       );

  final List<TransactionRecord> filteredTransactions;
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double? revenueChangePercent;
  final double? orderChangePercent;
  final double? aovChangePercent;
  final List<_DailyRevenuePoint> dailyRevenuePoints;
  final double salesTrendMaxY;
  final List<_CategoryBreakdown> categoryBreakdown;
  final int maxCategoryQuantity;
  final List<_ChannelBreakdown> channelBreakdown;
  final List<_TopSeller> topSellers;
  final List<_PaymentBreakdown> paymentBreakdown;
  final double totalPaymentRevenue;
  final List<int> heatmapHours;
  final List<List<double>> heatmapValues;
  final double heatmapMaxValue;
  final String heatmapSummary;
  final double peakHourRevenue;
  final String peakHourWindowLabel;
}

class _DailyRevenuePoint {
  const _DailyRevenuePoint({required this.date, required this.revenue});

  final DateTime date;
  final double revenue;
}

class _CategoryBreakdown {
  const _CategoryBreakdown({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final double revenue;
}

class _ChannelBreakdown {
  const _ChannelBreakdown({
    required this.name,
    required this.orders,
    required this.revenue,
    required this.share,
    this.peakLabel,
  });

  final String name;
  final int orders;
  final double revenue;
  final double share;
  final String? peakLabel;
}

class _TopSeller {
  const _TopSeller({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final double revenue;
}

class _PaymentBreakdown {
  const _PaymentBreakdown({
    required this.method,
    required this.count,
    required this.amount,
  });

  final String method;
  final int count;
  final double amount;
}

class _CategoryAggregate {
  int quantity = 0;
  double revenue = 0;
}

class _TopSellerAggregate {
  _TopSellerAggregate(this.name);

  final String name;
  int quantity = 0;
  double revenue = 0;
}

class _PaymentAggregate {
  int count = 0;
  double amount = 0;
}

class _ChannelAccumulator {
  double revenue = 0;
  int orders = 0;
  final Map<String, double> slotTotals = <String, double>{};
  double bestSlotValue = 0;
  int? bestHour;
  int? bestDayIndex;
}
