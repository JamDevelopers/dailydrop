class Plan {
  final int id;
  final String code;
  final String name;
  final double monthlyPrice;
  final double? yearlyPrice;
  final int maxUsers;
  final int maxProducts;
  final int maxStorageMb;
  final int? maxCollectionsPerMonth;
  final List<String> features;
  final bool isActive;

  Plan({
    required this.id,
    required this.code,
    required this.name,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.maxUsers = 1,
    this.maxProducts = 500,
    this.maxStorageMb = 1024,
    this.maxCollectionsPerMonth,
    this.features = const [],
    this.isActive = true,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    var feats = <String>[];
    if (json['features_json'] != null && json['features_json'] is List) {
      feats = (json['features_json'] as List).map((f) => f.toString()).toList();
    }

    return Plan(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      monthlyPrice: json['monthly_price'] != null
          ? double.tryParse(json['monthly_price'].toString()) ?? 0.0
          : 0.0,
      yearlyPrice: json['yearly_price'] != null
          ? double.tryParse(json['yearly_price'].toString())
          : null,
      maxUsers: json['max_users'] != null
          ? int.tryParse(json['max_users'].toString()) ?? 1
          : 1,
      maxProducts: json['max_products'] != null
          ? int.tryParse(json['max_products'].toString()) ?? 500
          : 500,
      maxStorageMb: json['max_storage_mb'] != null
          ? int.tryParse(json['max_storage_mb'].toString()) ?? 1024
          : 1024,
      maxCollectionsPerMonth: json['max_collections_per_month'] != null
          ? int.tryParse(json['max_collections_per_month'].toString())
          : null,
      features: feats,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

