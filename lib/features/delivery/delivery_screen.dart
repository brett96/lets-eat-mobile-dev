import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/restaurant.dart';
import '../../services/location_service.dart';
import '../../services/yelp_service.dart';
import '../restaurant/restaurant_details_screen.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  Future<List<Restaurant>>? _results;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final yelp = context.read<YelpService>();
    final location = context.read<LocationService>();
    setState(() {
      _results = () async {
        final position = await location.getCurrentPosition();
        return yelp.deliverySearch(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }();
    });
  }

  Future<void> _openYelp(Restaurant r) async {
    if (r.url == null) return;
    final uri = Uri.parse(r.url!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open Yelp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: _results == null
          ? const Center(child: CircularProgressIndicator())
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
                      child: Text('Could not load delivery options:\n${snapshot.error}',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                final restaurants = snapshot.data ?? const <Restaurant>[];
                if (restaurants.isEmpty) {
                  return const Center(
                      child: Text('No delivery options found near you.'));
                }
                return ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, i) {
                    final r = restaurants[i];
                    return ListTile(
                      leading: r.imageUrl != null && r.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(r.imageUrl!,
                                  width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.restaurant, size: 40)),
                            )
                          : const Icon(Icons.restaurant, size: 40),
                      title: Text(r.name),
                      subtitle: Text([
                        if (r.rating != null) '★ ${r.rating}',
                        if (r.price != null) r.price!,
                      ].join('  ·  ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delivery_dining),
                        tooltip: 'Order on Yelp',
                        onPressed: () => _openYelp(r),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              RestaurantDetailsScreen(restaurant: r))),
                    );
                  },
                );
              },
            ),
    );
  }
}
