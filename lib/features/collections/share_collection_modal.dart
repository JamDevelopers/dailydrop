import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme.dart';
import '../../models/collection.dart';
import '../../services/whatsapp_link_service.dart';
import '../public_catalog/public_catalog_screen.dart';

class ShareCollectionModal extends StatelessWidget {
  final Collection collection;
  final String businessSlug;
  final String businessName;

  const ShareCollectionModal({
    super.key,
    required this.collection,
    required this.businessSlug,
    required this.businessName,
  });

  String get publicCatalogUrl =>
      'https://textiledrop.com/catalog/$businessSlug/drop/${collection.shareToken}';

  @override
  Widget build(BuildContext context) {
    final shareMessage = WhatsAppLinkService.generateCollectionShareMessage(
      businessName: businessName,
      collectionName: collection.name,
      shareUrl: publicCatalogUrl,
      productCount: collection.productsCount,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
                      Icons.share_rounded,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share Daily Drop',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          collection.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

              // Expiry & Scope Status Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: collection.isExpired
                      ? Colors.red.shade50
                      : (collection.expiresAt != null
                            ? Colors.amber.shade50
                            : AppTheme.primaryLight),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: collection.isExpired
                        ? Colors.red.shade200
                        : (collection.expiresAt != null
                              ? Colors.amber.shade300
                              : AppTheme.primaryEmerald.withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      collection.isExpired
                          ? Icons.error_outline
                          : (collection.expiresAt != null
                                ? Icons.timer_outlined
                                : Icons.check_circle_outline),
                      size: 18,
                      color: collection.isExpired
                          ? Colors.red.shade700
                          : (collection.expiresAt != null
                                ? Colors.amber.shade900
                                : AppTheme.primaryEmerald),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        collection.isExpired
                            ? 'Drop has expired on this link'
                            : (collection.expiresAt != null
                                  ? 'Limited-Time Link: ${collection.remainingTimeFormatted}'
                                  : 'Permanent Active Catalog Link'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: collection.isExpired
                              ? Colors.red.shade800
                              : (collection.expiresAt != null
                                    ? Colors.amber.shade900
                                    : AppTheme.primaryDark),
                        ),
                      ),
                    ),
                    if (collection.isPrivateLinkOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Private Link',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QR Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: QrImageView(
                        data: publicCatalogUrl,
                        version: QrVersions.auto,
                        size: 150,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan to browse catalog on mobile',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Public URL Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        publicCatalogUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 18,
                        color: AppTheme.primaryEmerald,
                      ),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: publicCatalogUrl),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Catalog link copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Share Broadcast on WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.whatsappGreen,
                ),
                onPressed: () {
                  final encoded = Uri.encodeComponent(shareMessage);
                  WhatsAppLinkService.launchWhatsAppUrl(
                    'https://wa.me/?text=$encoded',
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Preview Public Buyer View'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicCatalogScreen(
                        businessSlug: businessSlug,
                        collectionSlug: collection.slug,
                      ),
                    ),
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
