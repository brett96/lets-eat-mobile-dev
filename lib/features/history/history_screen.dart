import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';

/// Shows the user's past instant suggestions, most recent first.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;
    final users = context.read<UserService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Suggestion History')),
      body: uid == null
          ? const Center(child: Text('Sign in to see your history.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: users.history(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snapshot.data ?? const [];
                if (entries.isEmpty) {
                  return const Center(
                      child: Text('No suggestions yet. Try Instant Suggestion!'));
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final imageUrl = e['imageUrl'] as String?;
                    final suggestedAt = e['suggestedAt'];
                    final date = suggestedAt is DateTime
                        ? suggestedAt
                        : (suggestedAt?.toDate() as DateTime?);
                    return ListTile(
                      leading: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(imageUrl,
                                  width: 56, height: 56, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.restaurant, size: 40)),
                            )
                          : const Icon(Icons.restaurant, size: 40),
                      title: Text(e['name'] as String? ?? 'Unknown'),
                      subtitle: Text([
                        if (e['rating'] != null) '★ ${e['rating']}',
                        if (e['price'] != null) e['price'] as String,
                        if (date != null) _formatDate(date),
                      ].join('  ·  ')),
                    );
                  },
                );
              },
            ),
    );
  }
}
