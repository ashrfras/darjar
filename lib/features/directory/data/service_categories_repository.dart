import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceSubcategory {
  const ServiceSubcategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.nameZgh,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? nameZgh;

  String localizedName(String languageCode) => switch (languageCode) {
    'ar' => nameAr,
    'zgh' => nameZgh ?? _serviceSubcategoryNamesZgh[id] ?? nameAr,
    _ => nameEn,
  };

  factory ServiceSubcategory.fromMap(Map<String, dynamic> data) {
    return ServiceSubcategory(
      id: data['id'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      nameZgh: data['nameZgh'] as String?,
    );
  }
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.shortNameAr,
    required this.longNameAr,
    required this.shortNameEn,
    required this.longNameEn,
    required this.subcategories,
    required this.order,
    this.shortNameZgh,
    this.longNameZgh,
  });

  final String id;
  final String shortNameAr;
  final String longNameAr;
  final String shortNameEn;
  final String longNameEn;
  final String? shortNameZgh;
  final String? longNameZgh;
  final List<ServiceSubcategory> subcategories;
  final int order;

  String localizedShortName(String languageCode) => switch (languageCode) {
    'ar' => shortNameAr,
    'zgh' => shortNameZgh ?? _serviceCategoryNamesZgh[id]?.$1 ?? shortNameAr,
    _ => shortNameEn,
  };

  String localizedLongName(String languageCode) => switch (languageCode) {
    'ar' => longNameAr,
    'zgh' => longNameZgh ?? _serviceCategoryNamesZgh[id]?.$2 ?? longNameAr,
    _ => longNameEn,
  };

  factory ServiceCategory.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawSubcategories = data['subcategories'] as List? ?? const [];
    return ServiceCategory(
      id: document.id,
      shortNameAr: data['shortNameAr'] as String? ?? '',
      longNameAr: data['longNameAr'] as String? ?? '',
      shortNameEn: data['shortNameEn'] as String? ?? '',
      longNameEn: data['longNameEn'] as String? ?? '',
      shortNameZgh: data['shortNameZgh'] as String?,
      longNameZgh: data['longNameZgh'] as String?,
      subcategories: [
        for (final value in rawSubcategories)
          if (value is Map)
            ServiceSubcategory.fromMap(Map<String, dynamic>.from(value)),
      ],
      order: data['order'] as int? ?? 0,
    );
  }
}

const _serviceCategoryNamesZgh = <String, (String, String)>{
  'home-maintenance': ('ⴰⵙⴻⴳⴳⴻⵎ', 'ⴰⵙⴻⴳⴳⴻⵎ ⵏ ⵓⵅⵅⴰⵎ'),
  'appliances-equipment': ('ⵉⵎⴰⵙⵙⴻⵏ', 'ⵉⴱⴻⵏⴽⴰⵏ ⴷ ⵉⵎⴰⵙⵙⴻⵏ'),
  'cleaning-care': ('ⴰⵙⵉⵣⴷⴻⴳ', 'ⴰⵙⵉⵣⴷⴻⴳ ⴷ ⵓⵄⴻⵢⵢⴻⵏ'),
  'transport-delivery': ('ⴰⵎⵙⴰⵡⴰⴹ', 'ⴰⵎⵙⴰⵡⴰⴹ ⴷ ⵓⵙⵉⵡⴻⴹ'),
  'personal-family': ('ⵜⴰⵡⴰⵛⵓⵍⵜ', 'ⵉⵎⴻⵥⵍⴰ ⵓⴷⵎⴰⵡⴰⵏⴻⵏ ⴷ ⵏ ⵜⵡⴰⵛⵓⵍⵜ'),
  'other-services': ('ⵉⵎⴻⵥⵍⴰ ⵏⵏⵉⴹⴻⵏ', 'ⵉⵎⴻⵥⵍⴰ ⵏⵏⵉⴹⴻⵏ'),
};

const _serviceSubcategoryNamesZgh = <String, String>{
  'plumber': 'ⴰⵎⵙⴻⴳⴳⴻⵎ ⵏ ⵡⴰⵎⴰⵏ',
  'electrician': 'ⴰⵎⴻⵙⵏⴰⵡ ⵏ ⵜⴰⴼⴰⵜ',
  'painter': 'ⴰⵎⴻⵙⵍⴰⵢ',
  'carpenter': 'ⴰⵏⴻⵊⵊⴰⵔ',
  'plasterer': 'ⴰⴳⴻⴱⴱⴰⵚ',
  'aluminum-glass': 'ⴰⵍⵓⵎⵉⵏⵢⵓⵎ ⴷ ⵓⵣⵓⵊⴰⵊ',
  'lock-repair': 'ⴰⵙⴻⴳⴳⴻⵎ ⵏ ⵜⵇⴻⴼⴼⴰⵍⵉⵏ',
  'curtain-installation': 'ⴰⵙⴱⴻⴷⴷ ⵏ ⵉⵙⴻⴷⴷⴰⵔⴻⵏ',
  'home-appliance-repair': 'ⴰⵙⴻⴳⴳⴻⵎ ⵏ ⵉⴱⴻⵏⴽⴰⵏ ⵏ ⵓⵅⵅⴰⵎ',
  'cooling-air-conditioning': 'ⴰⵙⵎⵉⴹⵉ ⴷ ⵓⵙⵏⴻⴼⵙ',
  'tv-repair': 'ⴰⵙⴻⴳⴳⴻⵎ ⵏ ⵜⵉⵍⵉⴼⵉⵣⵢⵓⵏ',
  'internet-networks': 'ⴰⵏⵜⵉⵔⵏⵉⵜ ⴷ ⵉⵣⴻⴹⵡⴰⵏ',
  'security-cameras': 'ⵜⵉⴽⴰⵎⵉⵔⴰⵜⵉⵏ ⵏ ⵓⵄⴰⵙⵙⴰ',
  'satellite-dish-installation': 'ⴰⵙⴱⴻⴷⴷ ⵏ ⵉⵎⴻⵇⵇⵔⴰⵏⴻⵏ ⵏ ⵓⴳⴻⵏⵏⵉ',
  'home-cleaning': 'ⴰⵙⵉⵣⴷⴻⴳ ⵏ ⵉⵅⵅⴰⵎⴻⵏ',
  'building-cleaning': 'ⴰⵙⵉⵣⴷⴻⴳ ⵏ ⵜⵣⴻⴷⵖⵉⵏ',
  'carpet-upholstery-cleaning': 'ⴰⵙⵉⵣⴷⴻⴳ ⵏ ⵉⴼⴻⵔⵔⴰⵛⴻⵏ',
  'pest-control': 'ⴰⵎⴻⵏⵖⵉ ⵎⴳⴰⵍ ⵉⵎⵉⴽⵉⵡⴻⵏ',
  'gardening': 'ⵜⴰⴱⵀⵉⵔⵜ',
  'pool-care': 'ⴰⵄⴻⵢⵢⴻⵏ ⵏ ⵉⵎⴻⴹⵢⴰⵙⴻⵏ',
  'furniture-moving': 'ⴰⵎⵙⴰⵡⴰⴹ ⵏ ⵉⵎⴻⵙⵙⵉⵔⴻⵏ',
  'goods-transport': 'ⴰⵎⵙⴰⵡⴰⴹ ⵏ ⵙⵙⵍⴰⵄⴰ',
  'order-delivery': 'ⴰⵙⵉⵡⴻⴹ ⵏ ⵉⵙⵓⵜⴻⵔ',
  'transport-vehicle-rental': 'ⴰⴽⴻⵔⵔⵓ ⵏ ⵉⵎⴻⵏⵖⵉⵢⴻⵏ ⵏ ⵓⵎⵙⴰⵡⴰⴹ',
  'moving-assistance': 'ⵜⴰⵍⵍⴻⵍⵜ ⴷⴻⴳ ⵓⵎⵙⴰⵡⴰⴹ',
  'babysitter': 'ⵜⴰⵎⵔⴰⴱⴱⵉⵜ ⵏ ⵉⴳⴻⵔⴷⴰⵏ',
  'home-nurse': 'ⵜⴰⵎⵙⴻⵊⵊⵉⵜ ⵏ ⵓⵅⵅⴰⵎ',
  'domestic-helper': 'ⵜⴰⵍⵍⴰⵍⵜ ⵏ ⵓⵅⵅⴰⵎ',
  'elderly-care': 'ⴰⵄⴻⵢⵢⴻⵏ ⵏ ⵉⵎⵖⴰⵔⴻⵏ',
  'private-tutor': 'ⴰⵙⴻⵍⵎⴰⴷ ⵓⴷⵎⴰⵡⴰⵏ',
  'school-transport': 'ⴰⵎⵙⴰⵡⴰⴹ ⴰⵖⴻⵔⴱⴰⵣ',
  'syndic-office': 'ⵜⴰⵏⴰⵔⵉⵜ ⵏ ⵙⵙⴰⵏⴷⵉⴽ',
  'security-guard': 'ⴰⵄⴻⵙⵙⴰⵙ',
  'accountant': 'ⴰⵎⵙⵉⴹⴻⵏ',
  'photographer': 'ⴰⵎⴻⵙⵙⴰⵡⴰⵍ ⵏ ⵜⵡⵍⴰⴼⵉⵏ',
  'lawyer-notary': 'ⴰⴱⵓⴳⴰⵟⵓ ⵏⴻⵖ ⴰⵎⵓⵙⵙⵏⴰⵡ',
  'design-printing': 'ⴰⵙⵏⵉⵔⴻⵎ ⴷ ⵜⵙⵉⴳⴳⴻⵣⵜ',
  'it-services': 'ⵉⵎⴻⵥⵍⴰ ⵏ ⵜⵉⴽⵏⵓⵍⵓⵊⵉⵜ',
};

abstract interface class ServiceCategoriesRepository {
  Stream<List<ServiceCategory>> watchCategories();
}

class FirestoreServiceCategoriesRepository
    implements ServiceCategoriesRepository {
  FirestoreServiceCategoriesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<ServiceCategory>> watchCategories() {
    return _firestore.collection('serviceCategories').snapshots().map((event) {
      final categories = event.docs.map(ServiceCategory.fromDocument).toList();
      categories.sort((a, b) => a.order.compareTo(b.order));
      return categories;
    });
  }
}

final serviceCategoriesRepositoryProvider =
    Provider<ServiceCategoriesRepository>(
      (ref) => FirestoreServiceCategoriesRepository(
        ref.watch(firebaseFirestoreProvider),
      ),
    );

final serviceCategoriesProvider = StreamProvider<List<ServiceCategory>>(
  (ref) => ref.watch(serviceCategoriesRepositoryProvider).watchCategories(),
);
