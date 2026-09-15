import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../models/collection.dart';
import '../../providers/inquiry_provider.dart';
import '../../services/whatsapp_link_service.dart';

class AskWhatsAppModal extends StatefulWidget {
  final Product product;
  final Collection? collection;
  final String sellerWhatsApp;
  final String businessName;
  final int businessId;

  const AskWhatsAppModal({
    super.key,
    required this.product,
    this.collection,
    required this.sellerWhatsApp,
    required this.businessName,
    required this.businessId,
  });

  @override
  State<AskWhatsAppModal> createState() => _AskWhatsAppModalState();
}

class _AskWhatsAppModalState extends State<AskWhatsAppModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Riya Boutique (Surat)');
  final _phoneController = TextEditingController(text: '9876543210');
  late final TextEditingController _messageController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.product.colorVariants.isNotEmpty
        ? widget.product.colorVariants.first
        : (widget.product.color ?? 'All Colors (Full Set)');

    _messageController = TextEditingController(
      text:
          'Please share wholesale price, video and available stock for full Set of ${widget.product.setCount}.',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitAndLaunchWhatsApp() {
    if (_formKey.currentState?.validate() ?? false) {
      final inqProvider = context.read<InquiryProvider>();

      final fullNote =
          'Color: $_selectedColor. ${_messageController.text.trim()}';

      // Record inquiry in CRM
      inqProvider.submitPublicInquiry(
        businessId: widget.businessId,
        buyerPhone: _phoneController.text.trim(),
        buyerName: _nameController.text.trim(),
        productId: widget.product.id,
        productCode: widget.product.productCode,
        productTitle: widget.product.title,
        productImage: widget.product.primaryImageUrl,
        productPrice: widget.product.price,
        collectionId: widget.collection?.id,
        collectionName: widget.collection?.name,
        message: fullNote,
      );

      // Generate WhatsApp Link with rich textile details
      final collName = widget.collection?.name ?? "Today's Daily Drop";
      var msg = 'Namaste ${widget.businessName},\n';
      msg += 'I am ${_nameController.text.trim()}.\n';
      msg +=
          'Inquiry for Design *${widget.product.productCode}* (${widget.product.displayTitle})\n';
      if (widget.product.fabric != null) {
        msg += '👗 Fabric: ${widget.product.fabric}\n';
      }
      if (widget.product.setCount > 1) {
        msg += '📦 Set: Set of ${widget.product.setCount} Pieces\n';
      }
      msg += '🎨 Color Preference: $_selectedColor\n';
      if (widget.product.price != null) {
        msg += '💰 Catalog Rate: ${widget.product.formattedPrice}\n';
      }
      msg += '📁 Collection: $collName\n\n';
      msg += '${_messageController.text.trim()}';

      final cleanSellerNumber = WhatsAppLinkService.formatPhoneNumber(
        widget.sellerWhatsApp,
      );
      final waUrl =
          'https://wa.me/$cleanSellerNumber?text=${Uri.encodeComponent(msg)}';

      Navigator.of(context).pop();

      WhatsAppLinkService.launchWhatsAppUrl(waUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                        color: AppTheme.whatsappGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: AppTheme.whatsappGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ask Seller on WhatsApp',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            widget.businessName,
                            style: const TextStyle(
                              fontSize: 13,
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

                // Selected Product Preview Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product.primaryImageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.product.productCode,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (widget.product.fabric != null)
                                  Text(
                                    widget.product.fabric!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.product.displayTitle,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.product.formattedPrice,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryEmerald,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Color Selection (if multiple color variants)
                if (widget.product.colorVariants.isNotEmpty) ...[
                  const Text(
                    'Select Color Variant:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...widget.product.colorVariants.map((c) {
                          final isSelected = _selectedColor == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedColor = c);
                              },
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: const Text('All Colors (Full Set)'),
                          selected: _selectedColor == 'All Colors (Full Set)',
                          onSelected: (val) {
                            if (val)
                              setState(
                                () => _selectedColor = 'All Colors (Full Set)',
                              );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Buyer Details Inputs
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name / Shop Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Your WhatsApp Number *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) => val == null || val.length < 10
                      ? 'Enter valid phone number'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _messageController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Requirement / Note',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Action
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                  ),
                  label: const Text('Connect on WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.whatsappGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _submitAndLaunchWhatsApp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
