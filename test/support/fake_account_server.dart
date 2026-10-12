// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:convert';

import 'package:codequest/services/account_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A pretend `/api/account` server for app tests. It behaves like the real
/// one: one cookie session per browser, each account only sees its own save.
class FakeAccountServer {
  final Map<String, ({String name, String password})> accounts = {};
  final Map<String, Object?> saves = {};

  /// Email of the account logged in on this "browser" (the cookie).
  String? loggedIn;

  /// When true, every request fails as if there were no internet.
  bool offline = false;

  /// Status to answer PUT (save) with, to test failures.
  int saveStatus = 200;

  int saveCount = 0;
  final List<String> calls = [];

  static final Uri endpoint = Uri.parse('https://codequest.test/api/account');

  AccountService service() => AccountService(endpoint: endpoint, client: client);

  /// Adds an account directly (as if it was made earlier).
  void addAccount(String email, String name, String password, {Map<String, Object?>? progress}) {
    accounts[email] = (name: name, password: password);
    if (progress != null) saves[email] = progress;
  }

  late final http.Client client = MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    calls.add(request.method);
    http.Response json(int status, Object body) => http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );

    if (request.method == 'GET') {
      final email = loggedIn;
      if (email == null) return json(401, {'error': 'Not logged in.'});
      return json(200, {
        'user': {'name': accounts[email]!.name},
        'progress': saves[email],
      });
    }

    final body = jsonDecode(request.body) as Map<String, Object?>;
    if (request.method == 'PUT') {
      final email = loggedIn;
      if (email == null) return json(401, {'error': 'Please log in again.'});
      if (saveStatus != 200) return json(saveStatus, {'error': 'Saving failed.'});
      saveCount++;
      saves[email] = body['progress'];
      return json(200, {'ok': true});
    }

    switch (body['action']) {
      case 'register':
        final email = (body['email'] as String).trim().toLowerCase();
        if (accounts.containsKey(email)) {
          return json(409, {'error': 'This email already has an account. Please log in instead.'});
        }
        accounts[email] = (name: body['name'] as String, password: body['password'] as String);
        if (body['progress'] != null) saves[email] = body['progress'];
        loggedIn = email;
        return json(201, {
          'user': {'name': body['name']},
          'progress': saves[email],
        });
      case 'login':
        final email = (body['email'] as String).trim().toLowerCase();
        final account = accounts[email];
        if (account == null || account.password != body['password']) {
          return json(401, {'error': 'Email or password is wrong.'});
        }
        loggedIn = email;
        return json(200, {
          'user': {'name': account.name},
          'progress': saves[email],
        });
      case 'logout':
        loggedIn = null;
        return json(200, {'ok': true});
      case 'delete':
        final email = loggedIn;
        if (email == null) return json(401, {'error': 'Please log in again.'});
        if (accounts[email]!.password != body['password']) return json(401, {'error': 'Password is wrong.'});
        accounts.remove(email);
        saves.remove(email);
        loggedIn = null;
        return json(200, {'ok': true});
    }
    return json(400, {'error': 'Bad action.'});
  });
}
