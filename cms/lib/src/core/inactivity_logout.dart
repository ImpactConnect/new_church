import 'package:flutter/material.dart';

/// Wraps the app.
/// Inactivity logout has been disabled as requested by the user —
/// users remain signed in permanently unless they deliberately sign out.
class InactivityLogoutWrapper extends StatelessWidget {
  const InactivityLogoutWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
