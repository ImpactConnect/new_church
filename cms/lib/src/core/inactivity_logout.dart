import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cms/src/core/providers.dart';

/// Wraps the app and tracks user activity.
/// Automatically signs out after [timeout] of inactivity.
/// Lead Pastor & Finance: 10 minutes. Secretary: 20 minutes.
class InactivityLogoutWrapper extends ConsumerStatefulWidget {
  const InactivityLogoutWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<InactivityLogoutWrapper> createState() =>
      _InactivityLogoutWrapperState();
}

class _InactivityLogoutWrapperState
    extends ConsumerState<InactivityLogoutWrapper> {
  Timer? _timer;
  Duration _timeout = const Duration(minutes: 20);

  @override
  void initState() {
    super.initState();
    _startOrResetTimer();
  }

  void _startOrResetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, _signOut);
  }

  Future<void> _signOut() async {
    final auth = ref.read(authRepositoryProvider);
    await auth.signOut();
  }

  void _onActivity(PointerEvent _) => _startOrResetTimer();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update timeout when user changes role
    ref.listen(cmsUserProvider, (_, next) {
      final roleId = next.valueOrNull?.roleId;
      _timeout = (roleId == 'leadPastor' || roleId == 'financeDept')
          ? const Duration(minutes: 10)
          : const Duration(minutes: 20);
      _startOrResetTimer();
    });

    return Listener(
      onPointerDown: _onActivity,
      onPointerMove: _onActivity,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
