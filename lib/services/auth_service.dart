import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// All authentication flows: email/password, Google Sign-In (with the
/// legacy account-merge behavior), and the account-deletion path that the
/// app stores now require.
class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user!;
  }

  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(username);
    await _ensureUserDocument(user, username: username);
    await user.sendEmailVerification();
    return user;
  }

  /// Sign in with Google. If an account already exists for this email the
  /// providers are linked by Firebase automatically (same UID); a Firestore
  /// profile document is created on first sign-in.
  Future<User> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'canceled', message: 'Sign-in canceled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    await _ensureUserDocument(user, username: user.displayName ?? user.email ?? 'user');
    return user;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Deletes the Firestore profile then the Firebase Auth user.
  /// May throw `requires-recent-login`, in which case the caller should
  /// re-authenticate and retry.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final username = (await userDoc.get()).data()?['username'] as String?;
    if (username != null) {
      await _firestore.collection('usernames').doc(username).delete();
    }
    await userDoc.delete();
    await user.delete();
  }

  Future<void> _ensureUserDocument(User user, {required String username}) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await doc.set({
        'username': username,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Public username → uid mapping so friends can be looked up without
      // exposing private user documents.
      await _firestore
          .collection('usernames')
          .doc(username)
          .set({'uid': user.uid});
    }
  }
}
