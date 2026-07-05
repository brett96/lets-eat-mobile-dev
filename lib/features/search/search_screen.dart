import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../services/location_service.dart';
import '../../services/yelp_service.dart';
import '../restaurant/restaurant_details_screen.dart';
import 'restaurant_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _term = TextEditingController();
  String? _price;
  bool _openNow = true;
  Future<List<Restaurant>>? _results;

  @override
  void dispose() {
    _term.dispose();
    super.dispose();
  }

  void _search() {
    final yelp = context.read<YelpService>();
    final location = context.read<LocationService>();
    setState(() {
      _results = () async {
        final position = await location.getCurrentPosition();
        return yelp.search(
          latitude: position.latitude,
          longitude: position.longitude,
          term: _term.text.trim(),
          price: _price,
          openNow: _openNow,
          limit: 30,
        );
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _term,
                  decoration: InputDecoration(
                    hintText: 'Sushi, tacos, pizza…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final p in const ['\$', '\$\$', '\$\$\$'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(p),
                          selected: _price == '${p.length}',
                          onSelected: (sel) =>
                              setState(() => _price = sel ? '${p.length}' : null),
                        ),
                      ),
                    FilterChip(
                      label: const Text('Open now'),
                      selected: _openNow,
                      onSelected: (v) => setState(() => _openNow = v),
                    ),
                    const Spacer(),
                    FilledButton(onPressed: _search, child: const Text('Go')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _results == null
                ? const Center(child: Text('Search for restaurants near you.'))
                : FutureBuilder<List<Restaurant>>(
                    future: _results,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Something went wrong:\n${snapshot.error}',
                                textAlign: TextAlign.center),
                          ),
                        );
                      }
                      final restaurants = snapshot.data ?? const <Restaurant>[];
                      if (restaurants.isEmpty) {
                        return const Center(child: Text('No results found.'));
                      }
                      return ListView.builder(
                        itemCount: restaurants.length,
                        itemBuilder: (context, i) => RestaurantTile(
                          restaurant: restaurants[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RestaurantDetailsScreen(restaurant: restaurants[i]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
