import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../models/restaurant.dart';
import '../../models/user_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../services/location_service.dart';
import '../../services/yelp_service.dart';
import '../restaurant/restaurant_details_screen.dart';
import 'group_chat_screen.dart';

/// Group hub: members contribute cuisine categories, generate candidate
/// restaurants, vote, and open the chat. The winning restaurant becomes the
/// group's result.
class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  Future<void> _addCategories(BuildContext context) async {
    final selected = <String>{};
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add cuisines to the group'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              children: UserPreferences.cuisineOptions.entries.map((e) {
                return FilterChip(
                  label: Text(e.key),
                  selected: selected.contains(e.value),
                  onSelected: (v) => setState(() =>
                      v ? selected.add(e.value) : selected.remove(e.value)),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    if (result == true && selected.isNotEmpty && context.mounted) {
      await context.read<GroupService>().addCategories(groupId, selected.toList());
    }
  }

  Future<void> _generateCandidates(BuildContext context, Group group) async {
    final messenger = ScaffoldMessenger.of(context);
    final location = context.read<LocationService>();
    final yelp = context.read<YelpService>();
    try {
      final position = await location.getCurrentPosition();
      final results = await yelp.search(
        latitude: position.latitude,
        longitude: position.longitude,
        categories:
            group.categories.isEmpty ? const ['restaurants'] : group.categories,
        openNow: true,
        limit: 10,
      );
      if (!context.mounted) return;
      if (results.isEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No restaurants matched. Adjust cuisines.')));
        return;
      }
      await _showVoteSheet(context, results);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _showVoteSheet(BuildContext context, List<Restaurant> candidates) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final groups = context.read<GroupService>();
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Vote for a restaurant',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final r in candidates)
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(r.name),
              subtitle: Text([
                if (r.rating != null) '★ ${r.rating}',
                if (r.price != null) r.price!,
              ].join('  ·  ')),
              trailing: const Icon(Icons.how_to_vote),
              onTap: () async {
                await groups.castVote(groupId, uid, r.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final groups = context.read<GroupService>();

    return StreamBuilder<Group>(
      stream: groups.group(groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final group = snapshot.data!;
        final isOwner = group.ownerUid == uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Chat',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        GroupChatScreen(groupId: groupId, groupName: group.name))),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'leave') {
                    await groups.leaveGroup(groupId, uid);
                    if (context.mounted) Navigator.pop(context);
                  } else if (value == 'delete') {
                    await groups.deleteGroup(groupId);
                    if (context.mounted) Navigator.pop(context);
                  } else if (value == 'reset') {
                    await groups.resetVote(groupId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'reset', child: Text('Reset vote')),
                  const PopupMenuItem(value: 'leave', child: Text('Leave group')),
                  if (isOwner)
                    const PopupMenuItem(
                        value: 'delete', child: Text('Delete group')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(context, 'Members (${group.memberCount})'),
              Wrap(
                spacing: 8,
                children: group.memberNames.values
                    .map((name) => Chip(label: Text(name)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _section(context, 'Cuisines'),
              Wrap(
                spacing: 8,
                children: [
                  ...group.categories.map((c) => Chip(label: Text(c))),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    onPressed: () => _addCategories(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _section(context, 'Group decision'),
              if (group.resultRestaurantId != null)
                _ResultCard(restaurantId: group.resultRestaurantId!)
              else
                Text(
                  group.votes.isEmpty
                      ? 'No votes yet.'
                      : '${group.votes.length} vote(s) cast — no winner yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Generate candidates & vote'),
                onPressed: () => _generateCandidates(context, group),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Loads and displays the winning restaurant for the group.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.restaurantId});

  final String restaurantId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Restaurant>(
      future: context.read<YelpService>().getBusiness(restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: ListTile(
                leading: CircularProgressIndicator(), title: Text('Loading…')),
          );
        }
        if (!snapshot.hasData) {
          return const Card(
              child: ListTile(title: Text('Could not load the result.')));
        }
        final r = snapshot.data!;
        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.emoji_events),
            title: Text('Winner: ${r.name}'),
            subtitle: Text(r.fullAddress),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RestaurantDetailsScreen(restaurant: r))),
          ),
        );
      },
    );
  }
}
