import 'product.dart';

class Collection {
  final int id;
  final int businessId;
  final int createdByUserId;
  final String name;
  final String slug;
  final String? description;
  final DateTime? collectionDate;
  final String? coverMediaUrl;
  final String visibility; // 'draft', 'public', 'private', 'archived'
  final String priceVisibility; // 'inherit', 'show', 'hide', 'on_request'
  final bool showInMainCatalog;
  final String? festival;
  final String? occasion;
  final String shareToken;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final int sortOrder;
  final List<int> productIds;
  final List<Product> products;
  final int viewsCount;
  final int inquiriesCount;

  Collection({
    required this.id,
    required this.businessId,
    required this.createdByUserId,
    required this.name,
    required this.slug,
    this.description,
    this.collectionDate,
    this.coverMediaUrl,
    this.visibility = 'public',
    this.priceVisibility = 'inherit',
    this.showInMainCatalog = true,
    this.festival,
    this.occasion,
    required this.shareToken,
    this.publishedAt,
    this.expiresAt,
    this.sortOrder = 0,
    this.productIds = const [],
    this.products = const [],
    this.viewsCount = 0,
    this.inquiriesCount = 0,
  });

  bool get isPublished =>
      (visibility == 'public' || visibility == 'private') &&
      publishedAt != null;
  bool get isDraft => visibility == 'draft';
  bool get isPrivateLinkOnly => visibility == 'private' || !showInMainCatalog;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get remainingTimeFormatted {
    final rem = remainingTime;
    if (rem == null) return 'Active';
    if (rem == Duration.zero) return 'Expired';
    final hours = rem.inHours;
    final minutes = rem.inMinutes.remainder(60);
    if (hours > 24) {
      final days = rem.inDays;
      return '$days days left';
    }
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m left';
  }

  bool get isToday {
    final now = DateTime.now();
    final d = collectionDate ?? publishedAt ?? now;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  int get productsCount =>
      products.isNotEmpty ? products.length : productIds.length;

  String get displayCoverUrl {
    if (coverMediaUrl != null && coverMediaUrl!.isNotEmpty) {
      return coverMediaUrl!;
    }
    if (products.isNotEmpty) {
      return products.first.primaryImageUrl;
    }
    return 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600&auto=format&fit=crop&q=80';
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    var pIds = <int>[];
    if (json['product_ids'] != null && json['product_ids'] is List) {
      pIds = (json['product_ids'] as List)
          .map((id) => int.parse(id.toString()))
          .toList();
    }

    var prods = <Product>[];
    if (json['products'] != null && json['products'] is List) {
      prods = (json['products'] as List)
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return Collection(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString()) ?? 1
          : 1,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      collectionDate: json['collection_date'] != null
          ? DateTime.tryParse(json['collection_date'])
          : null,
      coverMediaUrl: json['cover_media_url'],
      visibility: json['visibility'] ?? 'public',
      priceVisibility: json['price_visibility'] ?? 'inherit',
      showInMainCatalog:
          json['show_in_main_catalog'] == 1 ||
          json['show_in_main_catalog'] == true ||
          json['show_in_main_catalog'] == null,
      festival: json['festival'],
      occasion: json['occasion'],
      shareToken: json['share_token'] ?? 'share_${json['id']}',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      sortOrder: json['sort_order'] != null
          ? int.tryParse(json['sort_order'].toString()) ?? 0
          : 0,
      productIds: pIds,
      products: prods,
      viewsCount: json['views_count'] != null
          ? int.tryParse(json['views_count'].toString()) ?? 0
          : 0,
      inquiriesCount: json['inquiries_count'] != null
          ? int.tryParse(json['inquiries_count'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'created_by_user_id': createdByUserId,
      'name': name,
      'slug': slug,
      'description': description,
      'collection_date': collectionDate?.toIso8601String().split('T').first,
      'cover_media_url': coverMediaUrl,
      'visibility': visibility,
      'price_visibility': priceVisibility,
      'show_in_main_catalog': showInMainCatalog ? 1 : 0,
      'festival': festival,
      'occasion': occasion,
      'share_token': shareToken,
      'published_at': publishedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'sort_order': sortOrder,
      'product_ids': productIds,
      'products': products.map((p) => p.toJson()).toList(),
      'views_count': viewsCount,
      'inquiries_count': inquiriesCount,
    };
  }

  Collection copyWith({
    int? id,
    int? businessId,
    int? createdByUserId,
    String? name,
    String? slug,
    String? description,
    DateTime? collectionDate,
    String? coverMediaUrl,
    String? visibility,
    String? priceVisibility,
    bool? showInMainCatalog,
    String? festival,
    String? occasion,
    String? shareToken,
    DateTime? publishedAt,
    DateTime? expiresAt,
    int? sortOrder,
    List<int>? productIds,
    List<Product>? products,
    int? viewsCount,
    int? inquiriesCount,
  }) {
    return Collection(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      collectionDate: collectionDate ?? this.collectionDate,
      coverMediaUrl: coverMediaUrl ?? this.coverMediaUrl,
      visibility: visibility ?? this.visibility,
      priceVisibility: priceVisibility ?? this.priceVisibility,
      showInMainCatalog: showInMainCatalog ?? this.showInMainCatalog,
      festival: festival ?? this.festival,
      occasion: occasion ?? this.occasion,
      shareToken: shareToken ?? this.shareToken,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      sortOrder: sortOrder ?? this.sortOrder,
      productIds: productIds ?? this.productIds,
      products: products ?? this.products,
      viewsCount: viewsCount ?? this.viewsCount,
      inquiriesCount: inquiriesCount ?? this.inquiriesCount,
    );
  }
}
