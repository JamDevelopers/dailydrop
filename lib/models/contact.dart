class Contact {
  final int id;
  final int businessId;
  final int? createdByUserId;
  final String? name;
  final String phoneE164;
  final String? email;
  final String? companyName;
  final String? city;
  final String? state;
  final String country;
  final String contactType; // 'buyer', 'dealer', 'reseller', 'retailer', 'other'
  final String preferredLanguage; // 'gu', 'hi', 'en'
  final String preferredFrequency; // 'daily', 'weekly', 'special_only', 'none'
  final List<String> tags;
  final bool isBlocked;
  final int totalInquiries;
  final int totalOrders;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.businessId,
    this.createdByUserId,
    this.name,
    required this.phoneE164,
    this.email,
    this.companyName,
    this.city,
    this.state,
    this.country = 'India',
    this.contactType = 'buyer',
    this.preferredLanguage = 'hi',
    this.preferredFrequency = 'daily',
    this.tags = const [],
    this.isBlocked = false,
    this.totalInquiries = 0,
    this.totalOrders = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      if (companyName != null && companyName!.isNotEmpty) {
        return '$name ($companyName)';
      }
      return name!;
    }
    if (companyName != null && companyName!.isNotEmpty) {
      return companyName!;
    }
    return phoneE164;
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    var tagList = <String>[];
    if (json['tags_json'] != null) {
      if (json['tags_json'] is List) {
        tagList = (json['tags_json'] as List).map((e) => e.toString()).toList();
      }
    }

    return Contact(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      createdByUserId: json['created_by_user_id'] != null
          ? int.tryParse(json['created_by_user_id'].toString())
          : null,
      name: json['name'],
      phoneE164: json['phone_e164'] ?? json['phone'] ?? '',
      email: json['email'],
      companyName: json['company_name'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      contactType: json['contact_type'] ?? 'buyer',
      preferredLanguage: json['preferred_language'] ?? 'hi',
      preferredFrequency: json['preferred_frequency'] ?? 'daily',
      tags: tagList,
      isBlocked: json['is_blocked'] == 1 || json['is_blocked'] == true,
      totalInquiries: json['total_inquiries'] != null
          ? int.tryParse(json['total_inquiries'].toString()) ?? 0
          : 0,
      totalOrders: json['total_orders'] != null
          ? int.tryParse(json['total_orders'].toString()) ?? 0
          : 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'created_by_user_id': createdByUserId,
      'name': name,
      'phone_e164': phoneE164,
      'email': email,
      'company_name': companyName,
      'city': city,
      'state': state,
      'country': country,
      'contact_type': contactType,
      'preferred_language': preferredLanguage,
      'preferred_frequency': preferredFrequency,
      'tags_json': tags,
      'is_blocked': isBlocked ? 1 : 0,
      'total_inquiries': totalInquiries,
      'total_orders': totalOrders,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Contact copyWith({
    int? id,
    int? businessId,
    int? createdByUserId,
    String? name,
    String? phoneE164,
    String? email,
    String? companyName,
    String? city,
    String? state,
    String? country,
    String? contactType,
    String? preferredLanguage,
    String? preferredFrequency,
    List<String>? tags,
    bool? isBlocked,
    int? totalInquiries,
    int? totalOrders,
  }) {
    return Contact(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      name: name ?? this.name,
      phoneE164: phoneE164 ?? this.phoneE164,
      email: email ?? this.email,
      companyName: companyName ?? this.companyName,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      contactType: contactType ?? this.contactType,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      preferredFrequency: preferredFrequency ?? this.preferredFrequency,
      tags: tags ?? this.tags,
      isBlocked: isBlocked ?? this.isBlocked,
      totalInquiries: totalInquiries ?? this.totalInquiries,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt,
    );
  }
}

