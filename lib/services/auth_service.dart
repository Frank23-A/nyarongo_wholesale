import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      return credential;
    }

    await user.updateDisplayName(displayName);
    final profileData = {
      'uid': user.uid,
      'displayName': displayName,
      'email': email,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('users').doc(user.uid).set(profileData);
    } on FirebaseException catch (error) {
      if (!_isPermissionDenied(error)) {
        rethrow;
      }
    } catch (error) {
      if (!error.toString().toLowerCase().contains('permission')) {
        rethrow;
      }
    }

    return credential;
  }

  Future<void> saveCurrentUserProfile({
    required String displayName,
    required UserRole role,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': displayName,
        'email': user.email,
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (!_isPermissionDenied(error)) {
        rethrow;
      }
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  bool _isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied' ||
        error.message?.toLowerCase().contains('permission') == true;
  }
}
