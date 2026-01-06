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

  // ✅ REGISTER WITH ROLE (email & password)
  Future<User?> register({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Create user document in Firestore
      final userModel = UserModel(
        uid: result.user!.uid,
        email: email,
        role: role,
        name: name,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userModel.toMap());

      // 3. Update display name if provided
      if (name != null && name.isNotEmpty) {
        await result.user!.updateDisplayName(name);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ REGISTER / LOGIN WITH GOOGLE + ROLE
  //
  // - If user logs in with Google for the first time -> create Firestore doc with given role.
  // - If user already exists in Firestore -> keep existing role, ignore passed role.
  Future<User?> signInWithGoogle({required String role}) async {
    try {
      // 1. Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        throw 'Google sign-in cancelled.';
      }

      // 2. Get Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with Google credential
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user == null) {
        throw 'Google sign-in failed. No user returned.';
      }

      // 5. Ensure Firestore user document exists
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // First time Google sign-in -> treat as registration
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          role: role, // role from UI (student / instructor)
          name: user.displayName,
          createdAt: DateTime.now(),
        );

        await userDocRef.set(userModel.toMap());
      } else {
        // If the doc exists but role is missing, you can optionally set it:
        /*
        final data = userDoc.data();
        if (data != null && (data['role'] == null || data['role'] == '')) {
          await userDocRef.update({'role': role});
        }
        */
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      // For non-Firebase errors (e.g., GoogleSignIn errors)
      throw e.toString();
    }
  }

  // ✅ GET USER DATA FROM FIRESTORE
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // ✅ GET USER ROLE
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user role: $e');
    }
  }

  // ✅ STREAM USER DATA
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ✅ UPDATE USER PROFILE
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profileImage,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (profileImage != null) updates['profileImage'] = profileImage;

    await _firestore.collection('users').doc(uid).update(updates);
  }

  // ✅ LOGOUT (also sign out from Google if used)
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore Google sign-out errors
    }
  }

  // ✅ ERROR HANDLER
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
