import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _priceLabelController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _stockQuantityController;
  late final TextEditingController _descController;
  late final TextEditingController _notesController;
  late final TextEditingController _newImageUrlController;

  int? _selectedCategoryId;
  String _selectedFabric = AppConstants.fabrics.first;
  String _selectedColor = AppConstants.colors.first;
  String _selectedSize = AppConstants.sizes.first;
  String _selectedOccasion = AppConstants.occasions.first;
  String _selectedFestival = AppConstants.festivals.first;
  String _selectedSetOption = AppConstants.setOptions[1]; // Set of 4
  int _setCount = 4;
  String _stockStatus = 'available';
  bool _isPublic = true;
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final catalog = context.read<CatalogProvider>();

    _codeController = TextEditingController(
      text: p?.productCode ?? catalog.getNextDesignCode(),
    );
    _titleController = TextEditingController(text: p?.title ?? '');
    _priceController = TextEditingController(
      text: p?.price != null ? p!.price!.toStringAsFixed(0) : '',
    );
    _priceLabelController = TextEditingController(text: p?.priceLabel ?? '');
    _costPriceController = TextEditingController(
      text: p?.costPrice != null ? p!.costPrice!.toStringAsFixed(0) : '',
    );
    _stockQuantityController = TextEditingController(
      text: p?.stockQuantity != null ? p!.stockQuantity.toString() : '',
    );
    _descController = TextEditingController(text: p?.shortDescription ?? '');
    _notesController = TextEditingController(text: p?.internalNotes ?? '');
    _newImageUrlController = TextEditingController();

    _selectedCategoryId = p?.categoryId ?? 1;
    if (p?.fabric != null && AppConstants.fabrics.contains(p!.fabric)) {
      _selectedFabric = p.fabric!;
    }
    if (p?.color != null && AppConstants.colors.contains(p!.color)) {
      _selectedColor = p.color!;
    }
    if (p?.size != null && AppConstants.sizes.contains(p!.size)) {
      _selectedSize = p.size!;
    }
    if (p?.occasion != null && AppConstants.occasions.contains(p!.occasion)) {
      _selectedOccasion = p.occasion!;
    }
    if (p?.festival != null && AppConstants.festivals.contains(p!.festival)) {
      _selectedFestival = p.festival!;
    }
    if (p != null) {
      _setCount = p.setCount;
      _stockStatus = p.stockStatus;
      _isPublic = p.isPublic;
      _imageUrls.addAll(p.allImageUrls);
    } else {
      _imageUrls.add(
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _priceLabelController.dispose();
    _costPriceController.dispose();
    _stockQuantityController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _newImageUrlController.dispose();
    super.dispose();
  }

  void _addImageUrl() {
    final url = _newImageUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _imageUrls.add(url);
        _newImageUrlController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _saveProduct() {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthProvider>();
      final catalog = context.read<CatalogProvider>();

      final priceVal = double.tryParse(_priceController.text);
      final costVal = double.tryParse(_costPriceController.text);
      final stockQtyVal = int.tryParse(_stockQuantityController.text);

      if (widget.product != null) {
        // Edit
        final updated = widget.product!.copyWith(
          productCode: _codeController.text.trim(),
          title: _titleController.text.trim(),
          categoryId: _selectedCategoryId,
          fabric: _selectedFabric,
          color: _selectedColor,
          size: _selectedSize,
          occasion: _selectedOccasion,
          festival: _selectedFestival,
          setCount: _setCount,
          setLabel: 'Set of $_setCount',
          price: priceVal,
          priceLabel: _priceLabelController.text.trim().isNotEmpty
              ? _priceLabelController.text.trim()
              : (priceVal != null
                    ? '₹${priceVal.toStringAsFixed(0)} / Pc (Set of $_setCount)'
                    : null),
          costPrice: costVal,
          stockStatus: _stockStatus,
          stockQuantity: stockQtyVal,
          shortDescription: _descController.text.trim(),
          internalNotes: _notesController.text.trim(),
          isPublic: _isPublic,
          imageUrls: _imageUrls,
        );
        catalog.updateProduct(updated);
      } else {
        // Add
        catalog.addProduct(
          businessId: auth.business.id,
          productCode: _codeController.text.trim(),
          title: _titleController.text.trim(),
          categoryId: _selectedCategoryId,
          fabric: _selectedFabric,
          color: _selectedColor,
          size: _selectedSize,
          occasion: _selectedOccasion,
          festival: _selectedFestival,
          setCount: _setCount,
          setLabel: 'Set of $_setCount',
          price: priceVal,
          priceLabel: _priceLabelController.text.trim().isNotEmpty
              ? _priceLabelController.text.trim()
              : (priceVal != null
                    ? '₹${priceVal.toStringAsFixed(0)} / Pc (Set of $_setCount)'
                    : null),
          costPrice: costVal,
          stockStatus: _stockStatus,
          stockQuantity: stockQtyVal,
          shortDescription: _descController.text.trim(),
          internalNotes: _notesController.text.trim(),
          isPublic: _isPublic,
          imageUrls: _imageUrls,
        );
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Edit Product ${widget.product!.productCode}'
              : 'Add New Textile Product',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: AppTheme.primaryEmerald),
            label: const Text(
              'Save Product',
              style: TextStyle(
                color: AppTheme.primaryEmerald,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _saveProduct,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Design Code Row
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Design Code & Identifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Design / Product Code *',
                                  hintText: 'e.g. SR-260915-001',
                                  prefixIcon: Icon(Icons.qr_code),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Enter design code'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Generate Next'),
                              onPressed: () {
                                setState(() {
                                  _codeController.text = catalog
                                      .getNextDesignCode();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Core Textile Attributes (Category, Fabric, Color, Size, Occasion, Festival)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Textile Specifications & Attributes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Product Title',
                            hintText:
                                'e.g. Festive Georgette Saree with Scallop Border',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category & Fabric
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                ),
                                items: catalog.categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCategoryId = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedFabric,
                                decoration: const InputDecoration(
                                  labelText: 'Fabric Type *',
                                ),
                                items: AppConstants.fabrics.map((f) {
                                  return DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedFabric = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Color & Size
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedColor,
                                decoration: const InputDecoration(
                                  labelText: 'Primary Color',
                                ),
                                items: AppConstants.colors.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedColor = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSize,
                                decoration: const InputDecoration(
                                  labelText: 'Size / Cut',
                                ),
                                items: AppConstants.sizes.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedSize = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Occasion & Festival
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedOccasion,
                                decoration: const InputDecoration(
                                  labelText: 'Occasion',
                                ),
                                items: AppConstants.occasions.map((o) {
                                  return DropdownMenuItem(
                                    value: o,
                                    child: Text(o),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedOccasion = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedFestival,
                                decoration: const InputDecoration(
                                  labelText: 'Festival Collection',
                                ),
                                items: AppConstants.festivals.map((f) {
                                  return DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedFestival = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Set & Pricing
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wholesale Set & Pricing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedSetOption,
                                decoration: const InputDecoration(
                                  labelText: 'Wholesale Set Packaging',
                                ),
                                items: AppConstants.setOptions.map((opt) {
                                  return DropdownMenuItem(
                                    value: opt,
                                    child: Text(opt),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSetOption = val;
                                      if (val.contains('Set of 4'))
                                        _setCount = 4;
                                      else if (val.contains('Set of 6'))
                                        _setCount = 6;
                                      else if (val.contains('Set of 8'))
                                        _setCount = 8;
                                      else if (val.contains('Single Piece'))
                                        _setCount = 1;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price Per Piece (₹) *',
                                  prefixText: '₹ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _costPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cost Price (Private)',
                                  prefixText: '₹ ',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _stockStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Stock Status',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'available',
                                    child: Text('Available in Stock'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'limited',
                                    child: Text('Limited Stock'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sold_out',
                                    child: Text('Sold Out'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'discontinued',
                                    child: Text('Discontinued'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _stockStatus = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _stockQuantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Available Quantity (Pieces)',
                                  hintText: 'e.g. 150',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Multi-Image Carousel Manager (Set of 4 Colors / Angles)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Product Images & Color Carousel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_imageUrls.length} Photo${_imageUrls.length == 1 ? '' : 's'} (${_setCount} Set Variant)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add multiple photos for all colors in this set. Buyers will be able to swipe through them in the catalog carousel.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add Image URL row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newImageUrlController,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Add Image URL (Color Variant / Angle)',
                                  hintText: 'https://...',
                                  prefixIcon: Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Image'),
                              onPressed: _addImageUrl,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Image Thumbnail Grid
                        if (_imageUrls.isNotEmpty)
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _imageUrls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: index == 0
                                            ? AppTheme.primaryEmerald
                                            : AppTheme.borderColor,
                                        width: index == 0 ? 2 : 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index == 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryEmerald,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Cover',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: InkWell(
                                      onTap: () => _removeImageUrl(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description & Visibility
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Catalog Notes & Visibility',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Short Description (Buyer facing)',
                            hintText:
                                'e.g. 60 gram Dola Silk with 4 matching colors. Ready stock dispatch.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Internal Mill Notes (Private to staff)',
                            hintText:
                                'e.g. Mill Lot #442. Extra margin for bulk orders.',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Show in Public Catalog',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Toggle whether buyers can view this product in the main store index',
                          ),
                          value: _isPublic,
                          activeColor: AppTheme.primaryEmerald,
                          onChanged: (val) => setState(() => _isPublic = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(
                    isEdit ? 'Save Product Changes' : 'Create Textile Product',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
