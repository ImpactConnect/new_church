import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub FeatureGate — simply executes callback immediately for authenticated flows.
class FeatureGate {
  static void execute({
    required BuildContext context,
    required WidgetRef ref,
    required String featureName,
    required VoidCallback onAuthenticated,
  }) {
    onAuthenticated();
  }
}
