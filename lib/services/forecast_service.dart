import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sales_data_model.dart';

/// AI Forecasting Service
/// Handles communication with REST API for sales predictions and AI insights
class ForecastService {
  // TODO: Replace with your actual API endpoint
  static const String baseUrl = 'https://your-api-endpoint.com/api';

  /// Get sales forecast for next period
  /// Returns predicted sales data based on historical patterns
  Future<List<SalesForecast>> getSalesForecast({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forecast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SalesForecast.fromJson(item)).toList();
      } else {
        print('Error fetching forecast: ${response.statusCode}');
        return _getMockForecast(startDate, endDate);
      }
    } catch (e) {
      print('Error in forecast service: $e');
      // Return mock data for development
      return _getMockForecast(startDate, endDate);
    }
  }

  /// Get AI-driven insights based on sales patterns
  Future<List<String>> getSalesInsights() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/insights'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['insights']);
      } else {
        print('Error fetching insights: ${response.statusCode}');
        return _getMockInsights();
      }
    } catch (e) {
      print('Error in insights service: $e');
      return _getMockInsights();
    }
  }

  /// Analyze performance and get recommendations
  Future<Map<String, dynamic>> getPerformanceAnalysis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/performance'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error fetching performance analysis: ${response.statusCode}');
        return _getMockPerformanceAnalysis();
      }
    } catch (e) {
      print('Error in performance analysis: $e');
      return _getMockPerformanceAnalysis();
    }
  }

  /// Send historical data for model training
  Future<void> uploadHistoricalData(List<SalesData> salesData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': salesData.map((data) => data.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        print('Error uploading data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading historical data: $e');
    }
  }

  // ========== MOCK DATA FOR DEVELOPMENT ==========

  /// Mock forecast data for development/testing
  List<SalesForecast> _getMockForecast(DateTime startDate, DateTime endDate) {
    return List.generate(7, (index) {
      final date = startDate.add(Duration(days: index));
      return SalesForecast(
        date: date,
        predictedRevenue: 1500.0 + (index * 200),
        confidence: 0.85 - (index * 0.02),
        insights: [
          'Peak hours: 12 PM - 2 PM, 6 PM - 8 PM',
          'Expected ${15 + index} orders',
        ],
      );
    });
  }

  /// Mock insights for development/testing
  List<String> _getMockInsights() {
    return [
      '📈 Sales increased by 15% compared to last week',
      '🍕 Pizza is your top-selling item this month',
      '⏰ Peak hours are between 12 PM - 2 PM and 6 PM - 8 PM',
      '👥 Table 5 generates the highest revenue',
      '💡 Consider promoting beverages - lower sales than average',
    ];
  }

  /// Mock performance analysis for development/testing
  Map<String, dynamic> _getMockPerformanceAnalysis() {
    return {
      'overallScore': 8.5,
      'revenueGrowth': 12.5,
      'customerSatisfaction': 4.3,
      'recommendations': [
        'Optimize menu items based on popularity',
        'Consider extending peak hour staffing',
        'Introduce combo meals during off-peak hours',
      ],
    };
  }
}
