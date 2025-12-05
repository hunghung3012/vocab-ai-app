import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // LOGIN EMAIL
  Future<bool> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print("==> Error: ${e.message}");
      return false;
    }
  }

  // Future<void> _saveUserToFirestore(User user) async {
  //   final userRef =
  //   FirebaseFirestore.instance.collection("users").doc(user.uid);
  //
  //   final doc = await userRef.get();
  //
  //   if (!doc.exists) {
  //     await userRef.set({
  //       "uid": user.uid,
  //       "email": user.email,
  //       "createdAt": FieldValue.serverTimestamp(),
  //       "provider": user.providerData.first.providerId,
  //     });
  //   } else {
  //     print("User đã tồn tại trong Firestore");
  //   }
  // }

  // LOGIN GOOGLE
  Future<void> signInWithGoogle() async {
    try {
      print('==> check 1');
      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      await _auth.signInWithCredential(credential);
    } catch (e) {
      print("==> Google login error: $e");
    }
  }

  Future<bool> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      return true;
    } catch (e) {
      print("Logout error: $e");
      return false;
    }
  }
}
