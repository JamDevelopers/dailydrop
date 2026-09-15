import 'package:flutter_test/flutter_test.dart';
import 'package:dailydrop/core/constants.dart';
import 'package:dailydrop/models/product.dart';
import 'package:dailydrop/models/collection.dart';
import 'package:dailydrop/providers/catalog_provider.dart';

void main() {
  group('TextileDrop Advanced Catalog Tests', () {
    test(
      'Product supports multi-images, set of 4, festivals and formatted price',
      () {
        final product = Product(
          id: 999,
          businessId: 1,
          createdByUserId: 1,
          productCode: 'SR-260915-013',
          title: 'Festive Georgette Saree',
          fabric: 'Dola Silk',
          color: 'Emerald Green',
          festival: 'Diwali Special',
          occasion: 'Festive',
          setCount: 4,
          price: 950,
          imageUrls: [
            'https://images.unsplash.com/photo-1?w=800',
            'https://images.unsplash.com/photo-2?w=800',
            'https://images.unsplash.com/photo-3?w=800',
            'https://images.unsplash.com/photo-4?w=800',
          ],
          colorVariants: ['Emerald Green', 'Wine', 'Rani Pink', 'Royal Blue'],
        );

        expect(product.hasMultipleImages, isTrue);
        expect(product.allImageUrls.length, equals(4));
        expect(product.formattedPrice, equals('₹950 / Pc (Set of 4)'));
        expect(product.festival, equals('Diwali Special'));
        expect(product.occasion, equals('Festive'));
      },
    );

    test('Collection expiry calculations and remaining time formatting', () {
      final activeDrop = Collection(
        id: 1001,
        businessId: 1,
        createdByUserId: 1,
        name: "Today's Daily Drop",
        slug: 'today-drop',
        shareToken: 'token_active',
        collectionDate: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 12, minutes: 30)),
      );

      expect(activeDrop.isExpired, isFalse);
      expect(activeDrop.isToday, isTrue);
      expect(activeDrop.remainingTimeFormatted, contains('12h'));

      final expiredDrop = Collection(
        id: 1002,
        businessId: 1,
        createdByUserId: 1,
        name: 'Past Drop',
        slug: 'past-drop',
        shareToken: 'token_expired',
        expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(expiredDrop.isExpired, isTrue);
      expect(expiredDrop.remainingTimeFormatted, equals('Expired'));
    });

    test(
      'CatalogProvider smart filtering for today drop, fabric, and festival',
      () {
        final provider = CatalogProvider();

        expect(provider.allProducts.isNotEmpty, isTrue);
        expect(provider.todayLiveDrops.isNotEmpty, isTrue);

        // Filter by Fabric
        provider.setFabricFilter('Dola Silk');
        final dolaProducts = provider.filteredProducts;
        for (final p in dolaProducts) {
          expect(p.fabric, equals('Dola Silk'));
        }

        // Filter by Festival
        provider.setFestivalFilter('Diwali Special');
        final diwaliProducts = provider.filteredProducts;
        for (final p in diwaliProducts) {
          expect(p.festival, equals('Diwali Special'));
        }

        // Filter by Today's Drop only
        provider.setTodayDropFilter(true);
        expect(provider.isTodayDropOnly, isTrue);

        // Clear filters
        provider.clearFilters();
        expect(provider.selectedFabric, isNull);
        expect(provider.selectedFestival, isNull);
        expect(provider.isTodayDropOnly, isFalse);
      },
    );

    test('Product expiry calculations and remaining time formatting', () {
      final activeProd = Product(
        id: 1005,
        businessId: 1,
        createdByUserId: 1,
        productCode: 'SR-260915-099',
        expiresAt: DateTime.now().add(const Duration(hours: 4, minutes: 15)),
      );

      expect(activeProd.isExpired, isFalse);
      expect(activeProd.remainingTimeFormatted, contains('4h'));

      final expiredProd = Product(
        id: 1006,
        businessId: 1,
        createdByUserId: 1,
        productCode: 'SR-260915-100',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(expiredProd.isExpired, isTrue);
      expect(expiredProd.remainingTimeFormatted, equals('Expired'));
    });

    test('Custom catalog creation with custom expiry duration', () {
      final provider = CatalogProvider();
      final prods = provider.allProducts.take(3).map((p) => p.id).toList();

      final customColl = provider.createCollection(
        businessId: 1,
        name: 'VIP Diwali Preview Selection',
        description: 'Exclusive 24-hour preview',
        visibility: 'private',
        showInMainCatalog: false,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        productIds: prods,
      );

      expect(customColl.visibility, equals('private'));
      expect(customColl.showInMainCatalog, isFalse);
      expect(customColl.productIds.length, equals(3));
      expect(customColl.isExpired, isFalse);
      expect(
        customColl.remainingTimeFormatted,
        anyOf(contains('23h'), contains('24h'), contains('1d')),
      );
    });

    test('Constants contain all Surat textile options', () {
      expect(AppConstants.occasions, contains('Festive'));
      expect(AppConstants.occasions, contains('Wedding / Bridal'));
      expect(AppConstants.festivals, contains('Diwali Special'));
      expect(AppConstants.festivals, contains('Navratri & Garba'));
      expect(AppConstants.sizes, contains('Free Size'));
      expect(AppConstants.setOptions, contains('Set of 4 (4 Colors)'));
    });
  });
}
