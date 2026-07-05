import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lets_eat/services/yelp_service.dart';

const _business = {
  'id': 'biz1',
  'name': 'Pho Real',
  'rating': 4.0,
  'coordinates': {'latitude': 1.0, 'longitude': 2.0},
  'location': {'address1': '1 A St', 'city': 'LB', 'state': 'CA', 'zip_code': '90000'},
};

void main() {
  test('search builds the right request and parses results', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(json.encode({'businesses': [_business]}), 200);
    });
    final yelp = YelpService(client: client, apiKey: 'test-key');

    final results = await yelp.search(
      latitude: 33.78,
      longitude: -118.11,
      term: 'pho',
      price: '2',
      openNow: true,
    );

    expect(captured.url.host, 'api.yelp.com');
    expect(captured.url.path, '/v3/businesses/search');
    expect(captured.url.queryParameters['term'], 'pho');
    expect(captured.url.queryParameters['price'], '2');
    expect(captured.url.queryParameters['open_now'], 'true');
    expect(captured.headers['Authorization'], 'Bearer test-key');
    expect(results, hasLength(1));
    expect(results.first.name, 'Pho Real');
  });

  test('search throws YelpException on non-2xx', () async {
    final client = MockClient((_) async => http.Response('nope', 401));
    final yelp = YelpService(client: client, apiKey: 'bad');
    expect(
      () => yelp.search(latitude: 0, longitude: 0),
      throwsA(isA<YelpException>()),
    );
  });

  test('search throws StateError when no API key is configured', () {
    final yelp = YelpService(client: MockClient((_) async => http.Response('', 200)), apiKey: '');
    expect(() => yelp.search(latitude: 0, longitude: 0), throwsStateError);
  });

  test('suggestRandom returns one open restaurant deterministically', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['open_now'], 'true');
      return http.Response(
          json.encode({
            'businesses': [
              _business,
              {..._business, 'id': 'biz2', 'name': 'Burger Barn'},
            ]
          }),
          200);
    });
    final yelp = YelpService(client: client, apiKey: 'k', random: Random(1));

    final pick = await yelp.suggestRandom(latitude: 1, longitude: 2);
    expect(pick, isNotNull);
    expect(['Pho Real', 'Burger Barn'], contains(pick!.name));
  });

  test('suggestRandom returns null when nothing is open', () async {
    final client =
        MockClient((_) async => http.Response(json.encode({'businesses': []}), 200));
    final yelp = YelpService(client: client, apiKey: 'k');
    expect(await yelp.suggestRandom(latitude: 1, longitude: 2), isNull);
  });

  test('getBusiness fetches details by id', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v3/businesses/biz1');
      return http.Response(json.encode(_business), 200);
    });
    final yelp = YelpService(client: client, apiKey: 'k');
    final restaurant = await yelp.getBusiness('biz1');
    expect(restaurant.name, 'Pho Real');
  });
}
