// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/account_service.dart';
import 'progress.dart';

enum SyncState {
  /// Everything is saved online.
  saved,

  /// A save is on its way.
  saving,

  /// The last save failed (for example no internet). It will be retried.
  failed,

  /// The login ran out; the player must log in again to keep saving.
  signedOut,
}

/// Saves a logged-in player's progress to their account online.
///
/// Saves go out one at a time. If the game saves again while one is on its
/// way, only the newest data is sent next, so quick bursts become one save.
/// A failed save is kept and retried.
class CloudProgressStorage implements ProgressStorage {
  CloudProgressStorage({
    required this.service,
    String? initial,
    this.retryDelay = const Duration(seconds: 10),
  }) : _initial = initial;

  final AccountService service;
  final Duration retryDelay;
  final String? _initial;

  final ValueNotifier<SyncState> state = ValueNotifier(SyncState.saved);

  String? _pending;
  bool _sending = false;
  bool _closed = false;
  Timer? _retry;
  final List<Completer<void>> _waiters = [];

  @override
  Future<String?> read() async => _initial;

  @override
  Future<void> write(String data) async {
    if (_closed) return;
    _pending = data;
    unawaited(_pump());
  }

  /// Tries a failed save again straight away.
  void retryNow() => unawaited(_pump());

  Future<void> _pump() async {
    if (_sending || _pending == null || _closed) return;
    _retry?.cancel();
    final data = _pending!;
    _pending = null;
    _sending = true;
    state.value = SyncState.saving;
    try {
      await service.saveProgress(data);
      _sending = false;
      if (_pending != null && !_closed) {
        unawaited(_pump());
        return;
      }
      state.value = SyncState.saved;
    } on AccountException catch (e) {
      _sending = false;
      _pending ??= data; // keep the newest unsaved progress
      if (e.status == 401) {
        state.value = SyncState.signedOut;
      } else {
        state.value = SyncState.failed;
        if (!_closed) _retry = Timer(retryDelay, () => unawaited(_pump()));
      }
    }
    _wakeWaiters();
  }

  void _wakeWaiters() {
    for (final w in _waiters) {
      if (!w.isCompleted) w.complete();
    }
    _waiters.clear();
  }

  /// True when nothing is waiting to be saved.
  bool get isIdle => !_sending && _pending == null;

  /// Sends anything not yet saved and waits (up to [limit]) for it.
  Future<void> flush({Duration limit = const Duration(seconds: 6)}) async {
    if (isIdle || _closed) return;
    final waiter = Completer<void>();
    _waiters.add(waiter);
    if (!_sending) unawaited(_pump());
    try {
      await waiter.future.timeout(limit);
    } on TimeoutException {
      // Give up waiting; the player can still switch.
    }
  }

  /// Stops saving (the player switched or logged out).
  void close() {
    _closed = true;
    _retry?.cancel();
    _wakeWaiters();
  }
}
