import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );


  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();


  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // ADD THIS
      if (googleUser == null) {
        print('>>> Sign in cancelled by user');
        return null;
      }
      print('>>> Got google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      print('>>> Got auth tokens');

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      print('>>> Firebase sign in success: ${userCredential.user?.email}');

      final User? user = userCredential.user;
      if (user != null) {
        await _saveUserToFirestore(user);
      }

      return user;
    } catch (e, stack) {
      print('>>> Google Sign In error: $e');
      print('>>> Stack: $stack');
      return null;
    }
  }


  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }


  static Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'name': user.displayName ?? 'Cricket Fan',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
      });
    } else {
      await userRef.update({
        'name': user.displayName ?? 'Cricket Fan',
        'photoUrl': user.photoURL ?? '',
      });
    }
  }


  static Future<void> updateFcmToken(String token) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }
}