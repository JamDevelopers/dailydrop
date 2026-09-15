import 'media_asset.dart';

class Product {
  final int id;
  final int businessId;
  final int? categoryId;
  final String? categoryName;
  final int createdByUserId;
  final String productCode;
  final String? title;
  final String? fabric;
  final String? color;
  final String? size;
  final String? occasion;
  final String? festival;
  final int setCount;
  final String? setLabel;
  final String? brand;
  final double? price;
  final String? priceLabel;
  final double? costPrice;
  final String
  stockStatus; // 'available', 'limited', 'sold_out', 'discontinued'
  final int? stockQuantity;
  final String? shortDescription;
  final String? internalNotes;
  final bool isPublic;
  final bool isActive;
  final List<MediaAsset> media;
  final List<String> imageUrls;
  final List<String> colorVariants;
  final int viewsCount;
  final int inquiriesCount;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    this.categoryName,
    required this.createdByUserId,
    required this.productCode,
    this.title,
    this.fabric,
    this.color,
    this.size,
    this.occasion,
    this.festival,
    this.setCount = 4,
    this.setLabel,
    this.brand,
    this.price,
    this.priceLabel,
    this.costPrice,
    this.stockStatus = 'available',
    this.stockQuantity,
    this.shortDescription,
    this.internalNotes,
    this.isPublic = true,
    this.isActive = true,
    this.media = const [],
    this.imageUrls = const [],
    this.colorVariants = const [],
    this.viewsCount = 0,
    this.inquiriesCount = 0,
    this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get remainingTimeFormatted {
    if (expiresAt == null) return 'No Expiry';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '${diff.inSeconds}s';
  }

  String get primaryImageUrl {
    if (imageUrls.isNotEmpty) {
      return imageUrls.first;
    }
    if (media.isNotEmpty) {
      return media.first.displayUrl;
    }
    return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600&auto=format&fit=crop&q=80';
  }

  List<String> get allImageUrls {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }
    if (media.isNotEmpty) {
      return media.map((m) => m.displayUrl).toList();
    }
    return [primaryImageUrl];
  }

  String get displayTitle =>
      (title != null && title!.isNotEmpty) ? title! : 'Design $productCode';

  String get formattedPrice {
    if (priceLabel != null && priceLabel!.isNotEmpty) {
      return priceLabel!;
    }
    if (price != null && price! > 0) {
      final formattedNum = '₹${price!.toStringAsFixed(0)}';
      if (setCount > 1) {
        return '$formattedNum / Pc (Set of $setCount)';
      }
      return '$formattedNum / Pc';
    }
    return 'Price on Request';
  }

  bool get isAvailable =>
      stockStatus == 'available' || stockStatus == 'limited';
  bool get hasMultipleImages => allImageUrls.length > 1;

  factory Product.fromJson(Map<String, dynamic> json) {
    var mediaList = <MediaAsset>[];
    if (json['media'] != null && json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((m) => MediaAsset.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    var imgList = <String>[];
    if (json['image_urls'] != null && json['image_urls'] is List) {
      imgList = (json['image_urls'] as List).map((i) => i.toString()).toList();
    } else if (mediaList.isNotEmpty) {
      imgList = mediaList.map((m) => m.displayUrl).toList();
    }

    var colorsList = <String>[];
    if (json['colors'] != null && json['colors'] is List) {
      colorsList = (json['colors'] as List).map((c) => c.toString()).toList();
    }

    return Product(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString())
          : null,
      categoryName: json['category_name'],
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString()) ?? 1
          : 1,
      productCode: json['product_code'] ?? '',
      title: json['title'],
      fabric: json['fabric'] ?? json['fabric_type'],
      color: json['color'],
      size: json['size'],
      occasion: json['occasion'],
      festival: json['festival'],
      setCount: json['set_count'] != null
          ? int.tryParse(json['set_count'].toString()) ?? 4
          : 4,
      setLabel: json['set_label'],
      brand: json['brand'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      priceLabel: json['price_label'],
      costPrice: json['cost_price'] != null
          ? double.tryParse(json['cost_price'].toString())
          : null,
      stockStatus: json['stock_status'] ?? 'available',
      stockQuantity: json['stock_quantity'] != null
          ? int.tryParse(json['stock_quantity'].toString())
          : null,
      shortDescription: json['short_description'] ?? json['description'],
      internalNotes: json['internal_notes'],
      isPublic:
          json['is_public'] == 1 ||
          json['is_public'] == true ||
          json['is_public'] == null,
      isActive:
          json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      media: mediaList,
      imageUrls: imgList,
      colorVariants: colorsList,
      viewsCount: json['views_count'] != null
          ? int.tryParse(json['views_count'].toString()) ?? 0
          : 0,
      inquiriesCount: json['inquiries_count'] != null
          ? int.tryParse(json['inquiries_count'].toString()) ?? 0
          : 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'category_name': categoryName,
      'created_by_user_id': createdByUserId,
      'product_code': productCode,
      'title': title,
      'fabric': fabric,
      'color': color,
      'size': size,
      'occasion': occasion,
      'festival': festival,
      'set_count': setCount,
      'set_label': setLabel,
      'brand': brand,
      'price': price,
      'price_label': priceLabel,
      'cost_price': costPrice,
      'stock_status': stockStatus,
      'stock_quantity': stockQuantity,
      'short_description': shortDescription,
      'internal_notes': internalNotes,
      'is_public': isPublic ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'media': media.map((m) => m.toJson()).toList(),
      'image_urls': imageUrls,
      'colors': colorVariants,
      'views_count': viewsCount,
      'inquiries_count': inquiriesCount,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    int? businessId,
    int? categoryId,
    String? categoryName,
    int? createdByUserId,
    String? productCode,
    String? title,
    String? fabric,
    String? color,
    String? size,
    String? occasion,
    String? festival,
    int? setCount,
    String? setLabel,
    String? brand,
    double? price,
    String? priceLabel,
    double? costPrice,
    String? stockStatus,
    int? stockQuantity,
    String? shortDescription,
    String? internalNotes,
    bool? isPublic,
    bool? isActive,
    List<MediaAsset>? media,
    List<String>? imageUrls,
    List<String>? colorVariants,
    int? viewsCount,
    int? inquiriesCount,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      productCode: productCode ?? this.productCode,
      title: title ?? this.title,
      fabric: fabric ?? this.fabric,
      color: color ?? this.color,
      size: size ?? this.size,
      occasion: occasion ?? this.occasion,
      festival: festival ?? this.festival,
      setCount: setCount ?? this.setCount,
      setLabel: setLabel ?? this.setLabel,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      priceLabel: priceLabel ?? this.priceLabel,
      costPrice: costPrice ?? this.costPrice,
      stockStatus: stockStatus ?? this.stockStatus,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      shortDescription: shortDescription ?? this.shortDescription,
      internalNotes: internalNotes ?? this.internalNotes,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      media: media ?? this.media,
      imageUrls: imageUrls ?? this.imageUrls,
      colorVariants: colorVariants ?? this.colorVariants,
      viewsCount: viewsCount ?? this.viewsCount,
      inquiriesCount: inquiriesCount ?? this.inquiriesCount,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
