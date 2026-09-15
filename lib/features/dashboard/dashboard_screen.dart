import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/dashboard_stats.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/inquiry_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../products/bulk_upload_screen.dart';
import '../collections/create_collection_screen.dart';
import '../public_catalog/public_catalog_screen.dart';
import '../inquiries/inquiry_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final inqProvider = context.watch<InquiryProvider>();
    final dashboard = context.watch<DashboardProvider>();

    final stats = dashboard.getStats(catalog, inqProvider);
    final business = auth.business;
    final pendingFollowUps = inqProvider.pendingFollowUpsToday;

    return Scaffold(
      appBar: AppBar(
        title: Text(business.name),
        actions: [
          // Public Catalog Link Button
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Public Catalog'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicCatalogScreen(
                    businessSlug: business.slug,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
            label: const Text('Bulk Daily Drop'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 1200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Follow-Up Alert Banner
              if (pendingFollowUps.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGoldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: AppTheme.accentGold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔔 Action Required: ${pendingFollowUps.length} Buyer Follow-Up(s) Scheduled for Today!',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.brown),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Reach out to buyers on WhatsApp to confirm wholesale orders before new catalog drop.',
                              style: TextStyle(fontSize: 12, color: Colors.brown),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // KPI Stats Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : (constraints.maxWidth > 550 ? 2 : 1);

                  final kpiList = [
                    _KpiCard(
                      title: 'Catalog Views',
                      value: '${stats.todayViews}',
                      subtitle: 'Across public drops',
                      icon: Icons.visibility_rounded,
                      color: AppTheme.primaryEmerald,
                    ),
                    _KpiCard(
                      title: 'Total Inquiries',
                      value: '${stats.totalInquiries}',
                      subtitle: '${stats.newInquiriesCount} new / pending',
                      icon: Icons.chat_bubble_rounded,
                      color: AppTheme.whatsappGreen,
                    ),
                    _KpiCard(
                      title: 'Active Daily Drops',
                      value: '${stats.activeCollections}',
                      subtitle: 'Published catalogs',
                      icon: Icons.collections_bookmark_rounded,
                      color: Colors.purple,
                    ),
                    _KpiCard(
                      title: 'Designs in Stock',
                      value: '${stats.totalProducts}',
                      subtitle: '${stats.conversionRate.toStringAsFixed(1)}% Conversion Rate',
                      icon: Icons.inventory_2_rounded,
                      color: AppTheme.accentGold,
                    ),
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 130,
                    ),
                    itemCount: kpiList.length,
                    itemBuilder: (_, idx) => kpiList[idx],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Middle Section: Funnel Breakdown + Quick Actions
              Responsive(
                mobile: Column(
                  children: [
                    _buildFunnelCard(stats),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(context),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildFunnelCard(stats)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildQuickActionsCard(context)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Products & Inquiries Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Viewed & Inquired Design Codes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.topViewedProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = stats.topViewedProducts[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                p.primaryImageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              '${p.productCode} • ${p.displayTitle}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${p.fabric ?? "Fabric"} • ${p.formattedPrice}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p.viewsCount} Views',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                                Text(
                                  '${p.inquiriesCount} Inquiries',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.whatsappGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunnelCard(DashboardStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Pipeline & Conversion Funnel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...stats.inquiryFunnel.entries.map((entry) {
              final pct = stats.totalInquiries > 0
                  ? (entry.value / stats.totalInquiries)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${entry.value} Inquiries', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: AppTheme.backgroundLight,
                        color: entry.key == 'Ordered'
                            ? Colors.green
                            : (entry.key == 'Quoted'
                                ? Colors.amber.shade700
                                : AppTheme.primaryEmerald),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Workflows',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, size: 18),
              label: const Text('Bulk Upload Photos & Auto Design Codes'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create New Daily Drop'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Share Catalog Link / QR Code'),
              onPressed: () {
                final auth = context.read<AuthProvider>();
                final catalog = context.read<CatalogProvider>();
                if (catalog.collections.isNotEmpty) {
                  final coll = catalog.collections.first;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicCatalogScreen(
                        businessSlug: auth.business.slug,
                        collectionSlug: coll.slug,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
