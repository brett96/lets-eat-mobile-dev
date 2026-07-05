import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';
import '../models/user_preferences.dart';

/// Firestore access for per-user data (profile, saved restaurants, history).
/// Widgets never touch Firestore directly — they go through this service.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Stream<Map<String, dynamic>?> profile(String uid) =>
      _userDoc(uid).snapshots().map((s) => s.data());

  Future<void> updateUsername(String uid, String username) =>
      _userDoc(uid).update({'username': username});

  // ----- Saved restaurants -----

  CollectionReference<Map<String, dynamic>> _saved(String uid) =>
      _userDoc(uid).collection('savedRestaurants');

  Stream<List<Restaurant>> savedRestaurants(String uid) =>
      _saved(uid).snapshots().map((snap) => snap.docs
          .map((d) => Restaurant(
                id: d.id,
                name: d.data()['name'] as String? ?? 'Unknown',
                rating: (d.data()['rating'] as num?)?.toDouble(),
                price: d.data()['price'] as String?,
                imageUrl: d.data()['imageUrl'] as String?,
                address: d.data()['address'] as String?,
              ))
          .toList());

  Future<void> saveRestaurant(String uid, Restaurant restaurant) =>
      _saved(uid).doc(restaurant.id).set(restaurant.toFirestore());

  Future<void> removeSavedRestaurant(String uid, String restaurantId) =>
      _saved(uid).doc(restaurantId).delete();

  // ----- Suggestion history -----

  Future<void> addToHistory(String uid, Restaurant restaurant) =>
      _userDoc(uid).collection('history').add({
        ...restaurant.toFirestore(),
        'suggestedAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Map<String, dynamic>>> history(String uid) => _userDoc(uid)
      .collection('history')
      .orderBy('suggestedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());

  // ----- Preferences -----

  Future<UserPreferences> getPreferences(String uid) async {
    final snap = await _userDoc(uid).get();
    return UserPreferences.fromMap(
        snap.data()?['preferences'] as Map<String, dynamic>?);
  }

  Stream<UserPreferences> preferences(String uid) => _userDoc(uid)
      .snapshots()
      .map((s) => UserPreferences.fromMap(
          s.data()?['preferences'] as Map<String, dynamic>?));

  Future<void> savePreferences(String uid, UserPreferences prefs) =>
      _userDoc(uid).set({'preferences': prefs.toMap()}, SetOptions(merge: true));

  // ----- Friends -----

  /// Looks up a user by exact username via the public `usernames` mapping.
  /// Returns (uid, username) or null.
  Future<({String uid, String username})?> findByUsername(String username) async {
    final doc = await _firestore.collection('usernames').doc(username).get();
    final uid = doc.data()?['uid'] as String?;
    if (uid == null) return null;
    return (uid: uid, username: username);
  }

  /// Adds a mutual friendship by username. Returns the friend's display name,
  /// or throws if not found / self.
  Future<String> addFriendByUsername(String uid, String username) async {
    final match = await findByUsername(username);
    if (match == null) {
      throw Exception('No user found with username "$username".');
    }
    if (match.uid == uid) {
      throw Exception("You can't add yourself.");
    }
    final batch = _firestore.batch();
    batch.set(_userDoc(uid).collection('friends').doc(match.uid),
        {'username': match.username, 'addedAt': FieldValue.serverTimestamp()});
    // Reciprocal edge so both users see the friendship.
    final me = await _userDoc(uid).get();
    batch.set(_userDoc(match.uid).collection('friends').doc(uid), {
      'username': me.data()?['username'] ?? 'user',
      'addedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return match.username;
  }

  Stream<List<({String uid, String username})>> friends(String uid) => _userDoc(uid)
      .collection('friends')
      .orderBy('username')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) =>
              (uid: d.id, username: d.data()['username'] as String? ?? 'user'))
          .toList());

  Future<void> removeFriend(String uid, String friendUid) async {
    final batch = _firestore.batch();
    batch.delete(_userDoc(uid).collection('friends').doc(friendUid));
    batch.delete(_userDoc(friendUid).collection('friends').doc(uid));
    await batch.commit();
  }

  /// Persists the FCM token for push notifications.
  Future<void> saveFcmToken(String uid, String token) => _userDoc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
}
