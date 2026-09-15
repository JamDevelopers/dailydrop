import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import 'share_collection_modal.dart';

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(
    text:
        "Today's Daily Drop • ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
  );
  final _descController = TextEditingController(
    text:
        'Exclusive fresh textile designs direct from Surat factory floor. Ready stock available.',
  );
  DateTime _collectionDate = DateTime.now();
  String _visibility = 'public';
  String _priceVisibility = 'show';
  bool _showInMainCatalog = true;
  String _selectedFestival = AppConstants.festivals.first;
  String _selectedOccasion = AppConstants.occasions.first;
  String _expiryOption =
      '24_hours'; // 'never', '24_hours', '48_hours', '7_days', 'custom'
  DateTime? _customExpiryDate;
  final List<int> _selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    // Default select all available products
    final catalog = context.read<CatalogProvider>();
    _selectedProductIds.addAll(catalog.allProducts.map((p) => p.id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime? _calculateExpiryDate() {
    final now = DateTime.now();
    switch (_expiryOption) {
      case '24_hours':
        return now.add(const Duration(hours: 24));
      case '48_hours':
        return now.add(const Duration(hours: 48));
      case '7_days':
        return now.add(const Duration(days: 7));
      case 'custom':
        return _customExpiryDate ?? now.add(const Duration(days: 1));
      case 'never':
      default:
        return null;
    }
  }

  void _handleCreate() {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthProvider>();
      final catalog = context.read<CatalogProvider>();

      final coll = catalog.createCollection(
        businessId: auth.business.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        collectionDate: _collectionDate,
        visibility: _visibility,
        priceVisibility: _priceVisibility,
        showInMainCatalog: _showInMainCatalog,
        festival: _selectedFestival,
        occasion: _selectedOccasion,
        expiresAt: _calculateExpiryDate(),
        productIds: _selectedProductIds,
      );

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => ShareCollectionModal(
          collection: coll,
          businessSlug: auth.business.slug,
          businessName: auth.business.name,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final allProducts = catalog.allProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Daily Drop Collection'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(
              Icons.rocket_launch,
              size: 16,
              color: Colors.white,
            ),
            label: const Text('Publish Drop'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: _handleCreate,
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
                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collection Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Collection / Daily Drop Title *',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter collection title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText:
                                'Catalog Description (Visible to Buyers)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Festival & Occasion
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Limited Time Link & Expiry Configuration
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: AppTheme.primaryEmerald,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Time-Limited Link & Expiry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set an expiry duration for this daily drop. Once expired, buyers will see a drop ended notice and be guided to current drops.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _expiryOption,
                          decoration: const InputDecoration(
                            labelText: 'Link Expiry Duration',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '24_hours',
                              child: Text('⏳ 24 Hours (Standard Daily Drop)'),
                            ),
                            DropdownMenuItem(
                              value: '48_hours',
                              child: Text('⏳ 48 Hours (Weekend Drop)'),
                            ),
                            DropdownMenuItem(
                              value: '7_days',
                              child: Text('⏳ 7 Days (Weekly Catalog)'),
                            ),
                            DropdownMenuItem(
                              value: 'never',
                              child: Text(
                                '♾️ Never Expire (Permanent Catalog)',
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'custom',
                              child: Text('📅 Custom Expiry Date & Time'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _expiryOption = val);
                          },
                        ),
                        if (_expiryOption == 'custom') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _customExpiryDate != null
                                  ? 'Expires on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_customExpiryDate!)}'
                                  : 'Select Custom Expiry Date',
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(
                                  const Duration(days: 3),
                                ),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _customExpiryDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    23,
                                    59,
                                  );
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Visibility & Main Catalog Scope
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Public Visibility & Access',
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
                                value: _visibility,
                                decoration: const InputDecoration(
                                  labelText: 'Visibility Scope',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'public',
                                    child: Text(
                                      'Public (Accessible to anyone with link)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'private',
                                    child: Text(
                                      'Private (Dealers with private token only)',
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'draft',
                                    child: Text(
                                      'Draft (Saved privately, staff only)',
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _visibility = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _priceVisibility,
                                decoration: const InputDecoration(
                                  labelText: 'Price Display Mode',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'show',
                                    child: Text('Show Wholesale Prices'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'on_request',
                                    child: Text('Price on WhatsApp Request'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hide',
                                    child: Text('Hide Prices'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _priceVisibility = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Show in Main Public Catalog Index',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'When disabled, this collection will only be accessible via its direct link / WhatsApp share and hidden from main storefront',
                          ),
                          value: _showInMainCatalog,
                          activeColor: AppTheme.primaryEmerald,
                          onChanged: (val) =>
                              setState(() => _showInMainCatalog = val),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Product Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Select Designs to Include',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedProductIds.length ==
                                      allProducts.length) {
                                    _selectedProductIds.clear();
                                  } else {
                                    _selectedProductIds.clear();
                                    _selectedProductIds.addAll(
                                      allProducts.map((p) => p.id),
                                    );
                                  }
                                });
                              },
                              child: Text(
                                _selectedProductIds.length == allProducts.length
                                    ? 'Deselect All'
                                    : 'Select All (${allProducts.length})',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allProducts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = allProducts[index];
                            final isSelected = _selectedProductIds.contains(
                              p.id,
                            );

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppTheme.primaryEmerald,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedProductIds.add(p.id);
                                  } else {
                                    _selectedProductIds.remove(p.id);
                                  }
                                });
                              },
                              secondary: ClipRRect(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${p.fabric ?? "Fabric"} • ${p.formattedPrice}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _handleCreate,
                  child: Text(
                    'Create Daily Drop (${_selectedProductIds.length} Designs)',
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
