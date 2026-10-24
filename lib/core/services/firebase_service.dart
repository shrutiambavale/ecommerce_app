import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static bool _isInitialized = false;
  static bool _isFirebaseAvailable = false;

  static bool get isInitialized => _isInitialized;
  static bool get isFirebaseAvailable => _isFirebaseAvailable;

  static FirebaseAuth? get auth =>
      _isFirebaseAvailable ? FirebaseAuth.instance : null;

  static FirebaseFirestore? get firestore =>
      _isFirebaseAvailable ? FirebaseFirestore.instance : null;

  static FirebaseStorage? get storage =>
      _isFirebaseAvailable ? FirebaseStorage.instance : null;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Native Android initialization with google-services.json
        try {
          await Firebase.initializeApp();
        } catch (_) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseAvailable = true;
      developer.log(
        'Firebase initialized successfully with live project (iplteams-6eb14).',
        name: 'FirebaseService',
      );
    } catch (e, stack) {
      developer.log(
        'Firebase live initialization bypassed (running in secure local/emulator mode): $e',
        name: 'FirebaseService',
        error: e,
        stackTrace: stack,
      );
      _isFirebaseAvailable = false;
    } finally {
      _isInitialized = true;
    }
  }
}
