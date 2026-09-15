import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dashboard_stats.dart';
import 'catalog_provider.dart';
import 'inquiry_provider.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardStats getStats(CatalogProvider catalog, InquiryProvider inquiry) {
    final products = catalog.allProducts;
    final inquiries = inquiry.allInquiries;
    final collections = catalog.collections;

    int totalViews = 0;
    for (final p in products) {
      totalViews += p.viewsCount;
    }
    for (final c in collections) {
      totalViews += c.viewsCount;
    }

    final newInqs = inquiries.where((i) => i.status == 'new').length;
    final orderedInqs = inquiries.where((i) => i.status == 'ordered').length;
    final pendingFollowUps = inquiry.pendingFollowUpsToday.length;
    final activeColls = collections.where((c) => c.visibility == 'public').length;

    final double convRate = inquiries.isNotEmpty
        ? (orderedInqs / inquiries.length) * 100
        : 0.0;

    final funnel = <String, int>{
      'New': inquiries.where((i) => i.status == 'new').length,
      'Contacted': inquiries.where((i) => i.status == 'contacted' || i.status == 'catalog_sent').length,
      'Quoted': inquiries.where((i) => i.status == 'quoted').length,
      'Follow-Up': inquiries.where((i) => i.status == 'follow_up').length,
      'Ordered': orderedInqs,
    };

    final sortedViews = List.from(products)
      ..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final sortedInqs = List.from(products)
      ..sort((a, b) => b.inquiriesCount.compareTo(a.inquiriesCount));

    return DashboardStats(
      todayViews: totalViews,
      totalInquiries: inquiries.length,
      newInquiriesCount: newInqs,
      activeCollections: activeColls,
      totalProducts: products.length,
      followUpsPendingCount: pendingFollowUps,
      conversionRate: convRate,
      inquiryFunnel: funnel,
      topViewedProducts: sortedViews.take(5).cast<Product>().toList(),
      topInquiredProducts: sortedInqs.take(5).cast<Product>().toList(),
    );
  }
}
