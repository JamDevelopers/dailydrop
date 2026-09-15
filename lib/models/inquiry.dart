class InquiryActivity {
  final int id;
  final int businessId;
  final int inquiryId;
  final int? userId;
  final String? userName;
  final String activityType; // 'created', 'note', 'status_changed', 'call', 'whatsapp_opened', 'quote_sent', 'follow_up_scheduled', 'product_shared'
  final String? body;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  InquiryActivity({
    required this.id,
    required this.businessId,
    required this.inquiryId,
    this.userId,
    this.userName,
    required this.activityType,
    this.body,
    this.metadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory InquiryActivity.fromJson(Map<String, dynamic> json) {
    return InquiryActivity(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      inquiryId: json['inquiry_id'] is int
          ? json['inquiry_id']
          : int.parse(json['inquiry_id'].toString()),
      userId: json['user_id'] != null
          ? int.tryParse(json['user_id'].toString())
          : null,
      userName: json['user_name'],
      activityType: json['activity_type'] ?? 'note',
      body: json['body'],
      metadata: json['metadata_json'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'inquiry_id': inquiryId,
      'user_id': userId,
      'user_name': userName,
      'activity_type': activityType,
      'body': body,
      'metadata_json': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Inquiry {
  final int id;
  final int businessId;
  final int? contactId;
  final String? contactName;
  final String contactPhone;
  final String? contactCompany;
  final int? productId;
  final String? productCode;
  final String? productTitle;
  final String? productImage;
  final double? productPrice;
  final int? collectionId;
  final String? collectionName;
  final int? assignedToUserId;
  final String? assignedToUserName;
  final String source; // 'catalog', 'whatsapp', 'manual', 'qr', 'instagram', 'website', 'other'
  final String status; // 'new', 'contacted', 'catalog_sent', 'quoted', 'follow_up', 'ordered', 'lost', 'closed'
  final String? message;
  final double? quotedAmount;
  final DateTime? nextFollowUpAt;
  final DateTime? lastContactedAt;
  final String? lostReason;
  final List<InquiryActivity> activities;
  final DateTime createdAt;
  final DateTime updatedAt;

  Inquiry({
    required this.id,
    required this.businessId,
    this.contactId,
    this.contactName,
    required this.contactPhone,
    this.contactCompany,
    this.productId,
    this.productCode,
    this.productTitle,
    this.productImage,
    this.productPrice,
    this.collectionId,
    this.collectionName,
    this.assignedToUserId,
    this.assignedToUserName,
    this.source = 'catalog',
    this.status = 'new',
    this.message,
    this.quotedAmount,
    this.nextFollowUpAt,
    this.lastContactedAt,
    this.lostReason,
    this.activities = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get buyerDisplayName {
    if (contactName != null && contactName!.isNotEmpty) {
      if (contactCompany != null && contactCompany!.isNotEmpty) {
        return '$contactName ($contactCompany)';
      }
      return contactName!;
    }
    return contactPhone;
  }

  String get statusDisplay {
    switch (status) {
      case 'new':
        return 'New Inquiry';
      case 'contacted':
        return 'Contacted';
      case 'catalog_sent':
        return 'Catalog Sent';
      case 'quoted':
        return 'Price Quoted';
      case 'follow_up':
        return 'Follow-Up Scheduled';
      case 'ordered':
        return 'Deal Closed / Ordered';
      case 'lost':
        return 'Lost';
      case 'closed':
        return 'Archived';
      default:
        return status;
    }
  }

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    var acts = <InquiryActivity>[];
    if (json['activities'] != null && json['activities'] is List) {
      acts = (json['activities'] as List)
          .map((a) => InquiryActivity.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return Inquiry(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      contactId: json['contact_id'] != null
          ? int.tryParse(json['contact_id'].toString())
          : null,
      contactName: json['contact_name'],
      contactPhone: json['contact_phone'] ?? json['phone'] ?? '',
      contactCompany: json['contact_company'],
      productId: json['product_id'] != null
          ? int.tryParse(json['product_id'].toString())
          : null,
      productCode: json['product_code'],
      productTitle: json['product_title'],
      productImage: json['product_image'],
      productPrice: json['product_price'] != null
          ? double.tryParse(json['product_price'].toString())
          : null,
      collectionId: json['collection_id'] != null
          ? int.tryParse(json['collection_id'].toString())
          : null,
      collectionName: json['collection_name'],
      assignedToUserId: json['assigned_to_user_id'] != null
          ? int.tryParse(json['assigned_to_user_id'].toString())
          : null,
      assignedToUserName: json['assigned_to_user_name'],
      source: json['source'] ?? 'catalog',
      status: json['status'] ?? 'new',
      message: json['message'],
      quotedAmount: json['quoted_amount'] != null
          ? double.tryParse(json['quoted_amount'].toString())
          : null,
      nextFollowUpAt: json['next_follow_up_at'] != null
          ? DateTime.tryParse(json['next_follow_up_at'])
          : null,
      lastContactedAt: json['last_contacted_at'] != null
          ? DateTime.tryParse(json['last_contacted_at'])
          : null,
      lostReason: json['lost_reason'],
      activities: acts,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'contact_id': contactId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_company': contactCompany,
      'product_id': productId,
      'product_code': productCode,
      'product_title': productTitle,
      'product_image': productImage,
      'product_price': productPrice,
      'collection_id': collectionId,
      'collection_name': collectionName,
      'assigned_to_user_id': assignedToUserId,
      'assigned_to_user_name': assignedToUserName,
      'source': source,
      'status': status,
      'message': message,
      'quoted_amount': quotedAmount,
      'next_follow_up_at': nextFollowUpAt?.toIso8601String(),
      'last_contacted_at': lastContactedAt?.toIso8601String(),
      'lost_reason': lostReason,
      'activities': activities.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Inquiry copyWith({
    int? id,
    int? businessId,
    int? contactId,
    String? contactName,
    String? contactPhone,
    String? contactCompany,
    int? productId,
    String? productCode,
    String? productTitle,
    String? productImage,
    double? productPrice,
    int? collectionId,
    String? collectionName,
    int? assignedToUserId,
    String? assignedToUserName,
    String? source,
    String? status,
    String? message,
    double? quotedAmount,
    DateTime? nextFollowUpAt,
    DateTime? lastContactedAt,
    String? lostReason,
    List<InquiryActivity>? activities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inquiry(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactCompany: contactCompany ?? this.contactCompany,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      collectionId: collectionId ?? this.collectionId,
      collectionName: collectionName ?? this.collectionName,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      source: source ?? this.source,
      status: status ?? this.status,
      message: message ?? this.message,
      quotedAmount: quotedAmount ?? this.quotedAmount,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
      lostReason: lostReason ?? this.lostReason,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

