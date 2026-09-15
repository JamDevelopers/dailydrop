class MediaAsset {
  final int id;
  final int businessId;
  final int? productId;
  final int? collectionId;
  final String mediaType; // 'image', 'video', 'pdf'
  final String? originalFilename;
  final String originalPath;
  final String? optimizedPath;
  final String? thumbnailPath;
  final String? watermarkedPath;
  final String mimeType;
  final int fileSizeBytes;
  final String processingStatus; // 'pending', 'processing', 'ready', 'failed'
  final int sortOrder;

  MediaAsset({
    required this.id,
    required this.businessId,
    this.productId,
    this.collectionId,
    this.mediaType = 'image',
    this.originalFilename,
    required this.originalPath,
    this.optimizedPath,
    this.thumbnailPath,
    this.watermarkedPath,
    this.mimeType = 'image/jpeg',
    this.fileSizeBytes = 0,
    this.processingStatus = 'ready',
    this.sortOrder = 0,
  });

  String get displayUrl => watermarkedPath ?? optimizedPath ?? originalPath;
  String get thumbUrl => thumbnailPath ?? displayUrl;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      businessId: json['business_id'] is int
          ? json['business_id']
          : int.parse(json['business_id'].toString()),
      productId: json['product_id'] != null
          ? int.tryParse(json['product_id'].toString())
          : null,
      collectionId: json['collection_id'] != null
          ? int.tryParse(json['collection_id'].toString())
          : null,
      mediaType: json['media_type'] ?? 'image',
      originalFilename: json['original_filename'],
      originalPath: json['original_path'] ?? '',
      optimizedPath: json['optimized_path'],
      thumbnailPath: json['thumbnail_path'],
      watermarkedPath: json['watermarked_path'],
      mimeType: json['mime_type'] ?? 'image/jpeg',
      fileSizeBytes: json['file_size_bytes'] != null
          ? int.tryParse(json['file_size_bytes'].toString()) ?? 0
          : 0,
      processingStatus: json['processing_status'] ?? 'ready',
      sortOrder: json['sort_order'] != null
          ? int.tryParse(json['sort_order'].toString()) ?? 0
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'product_id': productId,
      'collection_id': collectionId,
      'media_type': mediaType,
      'original_filename': originalFilename,
      'original_path': originalPath,
      'optimized_path': optimizedPath,
      'thumbnail_path': thumbnailPath,
      'watermarked_path': watermarkedPath,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'processing_status': processingStatus,
      'sort_order': sortOrder,
    };
  }
}

