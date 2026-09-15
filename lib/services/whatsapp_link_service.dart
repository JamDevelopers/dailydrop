import 'package:url_launcher/url_launcher.dart';

class WhatsAppLinkService {
  static String formatPhoneNumber(String phone) {
    var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      clean = '91$clean'; // Default India country code
    }
    return clean;
  }

  static String generateInquiryUrl({
    required String sellerWhatsAppNumber,
    required String productCode,
    String? collectionName,
    String? customTemplate,
  }) {
    final cleanNumber = formatPhoneNumber(sellerWhatsAppNumber);
    final coll = collectionName ?? "Today's Daily Drop";
    final template = customTemplate ??
        'Hello, I am interested in Design {product_code} from {collection_name}. Please share wholesale price, video and available colors.';

    final message = template
        .replaceAll('{product_code}', productCode)
        .replaceAll('{collection_name}', coll);

    return 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
  }

  static String generateCollectionShareMessage({
    required String businessName,
    required String collectionName,
    required String shareUrl,
    int? productCount,
  }) {
    final countText = productCount != null ? ' ($productCount Fresh Designs)' : '';
    return '''✨ *${businessName.toUpperCase()}* ✨
*Daily Drop: $collectionName*$countText

👉 View full catalog with high-resolution photos & wholesale details here:
$shareUrl

_Direct inquiry with Design Code available on catalog link._''';
  }

  static Future<bool> launchWhatsAppUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> openDirectChat({
    required String buyerPhone,
    String? initialText,
  }) async {
    final clean = formatPhoneNumber(buyerPhone);
    final textParam = initialText != null && initialText.isNotEmpty
        ? '?text=${Uri.encodeComponent(initialText)}'
        : '';
    final url = 'https://wa.me/$clean$textParam';
    return await launchWhatsAppUrl(url);
  }
}

