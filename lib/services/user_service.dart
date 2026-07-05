import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/restaurant.dart';

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
}
