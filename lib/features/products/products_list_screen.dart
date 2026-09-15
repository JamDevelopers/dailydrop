import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import 'add_edit_product_screen.dart';
import 'bulk_upload_screen.dart';
import 'excel_import_modal.dart';
import 'create_custom_catalog_modal.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final Set<int> _selectedProductIds = {};

  void _toggleSelectProduct(int id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<Product> products) {
    setState(() {
      if (_selectedProductIds.length == products.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.clear();
        _selectedProductIds.addAll(products.map((p) => p.id));
      }
    });
  }

  void _openCreateCustomCatalog(List<Product> allProducts) {
    final selected = allProducts
        .where((p) => _selectedProductIds.contains(p.id))
        .toList();
    if (selected.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCustomCatalogModal(selectedProducts: selected),
    );
  }

  void _openExcelImport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExcelImportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.filteredProducts;
    final allSelected =
        products.isNotEmpty && _selectedProductIds.length == products.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory & Design Codes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              catalog.clearFilters();
              setState(() => _selectedProductIds.clear());
            },
            tooltip: 'Reset Filters',
          ),
          OutlinedButton.icon(
            icon: const Icon(
              Icons.table_view_outlined,
              size: 16,
              color: AppTheme.primaryEmerald,
            ),
            label: const Text(
              'Excel / CSV Import',
              style: TextStyle(
                color: AppTheme.primaryEmerald,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryEmerald),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: _openExcelImport,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
            label: const Text('Bulk Drop Upload'),
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MaxWidthContainer(
                    maxWidth: 1200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      'Search by Design Code (e.g. SR-260915-001) or Fabric...',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppTheme.primaryEmerald,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: catalog.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () =>
                                              catalog.setSearchQuery(''),
                                        )
                                      : null,
                                ),
                                onChanged: (val) => catalog.setSearchQuery(val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // 🔥 Today's Drop Filter Chip
                              FilterChip(
                                avatar: const Text(
                                  '🔥',
                                  style: TextStyle(fontSize: 13),
                                ),
                                label: const Text("Today's Drop"),
                                selected: catalog.isTodayDropOnly,
                                selectedColor: AppTheme.primaryEmerald
                                    .withOpacity(0.2),
                                checkmarkColor: AppTheme.primaryEmerald,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: catalog.isTodayDropOnly
                                      ? AppTheme.primaryEmerald
                                      : AppTheme.textPrimary,
                                ),
                                onSelected: (selected) {
                                  catalog.setTodayDropFilter(selected);
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('All Products'),
                                selected:
                                    !catalog.isTodayDropOnly &&
                                    catalog.selectedFabric == null &&
                                    catalog.selectedStockStatus == null,
                                onSelected: (_) => catalog.clearFilters(),
                              ),
                              const SizedBox(width: 8),
                              ...['available', 'limited', 'sold_out'].map((
                                status,
                              ) {
                                final label = status == 'available'
                                    ? 'Available'
                                    : (status == 'limited'
                                          ? 'Limited'
                                          : 'Sold Out');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(label),
                                    selected:
                                        catalog.selectedStockStatus == status,
                                    onSelected: (selected) {
                                      catalog.setStockStatusFilter(
                                        selected ? status : null,
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(width: 8),
                              ...AppConstants.fabrics.take(6).map((f) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(f),
                                    selected: catalog.selectedFabric == f,
                                    onSelected: (selected) {
                                      catalog.setFabricFilter(
                                        selected ? f : null,
                                      );
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Quick Multi-Select Helper Row
                        if (products.isNotEmpty)
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _toggleSelectAll(products),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        allSelected
                                            ? Icons.check_box
                                            : (_selectedProductIds.isNotEmpty
                                                  ? Icons
                                                        .indeterminate_check_box
                                                  : Icons
                                                        .check_box_outline_blank),
                                        size: 18,
                                        color: _selectedProductIds.isNotEmpty
                                            ? AppTheme.primaryEmerald
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        allSelected
                                            ? 'Deselect All (${products.length})'
                                            : (_selectedProductIds.isNotEmpty
                                                  ? 'Select All (${_selectedProductIds.length}/${products.length})'
                                                  : 'Select All Designs'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedProductIds.isNotEmpty
                                              ? AppTheme.primaryEmerald
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${products.length} Products listed',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Product List/Grid
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  _selectedProductIds.isNotEmpty ? 90 : 80,
                ),
                sliver: SliverToBoxAdapter(
                  child: MaxWidthContainer(
                    maxWidth: 1200,
                    child: products.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(60),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 54,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No products found matching your filters.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: const Text('Add Single Product'),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AddEditProductScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.table_view_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Import Demo Excel/CSV',
                                      ),
                                      onPressed: _openExcelImport,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth > 950
                                  ? 4
                                  : (constraints.maxWidth > 650 ? 2 : 1);

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 410,
                                    ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  final isSelected = _selectedProductIds
                                      .contains(product.id);
                                  return _ProductInventoryCard(
                                    product: product,
                                    isSelected: isSelected,
                                    onToggleSelect: () =>
                                        _toggleSelectProduct(product.id),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Bulk Action Bar (when products are selected)
          if (_selectedProductIds.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: MaxWidthContainer(
                  maxWidth: 900,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_selectedProductIds.length} Selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Select designs to bundle into a time-limited VIP catalog',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppTheme.primaryDark,
                          ),
                          label: const Text('Create Custom Catalog (Expiry)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () =>
                              _openCreateCustomCatalog(catalog.allProducts),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Clear Selection',
                          onPressed: () =>
                              setState(() => _selectedProductIds.clear()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedProductIds.isEmpty
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditProductScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class _ProductInventoryCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  const _ProductInventoryCard({
    required this.product,
    required this.isSelected,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();

    Color stockColor = Colors.green;
    String stockLabel = 'In Stock';
    if (product.stockStatus == 'limited') {
      stockColor = Colors.orange;
      stockLabel = 'Limited Stock';
    } else if (product.stockStatus == 'sold_out') {
      stockColor = Colors.red;
      stockLabel = 'Sold Out';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryEmerald : AppTheme.borderColor,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with Design Code overlay & Selection Checkbox
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  // Checkbox overlay for bulk selection
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: onToggleSelect,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryEmerald
                              : Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryEmerald
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.crop_square,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Design Code Overlay
                  Positioned(
                    top: 8,
                    left: 8,
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
                        product.productCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  // Set of 4 or Multi-image badge
                  if (product.setCount > 1 || product.imageUrls.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade800.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          product.setLabel ?? 'Set of ${product.setCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  // Stock Label Overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stockLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // Expiry Badge if item has an expiry time
                  if (product.expiresAt != null)
                    Positioned(
                      top: 38,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.isExpired
                              ? Colors.red.shade700
                              : Colors.amber.shade900,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.isExpired
                                  ? 'Expired'
                                  : product.remainingTimeFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 2),
                  Text(
                    '${product.fabric ?? "Fabric"} • ${product.color ?? "Assorted"}${product.festival != null ? " • ${product.festival}" : ""}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.viewsCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: AppTheme.whatsappGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.inquiriesCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick Stock Toggle Dropdown
                  PopupMenuButton<String>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change Stock Status',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    onSelected: (status) {
                      catalog.updateProductStock(product.id, status);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'available',
                        child: Text('Mark Available'),
                      ),
                      PopupMenuItem(
                        value: 'limited',
                        child: Text('Mark Limited Stock'),
                      ),
                      PopupMenuItem(
                        value: 'sold_out',
                        child: Text('Mark Sold Out'),
                      ),
                      PopupMenuItem(
                        value: 'discontinued',
                        child: Text('Mark Discontinued'),
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
