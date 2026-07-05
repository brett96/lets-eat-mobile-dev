import 'package:flutter_test/flutter_test.dart';
import 'package:lets_eat/models/restaurant.dart';

void main() {
  group('Restaurant.fromJson', () {
    test('parses a full Yelp business payload', () {
      final restaurant = Restaurant.fromJson({
        'id': 'abc123',
        'name': 'Taco Town',
        'rating': 4.5,
        'price': r'$$',
        'phone': '+15625551234',
        'coordinates': {'latitude': 33.78, 'longitude': -118.11},
        'distance': 1609.344,
        'alias': 'taco-town-long-beach',
        'is_closed': false,
        'review_count': 321,
        'url': 'https://yelp.com/biz/taco-town',
        'image_url': 'https://img.yelp.com/taco.jpg',
        'location': {
          'address1': '123 Main St',
          'city': 'Long Beach',
          'state': 'CA',
          'country': 'US',
          'zip_code': '90802',
        },
      });

      expect(restaurant.id, 'abc123');
      expect(restaurant.name, 'Taco Town');
      expect(restaurant.rating, 4.5);
      expect(restaurant.latitude, 33.78);
      expect(restaurant.isClosed, false);
      expect(restaurant.reviewCount, 321);
      expect(restaurant.distanceMiles, closeTo(1.0, 0.001));
      expect(restaurant.fullAddress, '123 Main St, Long Beach, CA, 90802');
    });

    test('tolerates missing optional fields', () {
      final restaurant = Restaurant.fromJson({'id': 'x', 'name': 'Mystery Diner'});
      expect(restaurant.id, 'x');
      expect(restaurant.rating, isNull);
      expect(restaurant.fullAddress, '');
      expect(restaurant.distanceMiles, 0);
    });

    test('parses integer rating as double', () {
      final restaurant =
          Restaurant.fromJson({'id': 'x', 'name': 'Y', 'rating': 4});
      expect(restaurant.rating, 4.0);
    });
  });

  test('toFirestore keeps only the persisted subset', () {
    const restaurant = Restaurant(
        id: 'abc', name: 'Taco Town', rating: 4.5, price: r'$$');
    final map = restaurant.toFirestore();
    expect(map.keys,
        containsAll(['id', 'name', 'rating', 'price', 'imageUrl', 'address']));
    expect(map.containsKey('phone'), isFalse);
  });
}
