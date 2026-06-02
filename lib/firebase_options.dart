import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBGVfY9YBPiQ5KkAsSU_PKPCp3SJNCXbfw',
    authDomain: 'ipila-9016a.firebaseapp.com',
    projectId: 'ipila-9016a',
    storageBucket: 'ipila-9016a.firebasestorage.app',
    messagingSenderId: '917201136319',
    appId: '1:917201136319:web:d15b178a2ecc6957c1f40a',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGdCAVN0Fhtot7ieBiO878F3U5QBADl3A',
    appId: '1:917201136319:android:6725dfec4368b7b9c1f40a',
    messagingSenderId: '917201136319',
    projectId: 'ipila-9016a',
    storageBucket: 'ipila-9016a.firebasestorage.app',
  );

  // iOS — fill in if needed
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGVFY9YBPiQ5KkAsSU_PKPCp3SJNCXbfw',
    appId: '1:917201136319:web:d15b178a2ecc6957c1f40a',
    messagingSenderId: '917201136319',
    projectId: 'ipila-9016a',
    storageBucket: 'ipila-9016a.firebasestorage.app',
    iosBundleId: 'com.pila.ipila',
  );
}
