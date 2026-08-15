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

  // LOCAL persistence: token is stored securely to keep user signed in until explicit logout.
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(
    const ProviderScope(
      child: CmsApp(),
    ),
  );
}
