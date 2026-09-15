import '../models/product.dart';
import '../models/category.dart';
import '../models/collection.dart';
import '../models/media_asset.dart';
import 'mock_data_service.dart';

class CatalogService {
  final List<Category> _categories = List.from(MockDataService.demoCategories);
  final List<Product> _products = List.from(MockDataService.demoProducts);
  final List<Collection> _collections = List.from(
    MockDataService.demoCollections,
  );

  List<Category> getCategories() => List.unmodifiable(_categories);
  List<Product> getProducts() => List.unmodifiable(_products);
  List<Collection> getCollections() => List.unmodifiable(_collections);

  // Products CRUD
  Product addProduct({
    required int businessId,
    required String productCode,
    String? title,
    int? categoryId,
    String? fabric,
    String? color,
    String? size,
    String? occasion,
    String? festival,
    int setCount = 4,
    String? setLabel,
    String? brand,
    double? price,
    String? priceLabel,
    double? costPrice,
    String stockStatus = 'available',
    int? stockQuantity,
    String? shortDescription,
    String? internalNotes,
    bool isPublic = true,
    List<String> imageUrls = const [],
    List<String> colorVariants = const [],
  }) {
    String? catName;
    if (categoryId != null) {
      final found = _categories.where((c) => c.id == categoryId);
      if (found.isNotEmpty) catName = found.first.name;
    }

    final newId = _products.isEmpty
        ? 101
        : _products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

    final mediaList = <MediaAsset>[];
    for (int i = 0; i < imageUrls.length; i++) {
      mediaList.add(
        MediaAsset(
          id: newId * 10 + i,
          businessId: businessId,
          productId: newId,
          originalPath: imageUrls[i],
          watermarkedPath: imageUrls[i],
          thumbnailPath: imageUrls[i],
          sortOrder: i,
        ),
      );
    }

    final product = Product(
      id: newId,
      businessId: businessId,
      categoryId: categoryId,
      categoryName: catName,
      createdByUserId: 1,
      productCode: productCode,
      title: title,
      fabric: fabric,
      color: color,
      size: size,
      occasion: occasion,
      festival: festival,
      setCount: setCount,
      setLabel: setLabel,
      brand: brand,
      price: price,
      priceLabel: priceLabel,
      costPrice: costPrice,
      stockStatus: stockStatus,
      stockQuantity: stockQuantity,
      shortDescription: shortDescription,
      internalNotes: internalNotes,
      isPublic: isPublic,
      media: mediaList,
      imageUrls: imageUrls,
      colorVariants: colorVariants,
    );

    _products.insert(0, product);
    return product;
  }

  void updateProduct(Product updated) {
    final idx = _products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _products[idx] = updated;
    }
  }

  void deleteProduct(int productId) {
    _products.removeWhere((p) => p.id == productId);
  }

  void updateProductStock(int productId, String newStockStatus) {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(stockStatus: newStockStatus);
    }
  }

  // Collections CRUD
  Collection createCollection({
    required int businessId,
    required String name,
    required String slug,
    String? description,
    DateTime? collectionDate,
    String? coverMediaUrl,
    String visibility = 'public',
    String priceVisibility = 'show',
    bool showInMainCatalog = true,
    String? festival,
    String? occasion,
    DateTime? expiresAt,
    List<int> productIds = const [],
  }) {
    final newId = _collections.isEmpty
        ? 201
        : _collections.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final shareToken = 'drop-${DateTime.now().millisecondsSinceEpoch}';

    final linkedProds = _products
        .where((p) => productIds.contains(p.id))
        .toList();

    final coll = Collection(
      id: newId,
      businessId: businessId,
      createdByUserId: 1,
      name: name,
      slug: slug,
      description: description,
      collectionDate: collectionDate ?? DateTime.now(),
      coverMediaUrl: coverMediaUrl,
      visibility: visibility,
      priceVisibility: priceVisibility,
      showInMainCatalog: showInMainCatalog,
      festival: festival,
      occasion: occasion,
      shareToken: shareToken,
      publishedAt: visibility == 'public' ? DateTime.now() : null,
      expiresAt: expiresAt,
      productIds: productIds,
      products: linkedProds,
    );

    _collections.insert(0, coll);
    return coll;
  }

  void updateCollection(Collection updated) {
    final idx = _collections.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _collections[idx] = updated;
    }
  }

  void deleteCollection(int id) {
    _collections.removeWhere((c) => c.id == id);
  }

  void toggleCollectionPublish(int id) {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final current = _collections[idx];
      final isPub = current.visibility == 'public';
      _collections[idx] = current.copyWith(
        visibility: isPub ? 'draft' : 'public',
        publishedAt: isPub ? null : DateTime.now(),
      );
    }
  }
}
