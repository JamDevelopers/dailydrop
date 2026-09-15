class User {
  final int id;
  final int? businessId;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'platform_admin', 'owner', 'manager', 'sales_staff', 'catalog_staff'
  final String? avatarPath;
  final bool isActive;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    this.businessId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarPath,
    this.isActive = true,
    this.lastLoginAt,
  });

  bool get isOwner => role == 'owner' || role == 'platform_admin';
  bool get isSalesStaff => role == 'sales_staff';
  bool get isCatalogStaff => role == 'catalog_staff';

  String get roleDisplay {
    switch (role) {
      case 'platform_admin':
        return 'Platform Admin';
      case 'owner':
        return 'Business Owner';
      case 'manager':
        return 'Store Manager';
      case 'sales_staff':
        return 'Sales Executive';
      case 'catalog_staff':
        return 'Catalog Staff';
      default:
        return role;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] != null
          ? (json['business_id'] is int
              ? json['business_id']
              : int.parse(json['business_id'].toString()))
          : null,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'owner',
      avatarPath: json['avatar_path'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar_path': avatarPath,
      'is_active': isActive ? 1 : 0,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    int? businessId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatarPath,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarPath: avatarPath ?? this.avatarPath,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

