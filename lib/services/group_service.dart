import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/group.dart';

/// All group operations: create/join/leave, pooled categories, voting, and
/// the group chat subcollection. Replaces the legacy display-name-keyed
/// `groups` collection logic scattered across ViewGroup/GroupChat/GroupVote.
class GroupService {
  GroupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  Future<String> createGroup({
    required String name,
    required String ownerUid,
    required String ownerName,
  }) async {
    final doc = await _groups.add({
      'name': name,
      'ownerUid': ownerUid,
      'memberUids': [ownerUid],
      'memberNames': {ownerUid: ownerName},
      'categories': <String>[],
      'votes': <String, String>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Groups the given user belongs to.
  Stream<List<Group>> groupsForUser(String uid) => _groups
      .where('memberUids', arrayContains: uid)
      .snapshots()
      .map((snap) => snap.docs.map(Group.fromSnapshot).toList());

  Stream<Group> group(String groupId) =>
      _groups.doc(groupId).snapshots().map(Group.fromSnapshot);

  Future<void> addMember(String groupId, String uid, String name) =>
      _groups.doc(groupId).update({
        'memberUids': FieldValue.arrayUnion([uid]),
        'memberNames.$uid': name,
      });

  Future<void> leaveGroup(String groupId, String uid) =>
      _groups.doc(groupId).update({
        'memberUids': FieldValue.arrayRemove([uid]),
        'memberNames.$uid': FieldValue.delete(),
        'votes.$uid': FieldValue.delete(),
      });

  Future<void> deleteGroup(String groupId) => _groups.doc(groupId).delete();

  Future<void> addCategories(String groupId, List<String> categories) =>
      _groups.doc(groupId).update({
        'categories': FieldValue.arrayUnion(categories),
      });

  /// Records [uid]'s vote for a restaurant id and, if the vote now has a clear
  /// winner across all members, promotes it to the group result.
  Future<void> castVote(String groupId, String uid, String restaurantId) async {
    final ref = _groups.doc(groupId);
    await ref.update({'votes.$uid': restaurantId});
    final group = Group.fromSnapshot(await ref.get());
    final winner = group.winningRestaurantId;
    if (winner != null) {
      await ref.update({'resultRestaurantId': winner});
    }
  }

  /// Sets the group's chosen restaurant directly (e.g. from a random roll).
  Future<void> setResult(String groupId, String restaurantId) =>
      _groups.doc(groupId).update({'resultRestaurantId': restaurantId});

  Future<void> resetVote(String groupId) => _groups.doc(groupId).update({
        'votes': <String, String>{},
        'resultRestaurantId': FieldValue.delete(),
      });

  // ----- Chat -----

  Stream<List<ChatMessage>> messages(String groupId) => _groups
      .doc(groupId)
      .collection('messages')
      .orderBy('sentAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromSnapshot).toList());

  Future<void> sendMessage(String groupId, ChatMessage message) => _groups
      .doc(groupId)
      .collection('messages')
      .add(message.toMap());
}
