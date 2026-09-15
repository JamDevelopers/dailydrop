import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import 'add_edit_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final catalog = context.watch<CatalogProvider>();

    // Fetch latest instance
    final currentProduct = catalog.allProducts.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );

    final isOwner = auth.currentUser?.isOwner ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('Design ${currentProduct.productCode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Product',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditProductScreen(product: currentProduct),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Product',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Product?'),
                  content: Text('Are you sure you want to delete Design ${currentProduct.productCode}?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        catalog.deleteProduct(currentProduct.id);
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
          maxWidth: 1000,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo and Core Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Responsive(
                    mobile: _buildDetailsColumn(context, currentProduct, isOwner),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            currentProduct.primaryImageUrl,
                            width: 320,
                            height: 380,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(child: _buildDetailsColumn(context, currentProduct, isOwner)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Analytics Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Catalog Views',
                        value: '${currentProduct.viewsCount}',
                        icon: Icons.visibility,
                        color: AppTheme.primaryEmerald,
                      ),
                      _StatColumn(
                        label: 'WhatsApp Inquiries',
                        value: '${currentProduct.inquiriesCount}',
                        icon: Icons.chat_bubble,
                        color: AppTheme.whatsappGreen,
                      ),
                      _StatColumn(
                        label: 'Stock Quantity',
                        value: currentProduct.stockQuantity != null ? '${currentProduct.stockQuantity} Pcs' : 'Unspecified',
                        icon: Icons.inventory_2,
                        color: AppTheme.accentGold,
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

  Widget _buildDetailsColumn(BuildContext context, Product p, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryEmerald.withOpacity(0.3)),
              ),
              child: Text(
                p.productCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.stockStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.displayTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.formattedPrice,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryEmerald,
          ),
        ),
        if (isOwner && p.costPrice != null) ...[
          const SizedBox(height: 4),
          Text(
            'Cost Price: ₹${p.costPrice!.toStringAsFixed(0)} (Profit Margin: ₹${(p.price != null ? p.price! - p.costPrice! : 0).toStringAsFixed(0)})',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
        const Divider(height: 28),
        _SpecRow(label: 'Fabric', value: p.fabric ?? 'Unspecified'),
        _SpecRow(label: 'Color', value: p.color ?? 'Assorted'),
        _SpecRow(label: 'Category', value: p.categoryName ?? 'Saree Collection'),
        _SpecRow(label: 'Brand / Label', value: p.brand ?? 'Surat Mill Direct'),
        if (p.shortDescription != null && p.shortDescription!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(p.shortDescription!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
        if (isOwner && p.internalNotes != null && p.internalNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔒 Internal Mill Notes (Private):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.brown)),
                const SizedBox(height: 2),
                Text(p.internalNotes!, style: const TextStyle(fontSize: 12, color: Colors.brown)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}

