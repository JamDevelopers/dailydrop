import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/collection.dart';
import '../services/catalog_service.dart';
import '../services/product_code_service.dart';

class CatalogProvider extends ChangeNotifier {
  final CatalogService _service = CatalogService();

  List<Category> _categories = [];
  List<Product> _products = [];
  List<Collection> _collections = [];

  String _searchQuery = '';
  int? _selectedCategoryId;
  String? _selectedFabric;
  String? _selectedStockStatus;
  String? _selectedFestival;
  String? _selectedOccasion;
  bool _isTodayDropOnly = false;

  CatalogProvider() {
    _loadInitialData();
  }

  void _loadInitialData() {
    _categories = _service.getCategories();
    _products = _service.getProducts();
    _collections = _service.getCollections();
    notifyListeners();
  }

  List<Category> get categories => _categories;
  List<Collection> get collections => _collections;

  List<Collection> get todayLiveDrops {
    return _collections
        .where((c) => c.isToday && !c.isExpired && c.visibility != 'draft')
        .toList();
  }

  List<Product> get allProducts => _products;

  List<Product> get filteredProducts {
    return _products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedFabric != null &&
          _selectedFabric!.isNotEmpty &&
          p.fabric != _selectedFabric) {
        return false;
      }
      if (_selectedStockStatus != null &&
          _selectedStockStatus!.isNotEmpty &&
          p.stockStatus != _selectedStockStatus) {
        return false;
      }
      if (_selectedFestival != null &&
          _selectedFestival!.isNotEmpty &&
          p.festival != _selectedFestival) {
        return false;
      }
      if (_selectedOccasion != null &&
          _selectedOccasion!.isNotEmpty &&
          p.occasion != _selectedOccasion) {
        return false;
      }
      if (_isTodayDropOnly) {
        // Must belong to today's drop product list
        final todayProductIds = todayLiveDrops
            .expand((d) => d.productIds)
            .toSet();
        if (todayProductIds.isNotEmpty && !todayProductIds.contains(p.id)) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCode = p.productCode.toLowerCase().contains(q);
        final matchTitle = (p.title ?? '').toLowerCase().contains(q);
        final matchFabric = (p.fabric ?? '').toLowerCase().contains(q);
        final matchFestival = (p.festival ?? '').toLowerCase().contains(q);
        final matchOccasion = (p.occasion ?? '').toLowerCase().contains(q);
        if (!matchCode &&
            !matchTitle &&
            !matchFabric &&
            !matchFestival &&
            !matchOccasion) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedFabric => _selectedFabric;
  String? get selectedStockStatus => _selectedStockStatus;
  String? get selectedFestival => _selectedFestival;
  String? get selectedOccasion => _selectedOccasion;
  bool get isTodayDropOnly => _isTodayDropOnly;

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategoryFilter(int? catId) {
    _selectedCategoryId = catId;
    notifyListeners();
  }

  void setFabricFilter(String? fabric) {
    _selectedFabric = fabric;
    notifyListeners();
  }

  void setFestivalFilter(String? festival) {
    _selectedFestival = festival;
    notifyListeners();
  }

  void setOccasionFilter(String? occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  void setTodayDropFilter(bool onlyToday) {
    _isTodayDropOnly = onlyToday;
    notifyListeners();
  }

  void setStockStatusFilter(String? status) {
    _selectedStockStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedFabric = null;
    _selectedStockStatus = null;
    _selectedFestival = null;
    _selectedOccasion = null;
    _isTodayDropOnly = false;
    notifyListeners();
  }

  // Next design code helper
  String getNextDesignCode({String prefix = 'SR', DateTime? date}) {
    final existing = _products.map((p) => p.productCode).toList();
    final seq = ProductCodeService.getNextSequenceNumber(
      prefix: prefix,
      date: date,
      existingCodes: existing,
    );
    return ProductCodeService.generateDesignCode(
      prefix: prefix,
      date: date,
      sequenceNumber: seq,
    );
  }

  // Product CRUD
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
    final prod = _service.addProduct(
      businessId: businessId,
      productCode: productCode,
      title: title,
      categoryId: categoryId,
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
      imageUrls: imageUrls,
      colorVariants: colorVariants,
    );
    _products = _service.getProducts();
    notifyListeners();
    return prod;
  }

  // Batch Image Upload Workflow with auto sequential design codes
  List<Product> batchUploadProducts({
    required int businessId,
    required List<String> imageUrls,
    String prefix = 'SR',
    int? categoryId,
    String? fabric,
    String? occasion,
    String? festival,
    int setCount = 4,
    double? price,
    String? priceLabel,
    String? titlePrefix,
    int? collectionId,
  }) {
    final existingCodes = _products.map((p) => p.productCode).toList();
    final startSeq = ProductCodeService.getNextSequenceNumber(
      prefix: prefix,
      existingCodes: existingCodes,
    );

    final codes = ProductCodeService.generateBatchDesignCodes(
      prefix: prefix,
      startSequence: startSeq,
      count: imageUrls.length,
      existingCodes: existingCodes,
    );

    final newProducts = <Product>[];
    final newProductIds = <int>[];

    for (int i = 0; i < imageUrls.length; i++) {
      final code = codes[i];
      final title = titlePrefix != null && titlePrefix.isNotEmpty
          ? '$titlePrefix ($code)'
          : (fabric != null ? '$fabric Wholesale Saree' : 'Design $code');

      final prod = _service.addProduct(
        businessId: businessId,
        productCode: code,
        title: title,
        categoryId: categoryId,
        fabric: fabric,
        occasion: occasion,
        festival: festival,
        setCount: setCount,
        price: price,
        priceLabel: priceLabel,
        imageUrls: [imageUrls[i]],
      );
      newProducts.add(prod);
      newProductIds.add(prod.id);
    }

    // Attach to collection if specified
    if (collectionId != null) {
      final coll = _collections.where((c) => c.id == collectionId).firstOrNull;
      if (coll != null) {
        final updatedIds = List<int>.from(coll.productIds)
          ..addAll(newProductIds);
        final updatedProds = List<Product>.from(coll.products)
          ..addAll(newProducts);
        _service.updateCollection(
          coll.copyWith(productIds: updatedIds, products: updatedProds),
        );
      }
    }

    _products = _service.getProducts();
    _collections = _service.getCollections();
    notifyListeners();
    return newProducts;
  }

  void updateProduct(Product product) {
    _service.updateProduct(product);
    _products = _service.getProducts();
    notifyListeners();
  }

  void deleteProduct(int productId) {
    _service.deleteProduct(productId);
    _products = _service.getProducts();
    notifyListeners();
  }

  void updateProductStock(int productId, String newStatus) {
    _service.updateProductStock(productId, newStatus);
    _products = _service.getProducts();
    notifyListeners();
  }

  // Collections
  Collection createCollection({
    required int businessId,
    required String name,
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
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
    final coll = _service.createCollection(
      businessId: businessId,
      name: name,
      slug: slug,
      description: description,
      collectionDate: collectionDate,
      coverMediaUrl: coverMediaUrl,
      visibility: visibility,
      priceVisibility: priceVisibility,
      showInMainCatalog: showInMainCatalog,
      festival: festival,
      occasion: occasion,
      expiresAt: expiresAt,
      productIds: productIds,
    );
    _collections = _service.getCollections();
    notifyListeners();
    return coll;
  }

  void updateCollection(Collection coll) {
    _service.updateCollection(coll);
    _collections = _service.getCollections();
    notifyListeners();
  }

  void deleteCollection(int id) {
    _service.deleteCollection(id);
    _collections = _service.getCollections();
    notifyListeners();
  }

  void toggleCollectionPublish(int id) {
    _service.toggleCollectionPublish(id);
    _collections = _service.getCollections();
    notifyListeners();
  }
}
