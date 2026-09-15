import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import 'create_collection_screen.dart';
import 'collection_detail_screen.dart';
import 'share_collection_modal.dart';

class CollectionsListScreen extends StatelessWidget {
  const CollectionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final collections = catalog.collections;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Drops & Catalog Collections'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Create Daily Drop'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryEmerald),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surat Wholesaler Daily Drop Cataloging',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Publish your daily new arrivals in one link instead of forwarding hundreds of loose photos on WhatsApp.',
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Collections List
              if (collections.isEmpty)
                Container(
                  padding: const EdgeInsets.all(60),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.collections_bookmark_outlined, size: 54, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No Daily Drops created yet.',
                        style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
                          );
                        },
                        child: const Text('Create Your First Daily Drop'),
                      ),
                    ],
                  ),
                )
              else
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
                        mainAxisExtent: 390,
                      ),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final collection = collections[index];
                        return _CollectionCard(
                          collection: collection,
                          businessSlug: auth.business.slug,
                          businessName: auth.business.name,
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Drop'),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
          );
        },
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Collection collection;
  final String businessSlug;
  final String businessName;

  const _CollectionCard({
    required this.collection,
    required this.businessSlug,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    final isLive = collection.isPublished;

    final dateStr = collection.collectionDate != null
        ? DateFormat('dd MMM yyyy').format(collection.collectionDate!)
        : 'Active Drop';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CollectionDetailScreen(collection: collection),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image with Badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    collection.displayCoverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.collections, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? AppTheme.primaryEmerald : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            const Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isLive ? 'LIVE' : 'DRAFT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${collection.productsCount} Designs included',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text('${collection.viewsCount}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.whatsappGreen),
                          const SizedBox(width: 4),
                          Text('${collection.inquiriesCount} Inquiries', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Share Link & QR'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ShareCollectionModal(
                                collection: collection,
                                businessSlug: businessSlug,
                                businessName: businessName,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isLive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          color: isLive ? Colors.orange : AppTheme.primaryEmerald,
                        ),
                        tooltip: isLive ? 'Unpublish' : 'Publish',
                        onPressed: () {
                          catalog.toggleCollectionPublish(collection.id);
                        },
                      ),
                    ],
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

