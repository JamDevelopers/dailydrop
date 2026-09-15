import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../collections/share_collection_modal.dart';

class CreateCustomCatalogModal extends StatefulWidget {
  final List<Product> selectedProducts;

  const CreateCustomCatalogModal({super.key, required this.selectedProducts});

  @override
  State<CreateCustomCatalogModal> createState() =>
      _CreateCustomCatalogModalState();
}

class _CreateCustomCatalogModalState extends State<CreateCustomCatalogModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String _expiryDuration =
      '24_hours'; // '2_hours', '12_hours', '24_hours', '48_hours', '7_days', 'custom'
  DateTime? _customExpiryDateTime;
  String _priceVisibility = 'show'; // 'show', 'on_request', 'hide'
  bool _isPrivateOnly = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text:
          "Custom Selection (${widget.selectedProducts.length} Designs) • ${DateFormat('dd MMM').format(DateTime.now())}",
    );
    _descController = TextEditingController(
      text:
          "Exclusive handpicked textile collection. Special wholesale pricing with limited-time availability.",
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  DateTime _calculateExpiry() {
    final now = DateTime.now();
    switch (_expiryDuration) {
      case '2_hours':
        return now.add(const Duration(hours: 2));
      case '12_hours':
        return now.add(const Duration(hours: 12));
      case '24_hours':
        return now.add(const Duration(hours: 24));
      case '48_hours':
        return now.add(const Duration(hours: 48));
      case '7_days':
        return now.add(const Duration(days: 7));
      case 'custom':
        return _customExpiryDateTime ?? now.add(const Duration(hours: 24));
      default:
        return now.add(const Duration(hours: 24));
    }
  }

  void _handleCreate() {
    if (_formKey.currentState?.validate() ?? false) {
      final auth = context.read<AuthProvider>();
      final catalog = context.read<CatalogProvider>();

      final expiry = _calculateExpiry();
      final pIds = widget.selectedProducts.map((p) => p.id).toList();

      final coll = catalog.createCollection(
        businessId: auth.business.id,
        name: _titleController.text.trim(),
        description: _descController.text.trim(),
        visibility: _isPrivateOnly ? 'private' : 'public',
        showInMainCatalog: !_isPrivateOnly,
        priceVisibility: _priceVisibility,
        expiresAt: expiry,
        productIds: pIds,
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create Time-Limited Custom Catalog',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Bundle ${widget.selectedProducts.length} selected designs with custom expiry & share privately',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selected Products Preview Strip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Selected Designs (${widget.selectedProducts.length})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.selectedProducts
                                .map((p) => p.productCode)
                                .join(', '),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryEmerald,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.selectedProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final p = widget.selectedProducts[idx];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                p.primaryImageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Description
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Catalog Title *',
                    hintText: 'e.g. VIP Selection for Riya Boutique',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter catalog title' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Buyer Note / Quote Terms',
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Color(0xFFB45309),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Time-Limited Expiry Duration',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _expiryDuration,
                        decoration: const InputDecoration(
                          labelText: 'Link Expiry Window',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '2_hours',
                            child: Text(
                              '⚡ 2 Hours (Urgent Stock Hold / Flash Quote)',
                            ),
                          ),
                          DropdownMenuItem(
                            value: '12_hours',
                            child: Text('⏳ 12 Hours (Same Day Decision)'),
                          ),
                          DropdownMenuItem(
                            value: '24_hours',
                            child: Text('⏳ 24 Hours (Standard Daily Drop)'),
                          ),
                          DropdownMenuItem(
                            value: '48_hours',
                            child: Text('⏳ 48 Hours (Weekend Special)'),
                          ),
                          DropdownMenuItem(
                            value: '7_days',
                            child: Text('⏳ 7 Days (Weekly Catalog)'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('📅 Custom Date & Time'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _expiryDuration = val);
                        },
                      ),
                      if (_expiryDuration == 'custom') ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: Text(
                            _customExpiryDateTime != null
                                ? 'Expires on: ${DateFormat('dd MMM yyyy, hh:mm a').format(_customExpiryDateTime!)}'
                                : 'Select Custom Date & Time',
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 2),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                _customExpiryDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
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
                const SizedBox(height: 16),

                // Pricing & Visibility Options
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priceVisibility,
                        decoration: const InputDecoration(
                          labelText: 'Price Mode',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'show',
                            child: Text('Show Wholesale Price'),
                          ),
                          DropdownMenuItem(
                            value: 'on_request',
                            child: Text('Price on Request'),
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
                    'Private Direct Link Only',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Keeps this custom selection private to the recipient buyer (hidden from public store)',
                  ),
                  value: _isPrivateOnly,
                  activeColor: AppTheme.primaryEmerald,
                  onChanged: (val) => setState(() => _isPrivateOnly = val),
                ),
                const SizedBox(height: 20),

                // Submit Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: Text(
                    'Generate Private Link for ${widget.selectedProducts.length} Designs',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
