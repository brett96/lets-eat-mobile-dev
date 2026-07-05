import 'package:flutter/material.dart';

import '../../models/restaurant.dart';

class RestaurantTile extends StatelessWidget {
  const RestaurantTile({super.key, required this.restaurant, this.onTap});

  final Restaurant restaurant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                restaurant.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.restaurant, size: 40),
              ),
            )
          : const Icon(Icons.restaurant, size: 40),
      title: Text(restaurant.name),
      subtitle: Text(
        [
          if (restaurant.rating != null) '★ ${restaurant.rating}',
          if (restaurant.price != null) restaurant.price!,
          if (restaurant.distanceMeters != null)
            '${restaurant.distanceMiles.toStringAsFixed(1)} mi',
        ].join('  ·  '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
