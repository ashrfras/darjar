import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Firestore seed contains the complete ordered service catalog',
    () async {
      final source = File('backend/notifications/service_categories.json');
      final categories =
          jsonDecode(await source.readAsString()) as List<dynamic>;

      expect(categories.map((category) => category['shortNameAr']), [
        'الصيانة',
        'التجهيزات',
        'النظافة',
        'النقل',
        'الأسرة',
        'خدمات أخرى',
      ]);
      expect(categories.map((category) => category['longNameAr']), [
        'صيانة المنزل',
        'الأجهزة والتجهيزات',
        'النظافة والعناية',
        'النقل والتوصيل',
        'خدمات شخصية وعائلية',
        'خدمات أخرى',
      ]);
      expect(categories.map((category) => category['subcategories'].length), [
        8,
        6,
        6,
        5,
        6,
        7,
      ]);
      for (final category in categories) {
        expect(
          category['subcategoryIds'],
          category['subcategories']
              .map((subcategory) => subcategory['id'])
              .toList(),
        );
      }
    },
  );
}
