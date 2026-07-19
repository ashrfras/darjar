import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ListingType { offer, giveAway, request }

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.seller,
    required this.timeLabel,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.type,
  });

  final String id;
  final String seller;
  final String timeLabel;
  final String title;
  final String description;
  final String priceLabel;
  final ListingType type;
}

abstract interface class MarketplaceRepository {
  List<MarketplaceListing> getListings();

  MarketplaceListing? getListing(String id);

  MarketplaceListing createListing({
    required String title,
    required String description,
    required String priceLabel,
    required ListingType type,
  });
}

class MockMarketplaceRepository implements MarketplaceRepository {
  final List<MarketplaceListing> _listings = [
    const MarketplaceListing(
      id: 'office-chair',
      seller: 'أحمد من العمارة',
      timeLabel: 'منذ 35 دقيقة',
      title: 'كرسي مكتب للبيع',
      description: 'كرسي مكتب مريح بحالة ممتازة. متاح للمعاينة داخل الإقامة.',
      priceLabel: '250 درهم',
      type: ListingType.offer,
    ),
    const MarketplaceListing(
      id: 'books',
      seller: 'نادية بناني',
      timeLabel: 'منذ ساعتين',
      title: 'كتب أطفال للإهداء',
      description: 'مجموعة قصص عربية مناسبة للأطفال من 6 إلى 9 سنوات.',
      priceLabel: 'مجاناً',
      type: ListingType.giveAway,
    ),
  ];

  @override
  List<MarketplaceListing> getListings() => List.unmodifiable(_listings);

  @override
  MarketplaceListing? getListing(String id) {
    for (final listing in _listings) {
      if (listing.id == id) return listing;
    }
    return null;
  }

  @override
  MarketplaceListing createListing({
    required String title,
    required String description,
    required String priceLabel,
    required ListingType type,
  }) {
    final listing = MarketplaceListing(
      id: 'listing-${_listings.length + 1}',
      seller: 'أحمد من العمارة',
      timeLabel: 'الآن',
      title: title,
      description: description,
      priceLabel: priceLabel,
      type: type,
    );
    _listings.insert(0, listing);
    return listing;
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MockMarketplaceRepository(),
);

final marketplaceListingsProvider =
    NotifierProvider<MarketplaceController, List<MarketplaceListing>>(
      MarketplaceController.new,
    );

class MarketplaceController extends Notifier<List<MarketplaceListing>> {
  @override
  List<MarketplaceListing> build() {
    return ref.read(marketplaceRepositoryProvider).getListings();
  }

  MarketplaceListing? find(String id) {
    return ref.read(marketplaceRepositoryProvider).getListing(id);
  }

  MarketplaceListing create({
    required String title,
    required String description,
    required String priceLabel,
    required ListingType type,
  }) {
    final listing = ref
        .read(marketplaceRepositoryProvider)
        .createListing(
          title: title,
          description: description,
          priceLabel: priceLabel,
          type: type,
        );
    state = ref.read(marketplaceRepositoryProvider).getListings();
    return listing;
  }
}
