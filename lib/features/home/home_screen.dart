import 'package:flutter/material.dart';

import '../account/account_screen.dart';
import '../delivery/delivery_screen.dart';
import '../friends/friends_screen.dart';
import '../groups/groups_screen.dart';
import '../preferences/preferences_screen.dart';
import '../saved/saved_screen.dart';
import '../search/search_screen.dart';
import '../suggestion/instant_suggestion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Let's Eat!"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.asset('assets/ACTUALLOGO.png', height: 140,
              errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(height: 16),
          _HomeCard(
            icon: Icons.casino,
            title: 'Instant Suggestion',
            subtitle: "Can't decide? Let us pick an open spot near you.",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InstantSuggestionScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.search,
            title: 'Search Restaurants',
            subtitle: 'Search by cuisine, name, or craving.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.delivery_dining,
            title: 'Delivery',
            subtitle: 'Find spots that deliver to you.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeliveryScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.groups,
            title: 'Groups',
            subtitle: 'Decide together — pool cuisines, vote, and chat.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GroupsScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.people,
            title: 'Friends',
            subtitle: 'Add friends by username.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.favorite,
            title: 'Saved Restaurants',
            subtitle: 'Your favorites, all in one place.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavedScreen()),
            ),
          ),
          _HomeCard(
            icon: Icons.tune,
            title: 'My Preferences',
            subtitle: 'Set default cuisines, dietary needs, and price.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PreferencesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
