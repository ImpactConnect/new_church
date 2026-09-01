import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/app.dart';
import 'package:cms/src/core/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: CmsFirebaseOptions.currentPlatform,
  );

  // Enable LOCAL persistence so users remain signed in on their browsers
  // across tab closes and refreshes until they deliberately click "Sign Out".
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // Enable Firestore offline persistence & caching for offline desktop capabilities
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: CmsApp(),
    ),
  );
}
