import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/restaurant.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../services/yelp_service.dart';
import '../restaurant/restaurant_details_screen.dart';

/// The app's signature feature: pick one open restaurant nearby at random.
class InstantSuggestionScreen extends StatefulWidget {
  const InstantSuggestionScreen({super.key});

  @override
  State<InstantSuggestionScreen> createState() => _InstantSuggestionScreenState();
}

class _InstantSuggestionScreenState extends State<InstantSuggestionScreen> {
  Future<Restaurant?>? _suggestion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _roll());
  }

  void _roll() {
    final yelp = context.read<YelpService>();
    final location = context.read<LocationService>();
    final auth = context.read<AuthService>();
    final users = context.read<UserService>();
    setState(() {
      _suggestion = () async {
        final position = await location.getCurrentPosition();
        final pick = await yelp.suggestRandom(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        final uid = auth.currentUser?.uid;
        if (pick != null && uid != null) {
          await users.addToHistory(uid, pick);
        }
        return pick;
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instant Suggestion')),
      body: FutureBuilder<Restaurant?>(
        future: _suggestion,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not get a suggestion:\n${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final pick = snapshot.data;
          if (pick == null) {
            return const Center(child: Text('No open restaurants found nearby.'));
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How about…', style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (pick.imageUrl != null && pick.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(pick.imageUrl!, height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink()),
                          ),
                        const SizedBox(height: 12),
                        Text(pick.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text([
                          if (pick.rating != null) '★ ${pick.rating}',
                          if (pick.price != null) pick.price!,
                          pick.fullAddress,
                        ].where((s) => s.isNotEmpty).join('  ·  '),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View details'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RestaurantDetailsScreen(restaurant: pick)),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.casino),
                  label: const Text('Pick again'),
                  onPressed: _roll,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
