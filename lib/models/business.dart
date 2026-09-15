class BusinessSettings {
  final int businessId;
  final String catalogTitle;
  final String catalogDescription;
  final String defaultCurrency;
  final bool showPricesPublicly;
  final bool allowGuestInquiry;
  final bool watermarkEnabled;
  final String watermarkText;
  final String inquiryWhatsappTemplate;
  final String? termsUrl;
  final String? privacyUrl;

  BusinessSettings({
    required this.businessId,
    this.catalogTitle = 'Daily New Arrival Drops',
    this.catalogDescription = 'Surat wholesale & manufacturing direct catalog',
    this.defaultCurrency = 'INR',
    this.showPricesPublicly = true,
    this.allowGuestInquiry = true,
    this.watermarkEnabled = true,
    this.watermarkText = 'TextileDrop',
    this.inquiryWhatsappTemplate =
        'Hello, I am interested in Design {product_code} from {collection_name}. Please share price, video and available stock.',
    this.termsUrl,
    this.privacyUrl,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.tryParse(json['business_id']?.toString() ?? '1') ?? 1,
      catalogTitle: json['catalog_title'] ?? 'Daily New Arrival Drops',
      catalogDescription: json['catalog_description'] ??
          'Surat wholesale & manufacturing direct catalog',
      defaultCurrency: json['default_currency'] ?? 'INR',
      showPricesPublicly: json['show_prices_publicly'] == 1 ||
          json['show_prices_publicly'] == true,
      allowGuestInquiry: json['allow_guest_inquiry'] == 1 ||
          json['allow_guest_inquiry'] == true,
      watermarkEnabled: json['watermark_enabled'] == 1 ||
          json['watermark_enabled'] == true,
      watermarkText: json['watermark_text'] ?? 'TextileDrop',
      inquiryWhatsappTemplate: json['inquiry_whatsapp_template'] ??
          'Hello, I am interested in Design {product_code} from {collection_name}. Please share price, video and available stock.',
      termsUrl: json['terms_url'],
      privacyUrl: json['privacy_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'catalog_title': catalogTitle,
      'catalog_description': catalogDescription,
      'default_currency': defaultCurrency,
      'show_prices_publicly': showPricesPublicly ? 1 : 0,
      'allow_guest_inquiry': allowGuestInquiry ? 1 : 0,
      'watermark_enabled': watermarkEnabled ? 1 : 0,
      'watermark_text': watermarkText,
      'inquiry_whatsapp_template': inquiryWhatsappTemplate,
      'terms_url': termsUrl,
      'privacy_url': privacyUrl,
    };
  }

  BusinessSettings copyWith({
    int? businessId,
    String? catalogTitle,
    String? catalogDescription,
    String? defaultCurrency,
    bool? showPricesPublicly,
    bool? allowGuestInquiry,
    bool? watermarkEnabled,
    String? watermarkText,
    String? inquiryWhatsappTemplate,
  }) {
    return BusinessSettings(
      businessId: businessId ?? this.businessId,
      catalogTitle: catalogTitle ?? this.catalogTitle,
      catalogDescription: catalogDescription ?? this.catalogDescription,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      showPricesPublicly: showPricesPublicly ?? this.showPricesPublicly,
      allowGuestInquiry: allowGuestInquiry ?? this.allowGuestInquiry,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      watermarkText: watermarkText ?? this.watermarkText,
      inquiryWhatsappTemplate:
          inquiryWhatsappTemplate ?? this.inquiryWhatsappTemplate,
    );
  }
}

class Business {
  final int id;
  final String publicId;
  final int? planId;
  final String name;
  final String? legalName;
  final String slug;
  final String businessType;
  final String? ownerName;
  final String? phone;
  final String whatsappNumber;
  final String? email;
  final String? addressLine1;
  final String city;
  final String state;
  final String country;
  final String? pincode;
  final String? gstNumber;
  final String? logoPath;
  final String primaryColor;
  final String subscriptionStatus; // trial, active, past_due, suspended, cancelled
  final DateTime? trialEndsAt;
  final DateTime? subscriptionEndsAt;
  final int storageUsedBytes;
  final bool isActive;
  final BusinessSettings settings;

  Business({
    required this.id,
    required this.publicId,
    this.planId,
    required this.name,
    this.legalName,
    required this.slug,
    this.businessType = 'textile_wholesaler',
    this.ownerName,
    this.phone,
    required this.whatsappNumber,
    this.email,
    this.addressLine1,
    this.city = 'Surat',
    this.state = 'Gujarat',
    this.country = 'India',
    this.pincode,
    this.gstNumber,
    this.logoPath,
    this.primaryColor = '#0B8F5B',
    this.subscriptionStatus = 'active',
    this.trialEndsAt,
    this.subscriptionEndsAt,
    this.storageUsedBytes = 0,
    this.isActive = true,
    required this.settings,
  });

  String get storageUsedMb => (storageUsedBytes / (1024 * 1024)).toStringAsFixed(1);

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      publicId: json['public_id'] ?? 'biz_${json['id']}',
      planId: json['plan_id'] != null
          ? int.tryParse(json['plan_id'].toString())
          : null,
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      slug: json['slug'] ?? '',
      businessType: json['business_type'] ?? 'textile_wholesaler',
      ownerName: json['owner_name'],
      phone: json['phone'],
      whatsappNumber: json['whatsapp_number'] ?? '',
      email: json['email'],
      addressLine1: json['address_line1'],
      city: json['city'] ?? 'Surat',
      state: json['state'] ?? 'Gujarat',
      country: json['country'] ?? 'India',
      pincode: json['pincode'],
      gstNumber: json['gst_number'],
      logoPath: json['logo_path'],
      primaryColor: json['primary_color'] ?? '#0B8F5B',
      subscriptionStatus: json['subscription_status'] ?? 'active',
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at'])
          : null,
      subscriptionEndsAt: json['subscription_ends_at'] != null
          ? DateTime.tryParse(json['subscription_ends_at'])
          : null,
      storageUsedBytes: json['storage_used_bytes'] != null
          ? int.tryParse(json['storage_used_bytes'].toString()) ?? 0
          : 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      settings: json['settings'] != null
          ? BusinessSettings.fromJson(json['settings'])
          : BusinessSettings(businessId: json['id'] is int ? json['id'] : 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'public_id': publicId,
      'plan_id': planId,
      'name': name,
      'legal_name': legalName,
      'slug': slug,
      'business_type': businessType,
      'owner_name': ownerName,
      'phone': phone,
      'whatsapp_number': whatsappNumber,
      'email': email,
      'address_line1': addressLine1,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'gst_number': gstNumber,
      'logo_path': logoPath,
      'primary_color': primaryColor,
      'subscription_status': subscriptionStatus,
      'storage_used_bytes': storageUsedBytes,
      'is_active': isActive ? 1 : 0,
      'settings': settings.toJson(),
    };
  }

  Business copyWith({
    int? id,
    String? publicId,
    int? planId,
    String? name,
    String? legalName,
    String? slug,
    String? businessType,
    String? ownerName,
    String? phone,
    String? whatsappNumber,
    String? email,
    String? addressLine1,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? gstNumber,
    String? logoPath,
    String? primaryColor,
    String? subscriptionStatus,
    int? storageUsedBytes,
    bool? isActive,
    BusinessSettings? settings,
  }) {
    return Business(
      id: id ?? this.id,
      publicId: publicId ?? this.publicId,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      slug: slug ?? this.slug,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      addressLine1: addressLine1 ?? this.addressLine1,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      gstNumber: gstNumber ?? this.gstNumber,
      logoPath: logoPath ?? this.logoPath,
      primaryColor: primaryColor ?? this.primaryColor,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
    );
  }
}

