import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../collections/share_collection_modal.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prefixController = TextEditingController(text: 'SR');
  final _priceController = TextEditingController(text: '950');
  final _priceLabelController = TextEditingController(
    text: '₹950 / Pc (Set of 4)',
  );
  final _titlePrefixController = TextEditingController(
    text: 'Festive Georgette Saree',
  );

  String _selectedFabric = 'Georgette';
  String _selectedFestival = 'Diwali Special';
  String _selectedOccasion = 'Festive';
  String _selectedSetOption = AppConstants.setOptions[1]; // Set of 4
  int _setCount = 4;
  int? _selectedCategoryId = 1;
  int? _selectedCollectionId;
  bool _createNewCollection = true;
  final _collectionNameController = TextEditingController(
    text: "Today's New Arrival • ${DateTime.now().day} Sep 2026",
  );

  List<String> _selectedImageUrls = [
    'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1609357605129-26f69add5d6e?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=800&auto=format&fit=crop&q=80',
  ];

  bool _isProcessing = false;

  @override
  void dispose() {
    _prefixController.dispose();
    _priceController.dispose();
    _priceLabelController.dispose();
    _titlePrefixController.dispose();
    _collectionNameController.dispose();
    super.dispose();
  }

  void _addMoreSampleImages() {
    setState(() {
      _selectedImageUrls.addAll([
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=800&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=800&auto=format&fit=crop&q=80',
      ]);
    });
  }

  void _handleBulkSubmit() async {
    if (_selectedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 image to upload.'),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isProcessing = true);

      final auth = context.read<AuthProvider>();
      final catalog = context.read<CatalogProvider>();

      int? targetCollectionId = _selectedCollectionId;

      // Create new collection if requested
      if (_createNewCollection && _collectionNameController.text.isNotEmpty) {
        final newColl = catalog.createCollection(
          businessId: auth.business.id,
          name: _collectionNameController.text.trim(),
          description: 'Daily Drop created via bulk image upload.',
          visibility: 'public',
          priceVisibility: 'show',
          festival: _selectedFestival,
          occasion: _selectedOccasion,
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );
        targetCollectionId = newColl.id;
      }

      final priceVal = double.tryParse(_priceController.text);

      final createdProducts = catalog.batchUploadProducts(
        businessId: auth.business.id,
        imageUrls: _selectedImageUrls,
        prefix: _prefixController.text.trim().toUpperCase(),
        categoryId: _selectedCategoryId,
        fabric: _selectedFabric,
        occasion: _selectedOccasion,
        festival: _selectedFestival,
        setCount: _setCount,
        price: priceVal,
        priceLabel: _priceLabelController.text.trim(),
        titlePrefix: _titlePrefixController.text.trim(),
        collectionId: targetCollectionId,
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Successfully created ${createdProducts.length} designs with sequential design codes!',
          ),
          backgroundColor: AppTheme.primaryDark,
        ),
      );

      // Show share modal if collection was targeted
      if (targetCollectionId != null) {
        final targetColl = catalog.collections.firstWhere(
          (c) => c.id == targetCollectionId,
        );
        showDialog(
          context: context,
          builder: (_) => ShareCollectionModal(
            collection: targetColl,
            businessSlug: auth.business.slug,
            businessName: auth.business.name,
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Image Upload & Daily Drop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: MaxWidthContainer(
          maxWidth: 900,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryEmerald.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flash_on_rounded,
                        color: AppTheme.primaryEmerald,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surat Daily Drop Workflow',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select 10-50 textile photos → System auto-assigns sequential design codes → Publish 1 WhatsApp link for all designs.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Step 1: Photos selected
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '1. Selected Photos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_selectedImageUrls.length} Photos in Queue',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.add_photo_alternate,
                                size: 16,
                              ),
                              label: const Text('Add More'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _addMoreSampleImages,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Horizontal Images Preview Strip
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImageUrls.length,
                            itemBuilder: (context, index) {
                              final seq = (index + 1).toString().padLeft(
                                3,
                                '0',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _selectedImageUrls[index],
                                        width: 110,
                                        height: 110,
                                        fit: BoxFit.cover,
                                      ),
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
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '#$seq',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImageUrls.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
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
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Auto Design Codes & Batch Configuration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '2. Design Code & Batch Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _prefixController,
                                decoration: const InputDecoration(
                                  labelText: 'Code Prefix',
                                  hintText: 'e.g. SR, ABC',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedFabric,
                                decoration: const InputDecoration(
                                  labelText: 'Fabric',
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
                        // Festival, Occasion, and Set selection
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedFestival,
                                decoration: const InputDecoration(
                                  labelText: 'Festival Tag',
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedOccasion,
                                decoration: const InputDecoration(
                                  labelText: 'Occasion Tag',
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
                                value: _selectedSetOption,
                                decoration: const InputDecoration(
                                  labelText: 'Set Packaging',
                                ),
                                items: AppConstants.setOptions.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
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
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Wholesale Price Per Piece (₹)',
                                  prefixText: '₹ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceLabelController,
                                decoration: const InputDecoration(
                                  labelText: 'Price Label / Terms',
                                  hintText: 'e.g. ₹950 / Pc (Set of 4)',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titlePrefixController,
                          decoration: const InputDecoration(
                            labelText: 'Product Title Pattern',
                            hintText: 'e.g. Pure Georgette Zari Saree',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Step 3: Bundle into Daily Drop Collection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3. Bundle into Daily Drop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Create new Daily Drop collection for this upload',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'Creates a single public catalog link with 24h countdown for all uploaded photos.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          value: _createNewCollection,
                          activeColor: AppTheme.primaryEmerald,
                          onChanged: (val) =>
                              setState(() => _createNewCollection = val),
                        ),
                        if (_createNewCollection) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _collectionNameController,
                            decoration: const InputDecoration(
                              labelText: 'Daily Drop Title',
                              prefixIcon: Icon(
                                Icons.collections_bookmark_outlined,
                              ),
                            ),
                            validator: (val) =>
                                _createNewCollection &&
                                    (val == null || val.isEmpty)
                                ? 'Enter drop title'
                                : null,
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedCollectionId,
                            decoration: const InputDecoration(
                              labelText: 'Add to Existing Collection',
                            ),
                            items: catalog.collections.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCollectionId = val),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.rocket_launch_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isProcessing
                        ? 'Processing ${_selectedImageUrls.length} Designs...'
                        : 'Create ${_selectedImageUrls.length} Products & Publish Drop Link',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isProcessing ? null : _handleBulkSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
