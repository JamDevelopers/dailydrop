import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/product.dart';
import '../../models/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/whatsapp_link_service.dart';
import 'ask_whatsapp_modal.dart';

class PublicCatalogScreen extends StatefulWidget {
  final String? businessSlug;
  final String? collectionSlug;

  const PublicCatalogScreen({
    super.key,
    this.businessSlug,
    this.collectionSlug,
  });

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  String _searchQuery = '';
  String? _selectedFabric;
  String? _selectedFestival;
  String? _selectedOccasion;
  bool _filterTodayOnly = false;
  int? _selectedCollectionId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();
    final business = auth.business;

    // Public collections (or direct token collection)
    final allCollections = catalog.collections.where((c) {
      if (widget.collectionSlug != null && c.slug == widget.collectionSlug) {
        return true; // Accessed directly via link
      }
      return c.visibility == 'public' && c.showInMainCatalog;
    }).toList();

    // Today's live drops
    final todayDrops = allCollections
        .where((c) => c.isToday && !c.isExpired)
        .toList();

    // Active collection
    final activeCollection = allCollections.firstWhere(
      (c) => _selectedCollectionId != null
          ? c.id == _selectedCollectionId
          : (widget.collectionSlug != null
                ? c.slug == widget.collectionSlug
                : true),
      orElse: () => allCollections.isNotEmpty
          ? allCollections.first
          : Collection(
              id: 0,
              businessId: business.id,
              createdByUserId: 1,
              name: "Today's Daily Drop",
              slug: 'today',
              shareToken: 'today',
            ),
    );

    // Products pool
    List<Product> sourceProducts;
    if (_filterTodayOnly) {
      final todayIds = todayDrops.expand((d) => d.productIds).toSet();
      if (todayIds.isNotEmpty) {
        sourceProducts = catalog.allProducts
            .where((p) => p.isPublic && todayIds.contains(p.id))
            .toList();
      } else {
        sourceProducts = todayDrops
            .expand((d) => d.products)
            .where((p) => p.isPublic)
            .toList();
      }
      // Fallback if no specific drops exist yet
      if (sourceProducts.isEmpty) {
        sourceProducts = catalog.allProducts.where((p) => p.isPublic).toList();
      }
    } else if (_selectedCollectionId != null) {
      sourceProducts =
          (activeCollection.products.isNotEmpty
                  ? activeCollection.products
                  : catalog.allProducts.where(
                      (p) => activeCollection.productIds.contains(p.id),
                    ))
              .where((p) => p.isPublic)
              .toList();
    } else {
      sourceProducts =
          (activeCollection.products.isNotEmpty
                  ? activeCollection.products
                  : catalog.allProducts)
              .where((p) => p.isPublic)
              .toList();
    }

    // Filter products
    final displayProducts = sourceProducts.where((p) {
      if (_selectedFabric != null && _selectedFabric!.isNotEmpty) {
        if (p.fabric != _selectedFabric) return false;
      }
      if (_selectedFestival != null && _selectedFestival!.isNotEmpty) {
        if (p.festival != _selectedFestival) return false;
      }
      if (_selectedOccasion != null && _selectedOccasion!.isNotEmpty) {
        if (p.occasion != _selectedOccasion) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = p.productCode.toLowerCase().contains(q);
        final matchTitle = (p.title ?? '').toLowerCase().contains(q);
        final matchFabric = (p.fabric ?? '').toLowerCase().contains(q);
        final matchFestival = (p.festival ?? '').toLowerCase().contains(q);
        final matchOccasion = (p.occasion ?? '').toLowerCase().contains(q);
        if (!matchCode &&
            !matchTitle &&
            !matchFabric &&
            !matchFestival &&
            !matchOccasion) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // Store Header Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: MaxWidthContainer(
                maxWidth: 1100,
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.layers_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  business.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: AppTheme.primaryEmerald,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${business.city}, ${business.state} • Wholesale & Manufacturing Direct',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chat with seller button
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.chat,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text('Chat with Seller'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.whatsappGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                      onPressed: () {
                        WhatsAppLinkService.openDirectChat(
                          buyerPhone: business.whatsappNumber,
                          initialText:
                              'Hello ${business.name}, I am browsing your wholesale catalog.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expiry Alert Banner (if collection is expired)
          if (activeCollection.isExpired)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: MaxWidthContainer(
                  maxWidth: 1100,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_toggle_off,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '⏰ This daily drop collection has ended. Displaying latest available catalogue items below.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (todayDrops.isNotEmpty)
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade700,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedCollectionId = todayDrops.first.id;
                            });
                          },
                          child: const Text(
                            "View Today's Drop",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // CAROUSEL FOR TODAY'S DAILY DROP (BEFORE SEARCH BAR)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: MaxWidthContainer(
                maxWidth: 1100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TodayDailyDropHeroCarousel(
                    todayDrops: todayDrops.isNotEmpty
                        ? todayDrops
                        : allCollections.take(3).toList(),
                    activeCollectionId: activeCollection.id,
                    onSelectDrop: (coll) {
                      setState(() {
                        _selectedCollectionId = coll.id;
                        _filterTodayOnly = false;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // Filters & Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: MaxWidthContainer(
                maxWidth: 1100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search by Design Code
                      TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by Design Code (e.g. SR-260915-013, 013, Dola Silk)...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryEmerald,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.borderColor,
                            ),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 12),

                      // Quick Filter Chips (Today's Drop, Fabrics, Festivals, Occasions)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Today's Drop Toggle Pill
                            FilterChip(
                              avatar: const Text(
                                '🔥',
                                style: TextStyle(fontSize: 13),
                              ),
                              label: const Text("Today's Drop"),
                              selected: _filterTodayOnly,
                              selectedColor: AppTheme.primaryEmerald
                                  .withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryEmerald,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _filterTodayOnly
                                    ? AppTheme.primaryEmerald
                                    : AppTheme.textPrimary,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _filterTodayOnly = selected;
                                  if (selected) {
                                    _selectedCollectionId = null;
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),

                            // All Fabrics / Fabric Filter
                            ChoiceChip(
                              label: const Text('All Fabrics'),
                              selected: _selectedFabric == null,
                              onSelected: (_) =>
                                  setState(() => _selectedFabric = null),
                            ),
                            const SizedBox(width: 8),
                            ...[
                              'Dola Silk',
                              'Georgette',
                              'Rayon 14kg',
                              'Cotton',
                              'Velvet',
                              'Organza',
                              'Banarasi Jacquard',
                            ].map((f) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: _selectedFabric == f,
                                  onSelected: (selected) {
                                    setState(
                                      () =>
                                          _selectedFabric = selected ? f : null,
                                    );
                                  },
                                ),
                              );
                            }),

                            // Festival Separator & Chips
                            Container(
                              width: 1,
                              height: 24,
                              color: AppTheme.borderColor,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            const SizedBox(width: 8),
                            ...[
                              'Diwali Special',
                              'Navratri & Garba',
                              'Wedding Season',
                              'Party Wear',
                            ].map((tag) {
                              final isFestival = AppConstants.festivals
                                  .contains(tag);
                              final isSelected = isFestival
                                  ? _selectedFestival == tag
                                  : _selectedOccasion == tag;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text('✨ $tag'),
                                  selected: isSelected,
                                  selectedColor: AppTheme.accentGold
                                      .withOpacity(0.25),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (isFestival) {
                                        _selectedFestival = selected
                                            ? tag
                                            : null;
                                      } else {
                                        _selectedOccasion = selected
                                            ? tag
                                            : null;
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Products Grid with Multi-Image Carousel Cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: MaxWidthContainer(
                maxWidth: 1100,
                child: displayProducts.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: AppTheme.textMuted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No designs found matching your filter criteria.',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth > 900
                              ? 3
                              : (constraints.maxWidth > 600 ? 2 : 1);

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 470,
                                ),
                            itemCount: displayProducts.length,
                            itemBuilder: (context, index) {
                              final product = displayProducts[index];
                              return _PublicProductCard(
                                product: product,
                                collection: activeCollection,
                                business: business,
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    '${business.name} • Surat, Gujarat',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Powered by TextileDrop SaaS • Direct WhatsApp Daily Drop Catalog Engine',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
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
}

/// HERO CAROUSEL FOR TODAY'S DAILY DROP (BEFORE SEARCH BAR)
class _TodayDailyDropHeroCarousel extends StatefulWidget {
  final List<Collection> todayDrops;
  final int activeCollectionId;
  final ValueChanged<Collection> onSelectDrop;

  const _TodayDailyDropHeroCarousel({
    required this.todayDrops,
    required this.activeCollectionId,
    required this.onSelectDrop,
  });

  @override
  State<_TodayDailyDropHeroCarousel> createState() =>
      _TodayDailyDropHeroCarouselState();
}

class _TodayDailyDropHeroCarouselState
    extends State<_TodayDailyDropHeroCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todayDrops.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.todayDrops.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              final drop = widget.todayDrops[index];
              final isSelected = drop.id == widget.activeCollectionId;

              return InkWell(
                onTap: () => widget.onSelectDrop(drop),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [
                              AppTheme.primaryEmerald.withOpacity(0.12),
                              AppTheme.accentGold.withOpacity(0.08),
                            ]
                          : [Colors.white, Colors.grey.shade50],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryEmerald
                          : AppTheme.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Drop Thumbnail Collage / Cover
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              drop.displayCoverUrl,
                              width: 110,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${drop.productsCount} Designs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Information & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '🔥 LIVE DAILY DROP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (drop.expiresAt != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '⏳ ${drop.remainingTimeFormatted}',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              drop.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (drop.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                drop.description!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  isSelected
                                      ? '✓ Viewing This Drop'
                                      : 'Tap to View Designs →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? AppTheme.primaryEmerald
                                        : AppTheme.textSecondary,
                                  ),
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
            },
          ),
        ),

        // Carousel Page Indicators (if multiple drops)
        if (widget.todayDrops.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.todayDrops.asMap().entries.map((entry) {
              final idx = entry.key;
              final isCurrent = idx == _currentPage;
              return Container(
                width: isCurrent ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isCurrent
                      ? AppTheme.primaryEmerald
                      : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// PRODUCT CARD WITH MULTI-IMAGE CAROUSEL (SET OF 4 COLORS / ANGLES)
class _PublicProductCard extends StatefulWidget {
  final Product product;
  final Collection collection;
  final dynamic business;

  const _PublicProductCard({
    required this.product,
    required this.collection,
    required this.business,
  });

  @override
  State<_PublicProductCard> createState() => _PublicProductCardState();
}

class _PublicProductCardState extends State<_PublicProductCard> {
  late final PageController _imagePageController;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.allImageUrls;
    final hasMultipleImages = images.length > 1;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Swipeable Image Carousel with Indicators
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!hasMultipleImages)
                  Image.network(
                    product.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: images.length,
                    onPageChanged: (idx) =>
                        setState(() => _activeImageIndex = idx),
                    itemBuilder: (context, idx) {
                      return Image.network(
                        images[idx],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),

                // Design Code Top-Left Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DESIGN ${product.productCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Fabric Pill Top-Right
                if (product.fabric != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.fabric!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),

                // Set of 4 / Multi-Image Carousel Indicator Bar
                if (hasMultipleImages) ...[
                  // Carousel dots
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final isSelected = idx == _activeImageIndex;
                        return Container(
                          width: isSelected ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 2),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Quick previous/next touch overlay buttons
                  Positioned(
                    left: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: _activeImageIndex > 0
                            ? () {
                                _imagePageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onPressed: _activeImageIndex < images.length - 1
                            ? () {
                                _imagePageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.displayTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price & Set of 4 Label
                Row(
                  children: [
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const Spacer(),
                    if (product.festival != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.festival!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Color Swatches / Set Variants
                if (product.colorVariants.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: product.colorVariants.take(4).map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else if (product.color != null)
                  Text(
                    'Color: ${product.color}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                const SizedBox(height: 10),

                // Flagship "Ask on WhatsApp" Button
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.chat_bubble_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                  label: const Text('Ask on WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsappGreen,
                    minimumSize: const Size.fromHeight(38),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AskWhatsAppModal(
                        product: product,
                        collection: widget.collection,
                        sellerWhatsApp: widget.business.whatsappNumber,
                        businessName: widget.business.name,
                        businessId: widget.business.id,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
