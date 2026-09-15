import 'product.dart';

class DashboardStats {
  final int todayViews;
  final int totalInquiries;
  final int newInquiriesCount;
  final int activeCollections;
  final int totalProducts;
  final int followUpsPendingCount;
  final double conversionRate;
  final Map<String, int> inquiryFunnel;
  final List<Product> topViewedProducts;
  final List<Product> topInquiredProducts;

  DashboardStats({
    this.todayViews = 0,
    this.totalInquiries = 0,
    this.newInquiriesCount = 0,
    this.activeCollections = 0,
    this.totalProducts = 0,
    this.followUpsPendingCount = 0,
    this.conversionRate = 0.0,
    this.inquiryFunnel = const {},
    this.topViewedProducts = const [],
    this.topInquiredProducts = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    var topViews = <Product>[];
    if (json['top_viewed_products'] != null &&
        json['top_viewed_products'] is List) {
      topViews = (json['top_viewed_products'] as List)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    var topInqs = <Product>[];
    if (json['top_inquired_products'] != null &&
        json['top_inquired_products'] is List) {
      topInqs = (json['top_inquired_products'] as List)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    var funnel = <String, int>{};
    if (json['inquiry_funnel'] != null && json['inquiry_funnel'] is Map) {
      json['inquiry_funnel'].forEach((k, v) {
        funnel[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    return DashboardStats(
      todayViews: json['today_views'] != null
          ? int.tryParse(json['today_views'].toString()) ?? 0
          : 0,
      totalInquiries: json['total_inquiries'] != null
          ? int.tryParse(json['total_inquiries'].toString()) ?? 0
          : 0,
      newInquiriesCount: json['new_inquiries_count'] != null
          ? int.tryParse(json['new_inquiries_count'].toString()) ?? 0
          : 0,
      activeCollections: json['active_collections'] != null
          ? int.tryParse(json['active_collections'].toString()) ?? 0
          : 0,
      totalProducts: json['total_products'] != null
          ? int.tryParse(json['total_products'].toString()) ?? 0
          : 0,
      followUpsPendingCount: json['follow_ups_pending_count'] != null
          ? int.tryParse(json['follow_ups_pending_count'].toString()) ?? 0
          : 0,
      conversionRate: json['conversion_rate'] != null
          ? double.tryParse(json['conversion_rate'].toString()) ?? 0.0
          : 0.0,
      inquiryFunnel: funnel,
      topViewedProducts: topViews,
      topInquiredProducts: topInqs,
    );
  }
}

