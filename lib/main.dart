import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/app.dart';
import 'package:nyarongo_wholesale/firebase_options.dart';
import 'package:nyarongo_wholesale/services/product_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _FirebaseBootstrap());
}

class _FirebaseBootstrap extends StatefulWidget {
  const _FirebaseBootstrap();

  @override
  State<_FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<_FirebaseBootstrap> {
  var _firebaseReady = false;
  String? _firebaseErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeFirebase());
  }

  Future<void> _initializeFirebase() async {
    var firebaseReady = false;
    String? firebaseErrorMessage;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      firebaseReady = true;
      unawaited(_seedDemoProducts());
    } catch (error) {
      if (error is FirebaseException && error.code == 'duplicate-app') {
        firebaseReady = true;
        unawaited(_seedDemoProducts());
      } else {
        firebaseErrorMessage = error.toString();
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _firebaseReady = firebaseReady;
      _firebaseErrorMessage = firebaseErrorMessage;
    });
  }

  Future<void> _seedDemoProducts() async {
    try {
      await const ProductService().seedDemoProductsIfEmpty();
    } catch (_) {
      // Firestore security rules may block seeding; the UI will surface
      // collection-level errors where the data is used.
    }
  }

  @override
  Widget build(BuildContext context) {
    return NyarongoWholesaleApp(
      firebaseReady: _firebaseReady,
      firebaseErrorMessage: _firebaseErrorMessage,
    );
  }
}
