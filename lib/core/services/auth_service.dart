// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ LOGIN (email & password)
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ REGISTER (email & password)
  Future<User?> register({
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        uid: result.user!.uid,
        email: email,
        role: role,
        name: name,
        createdAt: DateTime.now(),
        phone: phone,
        socials: {},
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userModel.toMap());

      if (name != null && name.isNotEmpty) {
        await result.user!.updateDisplayName(name);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ SIGN IN WITH GOOGLE (FIXED: Force Account Picker)
  Future<User?> signInWithGoogle({required String role}) async {
    try {
      // 1. FORCE ACCOUNT PICKER:
      // Sign out from Google Plugin first so it doesn't auto-select the last user.
      await _googleSignIn.signOut();

      // 2. Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw 'Google sign-in cancelled.'; // User clicked outside the dialog
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Sign in to Firebase
      // If "One account per email" is enabled in Console, this links accounts.
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        // 4. CRITICAL CHECK: Only create DB entry if it DOES NOT EXIST.
        if (!userDoc.exists) {
          final userModel = UserModel(
            uid: user.uid,
            email: user.email!,
            role: role, // Use selected role for NEW users only
            name: user.displayName,
            profileImage: user.photoURL,
            createdAt: DateTime.now(),
            phone: user.phoneNumber,
            socials: {},
          );

          await userDocRef.set(userModel.toMap());
        }
        // If doc exists, we do nothing to preserve existing role/data.
      }

      return user;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // ... (Keep existing getters and helpers)
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profileImage,
    String? phone,
    Map<String, dynamic>? socials,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profileImage != null) updates['profileImage'] = profileImage;
    if (phone != null) updates['phone'] = phone;
    if (socials != null) updates['socials'] = socials;
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(uid).update(updates);

    if (name != null && _auth.currentUser != null) {
      await _auth.currentUser!.updateDisplayName(name);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  String _handleAuthError(FirebaseAuthException e) {
    return e.message ?? 'Authentication error';
  }
}
