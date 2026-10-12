// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/account_service.dart';
import 'cloud_storage.dart';
import 'progress.dart';
import 'scoring.dart';

enum PlayerKind {
  /// Nobody picked yet: the "Who's playing?" screen comes next.
  none,

  /// Guest: progress stays only on this device.
  guest,

  /// Logged in with email + password: progress is saved to their account.
  account,
}

/// A short look at the guest save on this device, for the
/// "Continue guest game" button.
@immutable
class GuestSummary {
  const GuestSummary({required this.playerLevel, required this.stars});

  final int playerLevel;
  final int stars;

  /// Reads a guest save. Returns null when there is nothing worth continuing.
  static GuestSummary? fromJson(String? raw) {
    if (raw == null || raw.length > 100000) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final xp = json['xp'] is int ? json['xp'] as int : 0;
      var stars = 0;
      final map = json['stars'];
      if (map is Map) {
        for (final v in map.values) {
          if (v is int) stars += v.clamp(0, 3);
        }
      }
      if (xp <= 0 && stars == 0) return null;
      return GuestSummary(playerLevel: playerLevelFor(xp.clamp(0, 10000000)), stars: stars);
    } on FormatException {
      return null;
    }
  }
}

/// Knows who is playing and gives each player their own progress.
///
/// - Guest progress is stored only on this device.
/// - Account progress is stored online in that player's own account and is
///   only kept in memory here, so the next person on a shared device cannot
///   see it after the player switches or logs out.
/// - Every switch wipes the progress in memory before loading the new
///   player's save (see [ProgressController.switchStorage]).
class SessionController extends ChangeNotifier {
  SessionController({
    required this.progress,
    this.accounts,
    ProgressStorage? guestStorage,
  }) : guestStorage = guestStorage ?? SharedPrefsProgressStorage();

  /// Someone is already playing as a guest with [progress] (tests, demos).
  SessionController.preloaded(this.progress)
      : accounts = null,
        guestStorage = MemoryProgressStorage(),
        _kind = PlayerKind.guest;

  final ProgressController progress;
  final AccountService? accounts;
  final ProgressStorage guestStorage;

  PlayerKind _kind = PlayerKind.none;
  String? _name;
  CloudProgressStorage? _cloud;
  bool _restoring = false;
  Future<void>? _restoreDone;

  PlayerKind get kind => _kind;
  bool get hasPlayer => _kind != PlayerKind.none;
  bool get isGuest => _kind == PlayerKind.guest;
  bool get isAccount => _kind == PlayerKind.account;

  /// True while checking whether someone is already logged in.
  bool get restoring => _restoring;

  /// False when this build has no server to talk to (accounts hidden).
  bool get accountsEnabled => accounts != null;

  /// The logged-in player's name, or "Guest".
  String get displayName => _kind == PlayerKind.account ? (_name ?? 'Player') : 'Guest';

  /// Online save status for account players (null for guests).
  ValueListenable<SyncState>? get sync => _cloud?.state;

  void retrySave() => _cloud?.retryNow();

  /// Checks once whether a player is still logged in on this device.
  Future<void> restore() => _restoreDone ??= _restore();

  /// Completes when [restore] has finished (at once if it never ran).
  Future<void> get ready => _restoreDone ?? Future<void>.value();

  Future<void> _restore() async {
    final service = accounts;
    if (service == null) return;
    _restoring = true;
    notifyListeners();
    try {
      final session = await service.restore();
      if (session != null) await _enterAccount(session);
    } on AccountException {
      // Offline or accounts unavailable: the player can choose on the
      // "Who's playing?" screen.
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<GuestSummary?> guestSummary() async {
    try {
      return GuestSummary.fromJson(await guestStorage.read());
    } catch (_) {
      return null;
    }
  }

  /// Plays as a guest on this device. [fresh] deletes the old guest game.
  Future<void> playAsGuest({bool fresh = false}) async {
    await _leaveCurrent();
    await progress.switchStorage(guestStorage);
    if (fresh) progress.resetProgress();
    _kind = PlayerKind.guest;
    _name = null;
    notifyListeners();
  }

  /// Logs in. Throws [AccountException] with a friendly message on failure.
  Future<void> login({required String email, required String password}) async {
    final session = await _requireAccounts().login(email: email.trim(), password: password);
    await _leaveCurrent();
    await _enterAccount(session);
    notifyListeners();
  }

  /// Creates an account. With [bringGuestProgress] the guest game on this
  /// device moves into the new account (and is removed from the device).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    bool bringGuestProgress = false,
  }) async {
    String? guestJson;
    if (bringGuestProgress) {
      // Load through a controller so only clean, known fields are sent.
      final copy = ProgressController(storage: guestStorage);
      await copy.load();
      if (copy.hasProgress) guestJson = jsonEncode(copy.toJson());
      copy.dispose();
    }
    final session = await _requireAccounts().register(
      name: name.trim(),
      email: email.trim(),
      password: password,
      progressJson: guestJson,
    );
    if (guestJson != null) await _clearGuestSave();
    await _leaveCurrent();
    await _enterAccount(session);
    notifyListeners();
  }

  /// Ends this player's turn: saves, logs out (accounts) and clears their
  /// progress from memory. The next person starts at "Who's playing?".
  Future<void> switchPlayer() async {
    final wasAccount = isAccount;
    await _leaveCurrent();
    if (wasAccount) await accounts?.logout();
    await progress.switchStorage(MemoryProgressStorage());
    _kind = PlayerKind.none;
    _name = null;
    notifyListeners();
  }

  /// Deletes the account and all its saved progress (needs the password).
  Future<void> deleteAccount(String password) async {
    await _requireAccounts().deleteAccount(password);
    _cloud?.close();
    _cloud = null;
    await progress.switchStorage(MemoryProgressStorage());
    _kind = PlayerKind.none;
    _name = null;
    notifyListeners();
  }

  AccountService _requireAccounts() {
    final service = accounts;
    if (service == null) {
      throw const AccountException('Accounts are not available in this version. Play as a guest.');
    }
    return service;
  }

  Future<void> _enterAccount(AccountSession session) async {
    final cloud = CloudProgressStorage(service: _requireAccounts(), initial: session.progressJson);
    _cloud = cloud;
    _kind = PlayerKind.account;
    _name = session.user.name;
    await progress.switchStorage(cloud);
  }

  Future<void> _leaveCurrent() async {
    final cloud = _cloud;
    if (cloud == null) return;
    await cloud.flush();
    cloud.close();
    _cloud = null;
  }

  Future<void> _clearGuestSave() async {
    try {
      await guestStorage.write('{}');
    } catch (e) {
      debugPrint('CodeQuest: could not clear the guest save ($e)');
    }
  }

  @override
  void dispose() {
    _cloud?.close();
    super.dispose();
  }
}
