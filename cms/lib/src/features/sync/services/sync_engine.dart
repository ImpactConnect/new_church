import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cms/src/core/providers.dart';
import 'package:cms/src/features/sync/models/sync_outbox_model.dart';
import 'package:cms/src/features/sync/services/connectivity_service.dart';

class SyncEngineState {
  const SyncEngineState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.networkState = NetworkState.online,
  });

  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final NetworkState networkState;

  SyncEngineState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    NetworkState? networkState,
  }) => SyncEngineState(
    isSyncing: isSyncing ?? this.isSyncing,
    pendingCount: pendingCount ?? this.pendingCount,
    lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    networkState: networkState ?? this.networkState,
  );
}

class SyncEngine extends StateNotifier<SyncEngineState> {
  SyncEngine({
    required FirebaseFirestore firestore,
    required ConnectivityService connectivity,
  })  : _db = firestore,
        _connectivity = connectivity,
        super(const SyncEngineState()) {
    _init();
  }

  final FirebaseFirestore _db;
  final ConnectivityService _connectivity;
  final List<SyncOutboxModel> _outbox = [];
  final _uuid = const Uuid();
  StreamSubscription? _connSub;

  void _init() {
    state = state.copyWith(networkState: _connectivity.currentState);

    _connSub = _connectivity.onStateChanged.listen((netState) {
      state = state.copyWith(networkState: netState);
      if (netState == NetworkState.online) {
        processQueue();
      }
    });
  }

  /// Enqueue an offline operation.
  Future<void> enqueue({
    required String collection,
    required String documentId,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncOutboxModel(
      id: _uuid.v4(),
      collection: collection,
      documentId: documentId,
      action: action,
      payload: payload,
      timestamp: DateTime.now(),
    );

    _outbox.add(item);
    state = state.copyWith(pendingCount: _outbox.length);

    if (state.networkState == NetworkState.online) {
      processQueue();
    }
  }

  /// Process the outbox FIFO queue.
  Future<void> processQueue() async {
    if (state.isSyncing || _outbox.isEmpty) return;
    state = state.copyWith(isSyncing: true);

    final toRemove = <SyncOutboxModel>[];

    for (final item in List<SyncOutboxModel>.from(_outbox)) {
      try {
        final docRef = _db.doc(item.collection.contains('/') ? '${item.collection}/${item.documentId}' : item.collection);

        switch (item.action) {
          case SyncAction.create:
          case SyncAction.update:
            await docRef.set(item.payload, SetOptions(merge: true));
            break;
          case SyncAction.delete:
            await docRef.delete();
            break;
        }

        toRemove.add(item);
      } catch (e) {
        debugPrint('[SyncEngine] Failed to sync ${item.id}: $e');
        // Keep in queue for next retry
      }
    }

    _outbox.removeWhere((i) => toRemove.contains(i));
    state = state.copyWith(
      isSyncing: false,
      pendingCount: _outbox.length,
      lastSyncTime: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}

final syncEngineProvider = StateNotifierProvider<SyncEngine, SyncEngineState>((ref) {
  final db = ref.watch(firestoreProvider);
  final conn = ref.watch(connectivityServiceProvider);
  return SyncEngine(firestore: db, connectivity: conn);
});
