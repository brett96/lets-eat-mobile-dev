import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  Future<void> _addFriend(BuildContext context, String uid) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add friend'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Username'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (username == null || username.isEmpty || !context.mounted) return;
    try {
      final name =
          await context.read<UserService>().addFriendByUsername(uid, username);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Added $name.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    final users = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addFriend(context, uid),
              icon: const Icon(Icons.person_add),
              label: const Text('Add friend'),
            ),
      body: uid == null
          ? const Center(child: Text('Sign in to manage friends.'))
          : StreamBuilder<List<({String uid, String username})>>(
              stream: users.friends(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friends = snapshot.data ?? const [];
                if (friends.isEmpty) {
                  return const Center(
                      child: Text('No friends yet. Add someone by username.'));
                }
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(
                        child: Text(friends[i].username.characters.first.toUpperCase())),
                    title: Text(friends[i].username),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove),
                      onPressed: () =>
                          users.removeFriend(uid, friends[i].uid),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
