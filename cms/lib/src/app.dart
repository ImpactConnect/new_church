import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/inactivity_logout.dart';
import 'package:cms/src/core/theme.dart';
import 'package:cms/src/routing/app_router.dart';

class CmsApp extends ConsumerWidget {
  const CmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return InactivityLogoutWrapper(
      child: MaterialApp.router(
        title: 'Church Management System',
        theme: CmsTheme.theme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
