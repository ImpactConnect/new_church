import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cms/src/core/providers.dart';

/// Inactivity timeout durations per role (per dev guide spec §3.2)
const Duration _highSecurityTimeout  = Duration(minutes: 10);  // Lead Pastor, Finance
const Duration _secretaryTimeout     = Duration(minutes: 30);  // Secretary
const Duration _defaultTimeout       = Duration(minutes: 20);  // Branch Pastor, Asset Manager

/// Inactivity logout disabled per user directive: Users are kept logged in persistently.
class InactivityLogoutWrapper extends ConsumerWidget {
  const InactivityLogoutWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}
