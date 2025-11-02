/// Sales data model for analytics and forecasting
class SalesData {
  final DateTime date;
  final double revenue;
  final int orderCount;
  final double averageOrderValue;

  SalesData({
    required this.date,
    required this.revenue,
    required this.orderCount,
    required this.averageOrderValue,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'revenue': revenue,
      'orderCount': orderCount,
      'averageOrderValue': averageOrderValue,
    };
  }

  /// Create from JSON
  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      date: DateTime.parse(json['date']),
      revenue: json['revenue'].toDouble(),
      orderCount: json['orderCount'],
      averageOrderValue: json['averageOrderValue'].toDouble(),
    );
  }
}

/// AI Forecast model for predicted sales
class SalesForecast {
  final DateTime date;
  final double predictedRevenue;
  final double confidence;
  final List<String> insights;

  SalesForecast({
    required this.date,
    required this.predictedRevenue,
    required this.confidence,
    required this.insights,
  });

  /// Create from JSON (REST API response)
  factory SalesForecast.fromJson(Map<String, dynamic> json) {
    return SalesForecast(
      date: DateTime.parse(json['date']),
      predictedRevenue: json['predictedRevenue'].toDouble(),
      confidence: json['confidence'].toDouble(),
      insights: List<String>.from(json['insights'] ?? []),
    );
  }
}
