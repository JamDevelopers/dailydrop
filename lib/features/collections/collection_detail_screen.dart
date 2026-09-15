import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../products/product_detail_screen.dart';
import '../public_catalog/public_catalog_screen.dart';
import 'share_collection_modal.dart';

class CollectionDetailScreen extends StatelessWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();

    // Fetch latest instance
    final currentCollection = catalog.collections.firstWhere(
      (c) => c.id == collection.id,
      orElse: () => collection,
    );

    final includedProducts = currentCollection.products.isNotEmpty
        ? currentCollection.products
        : catalog.allProducts.where((p) => currentCollection.productIds.contains(p.id)).toList();

    final dateStr = currentCollection.collectionDate != null
        ? DateFormat('dd MMM yyyy').format(currentCollection.collectionDate!)
        : 'Active';

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCollection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppTheme.primaryEmerald),
            tooltip: 'Share Collection',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ShareCollectionModal(
                  collection: currentCollection,
                  businessSlug: auth.business.slug,
                  businessName: auth.business.name,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Preview Public Buyer View',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicCatalogScreen(
                    businessSlug: auth.business.slug,
                    collectionSlug: currentCollection.slug,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Collection',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Collection?'),
                  content: Text('Are you sure you want to delete "${currentCollection.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        catalog.deleteCollection(currentCollection.id);
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 1100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentCollection.isPublished
                                  ? AppTheme.primaryEmerald
                                  : Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentCollection.isPublished ? 'LIVE ON WHATSAPP LINK' : 'DRAFT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Date: $dateStr',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            '${includedProducts.length} Designs',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentCollection.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      if (currentCollection.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          currentCollection.description!,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                      const Divider(height: 28),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.visibility_outlined,
                            label: 'Views',
                            value: '${currentCollection.viewsCount}',
                          ),
                          _StatItem(
                            icon: Icons.chat_bubble_outline,
                            label: 'Inquiries',
                            value: '${currentCollection.inquiriesCount}',
                          ),
                          _StatItem(
                            icon: Icons.qr_code,
                            label: 'Share Token',
                            value: currentCollection.shareToken,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Included Products Title
              Row(
                children: [
                  const Text(
                    'Designs in this Daily Drop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share Broadcast'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ShareCollectionModal(
                          collection: currentCollection,
                          businessSlug: auth.business.slug,
                          businessName: auth.business.name,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Products Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 3
                      : (constraints.maxWidth > 600 ? 2 : 1);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 320,
                    ),
                    itemCount: includedProducts.length,
                    itemBuilder: (context, index) {
                      final p = includedProducts[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: p),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      p.primaryImageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          p.productCode,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.displayTitle,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${p.fabric ?? "Fabric"} • ${p.formattedPrice}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryEmerald, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryEmerald, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

