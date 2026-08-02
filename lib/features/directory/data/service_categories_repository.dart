import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:darjar/features/account/data/account_onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceSubcategory {
  const ServiceSubcategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  String localizedName(String languageCode) =>
      languageCode == 'ar' ? nameAr : nameEn;

  factory ServiceSubcategory.fromMap(Map<String, dynamic> data) {
    return ServiceSubcategory(
      id: data['id'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
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
  });

  final String id;
  final String shortNameAr;
  final String longNameAr;
  final String shortNameEn;
  final String longNameEn;
  final List<ServiceSubcategory> subcategories;
  final int order;

  String localizedShortName(String languageCode) =>
      languageCode == 'ar' ? shortNameAr : shortNameEn;

  String localizedLongName(String languageCode) =>
      languageCode == 'ar' ? longNameAr : longNameEn;

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
      subcategories: [
        for (final value in rawSubcategories)
          if (value is Map)
            ServiceSubcategory.fromMap(Map<String, dynamic>.from(value)),
      ],
      order: data['order'] as int? ?? 0,
    );
  }
}

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
