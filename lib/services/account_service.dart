// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A logged-in player, as the server describes them.
@immutable
class AccountUser {
  const AccountUser({required this.name});

  final String name;
}

/// What the server returns after log in / sign up / session check.
@immutable
class AccountSession {
  const AccountSession({required this.user, this.progressJson});

  final AccountUser user;

  /// This player's saved progress as JSON, or null for a brand-new player.
  final String? progressJson;
}

/// A problem with an account request, with a message safe to show players.
class AccountException implements Exception {
  const AccountException(this.message, {this.status});

  static const String offlineMessage =
      "Can't reach the CodeQuest server. Check your internet and try again.";

  final String message;

  /// HTTP status from the server, or null when the server could not be reached.
  final int? status;

  bool get isOffline => status == null;

  @override
  String toString() => message;
}

/// Keeps the session token on mobile. (On the web the session is an
/// HttpOnly cookie that app code can never read, so nothing is stored.)
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String? token);
}

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String? value) async => token = value;
}

class SharedPrefsTokenStore implements TokenStore {
  static const String key = 'codequest.session.v1';

  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, token);
    }
  }
}

/// Talks to our own `/api/account` endpoint: sign up, log in, log out,
/// delete account, and load/save the logged-in player's progress.
class AccountService {
  AccountService({
    required this.endpoint,
    http.Client? client,
    this.tokenStore,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client();

  final Uri endpoint;
  final Duration timeout;

  /// Set for the mobile app (Bearer token). Null on the web (cookie).
  final TokenStore? tokenStore;
  final http.Client _client;

  /// Web: same-origin `/api/account`. Mobile: `--dart-define=TUTOR_API_BASE=https://...`.
  static AccountService? fromEnvironment() {
    const base = String.fromEnvironment('TUTOR_API_BASE');
    if (base.isNotEmpty) {
      final uri = Uri.tryParse(base);
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        return AccountService(endpoint: uri.resolve('/api/account'), tokenStore: SharedPrefsTokenStore());
      }
      return null;
    }
    if (kIsWeb) return AccountService(endpoint: Uri.base.resolve('/api/account'));
    return null;
  }

  Future<http.Response> _send(String method, [Map<String, Object?>? body]) async {
    try {
      final request = http.Request(method, endpoint);
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final store = tokenStore;
      if (store != null) {
        request.headers['X-CodeQuest-Client'] = 'app';
        final token = await store.read();
        if (token != null) request.headers['Authorization'] = 'Bearer $token';
      }
      final streamed = await _client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on Exception {
      // Timeout, no network, DNS... all mean the same thing to the player.
      throw const AccountException(AccountException.offlineMessage);
    }
  }

  static Map<String, Object?> _decode(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, Object?>) return data;
    } on FormatException {
      // Not JSON (for example an HTML error page).
    }
    return const {};
  }

  static AccountException _error(http.Response response) {
    final message = _decode(response)['error'];
    if (message is String && message.isNotEmpty && message.length <= 200) {
      return AccountException(message, status: response.statusCode);
    }
    if (response.statusCode == 404 || response.statusCode >= 500) {
      return AccountException(
        'Accounts are not available right now. You can still play as a guest.',
        status: response.statusCode,
      );
    }
    return AccountException('Something went wrong (${response.statusCode}).', status: response.statusCode);
  }

  Future<AccountSession> _session(http.Response response) async {
    final data = _decode(response);
    final user = data['user'];
    if (user is! Map || user['name'] is! String) {
      throw AccountException('The server sent an unexpected reply.', status: response.statusCode);
    }
    final token = data['token'];
    if (tokenStore != null && token is String) await tokenStore!.write(token);
    final progress = data['progress'];
    return AccountSession(
      user: AccountUser(name: user['name'] as String),
      progressJson: progress is Map ? jsonEncode(progress) : null,
    );
  }

  /// The player who is already logged in on this device, or null.
  Future<AccountSession?> restore() async {
    // Mobile with no saved token: nobody is logged in, no need to ask.
    if (tokenStore != null && await tokenStore!.read() == null) return null;
    final response = await _send('GET');
    if (response.statusCode == 401) {
      await tokenStore?.write(null);
      return null;
    }
    if (response.statusCode != 200) throw _error(response);
    return _session(response);
  }

  Future<AccountSession> register({
    required String name,
    required String email,
    required String password,
    String? progressJson,
  }) async {
    final response = await _send('POST', {
      'action': 'register',
      'name': name,
      'email': email,
      'password': password,
      if (progressJson != null) 'progress': jsonDecode(progressJson),
    });
    if (response.statusCode != 201) throw _error(response);
    return _session(response);
  }

  Future<AccountSession> login({required String email, required String password}) async {
    final response = await _send('POST', {'action': 'login', 'email': email, 'password': password});
    if (response.statusCode != 200) throw _error(response);
    return _session(response);
  }

  /// Logs out on the server too. Never throws: the player is logged out on
  /// this device either way.
  Future<void> logout() async {
    try {
      await _send('POST', {'action': 'logout'});
    } on AccountException {
      // Offline: the cookie expires on its own; the app has already forgotten it.
    }
    await tokenStore?.write(null);
  }

  /// Deletes the account and all of its saved progress.
  Future<void> deleteAccount(String password) async {
    final response = await _send('POST', {'action': 'delete', 'password': password});
    if (response.statusCode != 200) throw _error(response);
    await tokenStore?.write(null);
  }

  /// Saves the logged-in player's progress (JSON from ProgressController).
  Future<void> saveProgress(String progressJson) async {
    final response = await _send('PUT', {'progress': jsonDecode(progressJson)});
    if (response.statusCode != 200) throw _error(response);
  }
}
