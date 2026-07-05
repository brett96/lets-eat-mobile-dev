import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/restaurant.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  const RestaurantDetailsScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open $uri')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final users = context.read<UserService>();
    final hasCoordinates =
        restaurant.latitude != null && restaurant.longitude != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Save',
            onPressed: () async {
              final uid = auth.currentUser?.uid;
              if (uid == null) return;
              await users.saveRestaurant(uid, restaurant);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${restaurant.name} saved!')));
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
            Image.network(restaurant.imageUrl!, height: 200, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text([
                  if (restaurant.rating != null)
                    '★ ${restaurant.rating} (${restaurant.reviewCount ?? 0} reviews)',
                  if (restaurant.price != null) restaurant.price!,
                ].join('  ·  ')),
                const SizedBox(height: 4),
                if (restaurant.fullAddress.isNotEmpty) Text(restaurant.fullAddress),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (restaurant.phone != null && restaurant.phone!.isNotEmpty)
                      ActionChip(
                        avatar: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        onPressed: () =>
                            _open(context, Uri.parse('tel:${restaurant.phone}')),
                      ),
                    if (restaurant.url != null)
                      ActionChip(
                        avatar: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View on Yelp'),
                        onPressed: () => _open(context, Uri.parse(restaurant.url!)),
                      ),
                    if (hasCoordinates)
                      ActionChip(
                        avatar: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        onPressed: () => _open(
                          context,
                          Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (hasCoordinates)
            SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(restaurant.latitude!, restaurant.longitude!),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId(restaurant.id),
                    position: LatLng(restaurant.latitude!, restaurant.longitude!),
                    infoWindow: InfoWindow(title: restaurant.name),
                  ),
                },
                liteModeEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
