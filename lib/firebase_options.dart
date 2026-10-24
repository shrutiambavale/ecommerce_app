import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] configured from your google-services.json (`iplteams-6eb14`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlqKVJgVBvp8QEdDAtLE4XIUusbHZB1tk',
    appId: '1:29343418210:android:f3e861b911c245b1c80e3b',
    messagingSenderId: '29343418210',
    projectId: 'iplteams-6eb14',
    storageBucket: 'iplteams-6eb14.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlqKVJgVBvp8QEdDAtLE4XIUusbHZB1tk',
    appId: '1:29343418210:web:f3e861b911c245b1c80e3b',
    messagingSenderId: '29343418210',
    projectId: 'iplteams-6eb14',
    authDomain: 'iplteams-6eb14.firebaseapp.com',
    storageBucket: 'iplteams-6eb14.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlqKVJgVBvp8QEdDAtLE4XIUusbHZB1tk',
    appId: '1:29343418210:ios:f3e861b911c245b1c80e3b',
    messagingSenderId: '29343418210',
    projectId: 'iplteams-6eb14',
    storageBucket: 'iplteams-6eb14.firebasestorage.app',
    iosBundleId: 'com.example.ecommerce_app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBlqKVJgVBvp8QEdDAtLE4XIUusbHZB1tk',
    appId: '1:29343418210:ios:f3e861b911c245b1c80e3b',
    messagingSenderId: '29343418210',
    projectId: 'iplteams-6eb14',
    storageBucket: 'iplteams-6eb14.firebasestorage.app',
    iosBundleId: 'com.example.ecommerce_app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBlqKVJgVBvp8QEdDAtLE4XIUusbHZB1tk',
    appId: '1:29343418210:web:f3e861b911c245b1c80e3b',
    messagingSenderId: '29343418210',
    projectId: 'iplteams-6eb14',
    authDomain: 'iplteams-6eb14.firebaseapp.com',
    storageBucket: 'iplteams-6eb14.firebasestorage.app',
  );
}
