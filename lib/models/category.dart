class Category {
  final int id;
  final int businessId;
  final int? parentId;
  final String name;
  final String slug;
  final bool isActive;
  final int sortOrder;

  Category({
    required this.id,
    required this.businessId,
    this.parentId,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      parentId: json['parent_id'] != null
          ? int.tryParse(json['parent_id'].toString())
          : null,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: json['sort_order'] != null
          ? int.tryParse(json['sort_order'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'parent_id': parentId,
      'name': name,
      'slug': slug,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}

