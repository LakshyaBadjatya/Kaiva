// Generated from the project's real Firebase config (project: kaiva-1).
// Values mirror android/app/google-services.json and the iOS
// GoogleService-Info.plist so Firebase initializes without relying on a
// native plist being bundled (which the regenerated iOS project does not do).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAT6isWqMjxjIWqjxxMOgsQ-sX6uEONvyE',
    appId: '1:444474123870:android:d85cd67953baf8a7b2f6cf',
    messagingSenderId: '444474123870',
    projectId: 'kaiva-1',
    storageBucket: 'kaiva-1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3Q4DWvxzVbtzkMcFzkB8CsfAIVq9J9Y4',
    appId: '1:444474123870:ios:c29e6d9fcbaa579bb2f6cf',
    messagingSenderId: '444474123870',
    projectId: 'kaiva-1',
    storageBucket: 'kaiva-1.firebasestorage.app',
    iosClientId:
        '444474123870-bi6am993ev374gu41gal8c1m1rgjlme0.apps.googleusercontent.com',
    iosBundleId: 'com.lakshya.kaiva',
  );
}
