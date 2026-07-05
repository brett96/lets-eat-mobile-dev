import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../search/restaurant_tile.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    final users = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Restaurants')),
      body: uid == null
          ? const Center(child: Text('Sign in to see saved restaurants.'))
          : StreamBuilder<List<Restaurant>>(
              stream: users.savedRestaurants(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final saved = snapshot.data ?? const <Restaurant>[];
                if (saved.isEmpty) {
                  return const Center(child: Text('No saved restaurants yet.'));
                }
                return ListView.builder(
                  itemCount: saved.length,
                  itemBuilder: (context, i) => Dismissible(
                    key: ValueKey(saved[i].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        users.removeSavedRestaurant(uid, saved[i].id),
                    child: RestaurantTile(restaurant: saved[i]),
                  ),
                );
              },
            ),
    );
  }
}
