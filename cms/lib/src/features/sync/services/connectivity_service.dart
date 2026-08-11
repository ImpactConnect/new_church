import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkState { online, offline }

class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final _controller = StreamController<NetworkState>.broadcast();
  NetworkState _currentState = NetworkState.online;

  Stream<NetworkState> get onStateChanged => _controller.stream;
  NetworkState get currentState => _currentState;

  void _init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      final newState = isOnline ? NetworkState.online : NetworkState.offline;
      if (newState != _currentState) {
        _currentState = newState;
        _controller.add(newState);
      }
    });
  }

  void dispose() {
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final networkStateProvider = StreamProvider<NetworkState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStateChanged;
});
