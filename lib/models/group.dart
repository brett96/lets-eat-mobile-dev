import 'package:cloud_firestore/cloud_firestore.dart';

/// A dining group: a set of members who pool preferences, vote, chat, and
/// generate a single restaurant suggestion together.
///
/// Modern, UID-based replacement for the legacy `groups` collection, which
/// keyed members and votes by display name.
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.ownerUid,
    this.memberUids = const [],
    this.memberNames = const {},
    this.categories = const [],
    this.resultRestaurantId,
    this.votes = const {},
  });

  final String id;
  final String name;
  final String ownerUid;
  final List<String> memberUids;

  /// uid → display name, so the UI can show who's in the group without extra
  /// lookups.
  final Map<String, String> memberNames;

  /// Pooled Yelp category aliases contributed by members.
  final List<String> categories;

  /// The Yelp business id chosen for the group (once a vote resolves).
  final String? resultRestaurantId;

  /// uid → the restaurant id that member voted for.
  final Map<String, String> votes;

  int get memberCount => memberUids.length;

  /// Tallies [votes] and returns the restaurant id with the most votes,
  /// or null on a tie / no votes.
  String? get winningRestaurantId {
    if (votes.isEmpty) return null;
    final counts = <String, int>{};
    for (final choice in votes.values) {
      counts[choice] = (counts[choice] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length > 1 && sorted[0].value == sorted[1].value) return null;
    return sorted.first.key;
  }

  factory Group.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Group(
      id: doc.id,
      name: data['name'] as String? ?? 'Group',
      ownerUid: data['ownerUid'] as String? ?? '',
      memberUids:
          (data['memberUids'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
      memberNames: (data['memberNames'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, '$v')),
      categories:
          (data['categories'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
      resultRestaurantId: data['resultRestaurantId'] as String?,
      votes: (data['votes'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, '$v')),
    );
  }
}
