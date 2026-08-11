import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/app.dart';
import 'package:cms/src/core/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: CmsFirebaseOptions.currentPlatform,
  );

  // SESSION persistence: token is never stored to disk.
  // The user must sign in again each time they open the app/browser.
  await FirebaseAuth.instance.setPersistence(Persistence.SESSION);

  runApp(
    const ProviderScope(
      child: CmsApp(),
    ),
  );
}
