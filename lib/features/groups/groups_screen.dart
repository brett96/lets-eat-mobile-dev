import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  Future<void> _createGroup(BuildContext context, String uid, String name) async {
    final controller = TextEditingController();
    final groupName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Group name'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (groupName == null || groupName.isEmpty || !context.mounted) return;
    final id = await context
        .read<GroupService>()
        .createGroup(name: groupName, ownerUid: uid, ownerName: name);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final groups = context.read<GroupService>();
    final displayName = user?.displayName ?? user?.email ?? 'user';

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createGroup(context, user.uid, displayName),
              icon: const Icon(Icons.group_add),
              label: const Text('New group'),
            ),
      body: user == null
          ? const Center(child: Text('Sign in to use groups.'))
          : StreamBuilder<List<Group>>(
              stream: groups.groupsForUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? const [];
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No groups yet. Create one to get started.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.groups),
                    title: Text(list[i].name),
                    subtitle: Text('${list[i].memberCount} member(s)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: list[i].id))),
                  ),
                );
              },
            ),
    );
  }
}
