import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/restaurant.dart';

/// The ONLY place in the app that talks to the Yelp Fusion API.
///
/// The API key is injected at build time:
///   flutter run --dart-define=YELP_API_KEY=xxxx
/// Never hardcode the key in source.
class YelpService {
  YelpService({http.Client? client, String? apiKey, Random? random})
      : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('YELP_API_KEY'),
        _random = random ?? Random();

  static const _base = 'api.yelp.com';
  final http.Client _client;
  final String _apiKey;
  final Random _random;

  Map<String, String> get _headers => {'Authorization': 'Bearer $_apiKey'};

  /// Search restaurants near [latitude]/[longitude].
  Future<List<Restaurant>> search({
    required double latitude,
    required double longitude,
    String? term,
    List<String>? categories,
    String? price,
    bool openNow = false,
    int limit = 20,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Yelp API key missing. Build with --dart-define=YELP_API_KEY=...',
      );
    }
    final uri = Uri.https(_base, '/v3/businesses/search', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'limit': '$limit',
      if (term != null && term.isNotEmpty) 'term': term,
      if (categories != null && categories.isNotEmpty)
        'categories': categories.join(','),
      if (price != null && price.isNotEmpty) 'price': price,
      if (openNow) 'open_now': 'true',
    });
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw YelpException(response.statusCode, response.body);
    }
    final map = json.decode(response.body) as Map<String, dynamic>;
    final businesses = map['businesses'] as List<dynamic>? ?? const [];
    return businesses
        .map((b) => Restaurant.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  /// Fetch full details for a single business by Yelp id.
  Future<Restaurant> getBusiness(String id) async {
    final uri = Uri.https(_base, '/v3/businesses/$id');
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw YelpException(response.statusCode, response.body);
    }
    return Restaurant.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// The signature feature: pick one open restaurant nearby at random.
  Future<Restaurant?> suggestRandom({
    required double latitude,
    required double longitude,
    List<String>? categories,
    String? price,
  }) async {
    final results = await search(
      latitude: latitude,
      longitude: longitude,
      categories: categories ?? const ['food', 'restaurants'],
      price: price,
      openNow: true,
      limit: 50,
    );
    if (results.isEmpty) return null;
    return results[_random.nextInt(results.length)];
  }
}

class YelpException implements Exception {
  YelpException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'Yelp API error $statusCode: $body';
}
