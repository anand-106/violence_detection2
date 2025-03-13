import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyC17lBe8_nBiXgvO6XO2-vxtEUUvHQ9uCY",
        authDomain: "rtvd-110be.firebaseapp.com",
        projectId: "rtvd-110be",
        storageBucket: "rtvd-110be.firebasestorage.app",
        messagingSenderId: "898304185713",
        appId: "1:898304185713:web:aee0627f001481f1fc52d0",
        measurementId: "G-YJ33MEKY2E",
      );
    }

    // Add other platforms if needed
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
}
