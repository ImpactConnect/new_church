import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for the CMS app, sharing the church-mobile-a1758 project.
/// The CMS is registered as a separate app within the same Firebase project.
class CmsFirebaseOptions {
  const CmsFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'CmsFirebaseOptions are not configured for $defaultTargetPlatform. '
          'The CMS runs on Web and Windows only.',
        );
    }
  }

  /// Web app registered in Firebase console under project church-mobile-a1758.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:web:2851b8ce6bcf6f377d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    authDomain: 'church-mobile-a1758.firebaseapp.com',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
  );

  /// Windows desktop app — uses same project, same Web app registration for now.
  /// NOTE: Register a dedicated Windows app in Firebase console and update this appId.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:web:2851b8ce6bcf6f377d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    authDomain: 'church-mobile-a1758.firebaseapp.com',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
  );
}
