/// A user's saved Yelp search preferences (cuisines, dietary needs, price).
///
/// Replaces the legacy `preferences` collection, which stored pre-built URL
/// fragments. Here we store the raw selections and let [YelpService] build the
/// query, so the same preferences work for search, suggestions, and groups.
class UserPreferences {
  const UserPreferences({
    this.cuisines = const [],
    this.dietary = const [],
    this.prices = const [],
  });

  /// Yelp category aliases, e.g. `mexican`, `japanese`, `italian`.
  final List<String> cuisines;

  /// Dietary category aliases, e.g. `vegetarian`, `vegan`, `halal`.
  final List<String> dietary;

  /// Yelp price tiers as `1`..`4` (maps to `$`..`$$$$`).
  final List<String> prices;

  /// Everything Yelp treats as a `categories` filter.
  List<String> get allCategories => [...cuisines, ...dietary];

  /// Yelp `price` parameter, e.g. `1,2` — or null when unset.
  String? get priceParam => prices.isEmpty ? null : prices.join(',');

  bool get isEmpty => cuisines.isEmpty && dietary.isEmpty && prices.isEmpty;

  factory UserPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPreferences();
    List<String> asList(dynamic v) =>
        (v as List<dynamic>? ?? const []).map((e) => '$e').toList();
    return UserPreferences(
      cuisines: asList(map['cuisines']),
      dietary: asList(map['dietary']),
      prices: asList(map['prices']),
    );
  }

  Map<String, dynamic> toMap() => {
        'cuisines': cuisines,
        'dietary': dietary,
        'prices': prices,
      };

  UserPreferences copyWith({
    List<String>? cuisines,
    List<String>? dietary,
    List<String>? prices,
  }) =>
      UserPreferences(
        cuisines: cuisines ?? this.cuisines,
        dietary: dietary ?? this.dietary,
        prices: prices ?? this.prices,
      );

  /// The cuisine options offered in the UI: label → Yelp alias.
  static const cuisineOptions = <String, String>{
    'American': 'tradamerican',
    'Mexican': 'mexican',
    'Italian': 'italian',
    'Japanese': 'japanese',
    'Korean': 'korean',
    'Chinese': 'chinese',
    'Indian': 'indpak',
    'Thai': 'thai',
    'Mediterranean': 'mediterranean',
    'French': 'french',
  };

  static const dietaryOptions = <String, String>{
    'Vegetarian': 'vegetarian',
    'Vegan': 'vegan',
    'Halal': 'halal',
    'Pescetarian': 'seafood',
  };
}
