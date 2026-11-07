import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// خيارات Firebase المعتمدة لمشروع Lamma (lama-a8920)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDwOrNV6_H0W2j7PMMcQxfBfKdpjHR0So',
    appId: '1:779197985848:android:f173f5674988a4d9f1e2cd',
    messagingSenderId: '779197985848',
    projectId: 'lama-a8920',
    storageBucket: 'lama-a8920.firebasestorage.app',
  );
}
