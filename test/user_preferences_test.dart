import 'package:flutter_test/flutter_test.dart';
import 'package:lets_eat/models/user_preferences.dart';

void main() {
  group('UserPreferences', () {
    test('combines cuisines and dietary into categories', () {
      const prefs = UserPreferences(
        cuisines: ['mexican', 'italian'],
        dietary: ['vegan'],
        prices: ['1', '2'],
      );
      expect(prefs.allCategories, ['mexican', 'italian', 'vegan']);
      expect(prefs.priceParam, '1,2');
      expect(prefs.isEmpty, isFalse);
    });

    test('empty preferences produce null price and empty categories', () {
      const prefs = UserPreferences();
      expect(prefs.priceParam, isNull);
      expect(prefs.allCategories, isEmpty);
      expect(prefs.isEmpty, isTrue);
    });

    test('round-trips through a map', () {
      const prefs = UserPreferences(cuisines: ['thai'], prices: ['3']);
      final restored = UserPreferences.fromMap(prefs.toMap());
      expect(restored.cuisines, ['thai']);
      expect(restored.prices, ['3']);
    });

    test('fromMap tolerates null and non-string entries', () {
      final prefs = UserPreferences.fromMap({
        'cuisines': [1, 'mexican'],
        'dietary': null,
      });
      expect(prefs.cuisines, ['1', 'mexican']);
      expect(prefs.dietary, isEmpty);
    });
  });
}
