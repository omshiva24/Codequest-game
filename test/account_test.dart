// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Player accounts in the app: every player gets their own progress, and a
// new player never sees anyone else's.

import 'dart:convert';

import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/cloud_storage.dart';
import 'package:codequest/logic/progress.dart';
import 'package:codequest/logic/session.dart';
import 'package:codequest/services/account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_account_server.dart';

/// Lets queued saves (async, no timers) finish.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountService', () {
    test('web mode: no token is ever handled by app code', () async {
      late http.Request seen;
      final service = AccountService(
        endpoint: Uri.parse('https://x.test/api/account'),
        client: MockClient((r) async {
          seen = r;
          return http.Response(jsonEncode({'user': {'name': 'Om'}, 'progress': null, 'token': 'leak'}), 200);
        }),
      );
      final session = await service.login(email: 'om@example.com', password: 'blue-tiger-42');
      expect(session.user.name, 'Om');
      expect(session.progressJson, isNull);
      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(seen.headers.containsKey('X-CodeQuest-Client'), isFalse);
      expect(jsonDecode(seen.body), {'action': 'login', 'email': 'om@example.com', 'password': 'blue-tiger-42'});
    });

    test('mobile mode: keeps the token and sends it as a Bearer header', () async {
      final tokens = MemoryTokenStore();
      final headers = <Map<String, String>>[];
      final service = AccountService(
        endpoint: Uri.parse('https://x.test/api/account'),
        tokenStore: tokens,
        client: MockClient((r) async {
          headers.add(r.headers);
          if (r.method == 'GET') return http.Response(jsonEncode({'user': {'name': 'Om'}, 'progress': {'xp': 5}}), 200);
          if (r.body.contains('logout')) return http.Response('{"ok":true}', 200);
          return http.Response(jsonEncode({'user': {'name': 'Om'}, 'progress': null, 'token': 'tok123'}), 200);
        }),
      );
      expect(await service.restore(), isNull, reason: 'no token yet, so no request');
      expect(headers, isEmpty);
      await service.login(email: 'om@example.com', password: 'blue-tiger-42');
      expect(tokens.token, 'tok123');
      final restored = await service.restore();
      expect(restored!.progressJson, '{"xp":5}');
      expect(headers.last['Authorization'], 'Bearer tok123');
      expect(headers.last['X-CodeQuest-Client'], 'app');
      await service.logout();
      expect(tokens.token, isNull);
    });

    test('server messages are passed on; odd replies become friendly ones', () async {
      Future<AccountException> failWith(http.Response response) async {
        final service = AccountService(
          endpoint: Uri.parse('https://x.test/api/account'),
          client: MockClient((_) async => response),
        );
        try {
          await service.login(email: 'a@b.cd', password: 'x');
        } on AccountException catch (e) {
          return e;
        }
        fail('should have thrown');
      }

      expect((await failWith(http.Response('{"error":"Email or password is wrong."}', 401))).message,
          'Email or password is wrong.');
      final html = await failWith(http.Response('<html>oops</html>', 502));
      expect(html.message, contains('guest'));
      expect(html.status, 502);
    });

    test('no internet gives an offline error, not a crash', () async {
      final service = AccountService(
        endpoint: Uri.parse('https://x.test/api/account'),
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      expect(
        () => service.restore(),
        throwsA(isA<AccountException>().having((e) => e.isOffline, 'offline', isTrue)),
      );
    });
  });

  group('CloudProgressStorage', () {
    test('bursts of saves become one save with the newest data', () async {
      final server = FakeAccountServer()..addAccount('om@example.com', 'Om', 'pw-123456');
      server.loggedIn = 'om@example.com';
      final cloud = CloudProgressStorage(service: server.service());
      await cloud.write('{"xp":1}');
      await cloud.write('{"xp":2}');
      await cloud.write('{"xp":3}');
      await settle();
      expect(server.saves['om@example.com'], {'xp': 3});
      expect(server.saveCount, 2, reason: 'first save, then only the newest');
      expect(cloud.state.value, SyncState.saved);
      cloud.close();
    });

    test('a failed save is kept and sent again', () async {
      final server = FakeAccountServer()..addAccount('om@example.com', 'Om', 'pw-123456');
      server.loggedIn = 'om@example.com';
      server.saveStatus = 503;
      final cloud = CloudProgressStorage(service: server.service(), retryDelay: const Duration(hours: 1));
      await cloud.write('{"xp":7}');
      await settle();
      expect(cloud.state.value, SyncState.failed);
      server.saveStatus = 200;
      cloud.retryNow();
      await settle();
      expect(cloud.state.value, SyncState.saved);
      expect(server.saves['om@example.com'], {'xp': 7});
      cloud.close();
    });

    test('an expired login is reported so the player can log in again', () async {
      final server = FakeAccountServer(); // nobody logged in -> 401
      final cloud = CloudProgressStorage(service: server.service());
      await cloud.write('{"xp":1}');
      await settle();
      expect(cloud.state.value, SyncState.signedOut);
      cloud.close();
    });
  });

  group('SessionController', () {
    late FakeAccountServer server;
    late ProgressController progress;
    late MemoryProgressStorage guest;
    late SessionController session;

    setUp(() {
      server = FakeAccountServer();
      progress = ProgressController(storage: MemoryProgressStorage());
      guest = MemoryProgressStorage();
      session = SessionController(progress: progress, accounts: server.service(), guestStorage: guest);
    });

    tearDown(() => session.dispose());

    test('THE BUG: a new account starts fresh, never with the last player\'s levels', () async {
      await session.register(name: 'Om', email: 'om@example.com', password: 'blue-tiger-42');
      progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
      progress.recordResult(levelById('py-2')!, stars: 2, correct: 4);
      await settle();
      expect(progress.completedLevels, 2);

      // Same device, next person.
      await session.switchPlayer();
      expect(progress.completedLevels, 0, reason: 'wiped from memory on switch');
      expect(progress.xp, 0);

      await session.register(name: 'Priya', email: 'priya@example.com', password: 'green-lion-77');
      expect(session.displayName, 'Priya');
      expect(progress.completedLevels, 0, reason: 'a new ID starts at zero');
      expect(progress.isUnlocked(levelById('py-2')!), isFalse);

      // And Om still has his own progress when he comes back.
      await session.switchPlayer();
      await session.login(email: 'om@example.com', password: 'blue-tiger-42');
      expect(progress.completedLevels, 2);
      expect(progress.starsFor('py-1'), 3);
    });

    test('account progress is never written to the device', () async {
      await session.register(name: 'Om', email: 'om@example.com', password: 'blue-tiger-42');
      progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
      await settle();
      await session.switchPlayer();
      expect(guest.data, isNull, reason: 'guest slot untouched');
      expect(server.saves['om@example.com'], isA<Map<String, Object?>>());
    });

    test('logging out tells the server and clears the session', () async {
      server.addAccount('om@example.com', 'Om', 'blue-tiger-42');
      await session.login(email: 'om@example.com', password: 'blue-tiger-42');
      expect(server.loggedIn, 'om@example.com');
      await session.switchPlayer();
      expect(server.loggedIn, isNull);
      expect(session.kind, PlayerKind.none);
    });

    test('wrong password: friendly error and nothing changes', () async {
      server.addAccount('om@example.com', 'Om', 'blue-tiger-42', progress: {'xp': 500});
      await session.playAsGuest();
      progress.recordResult(levelById('c-1')!, stars: 1, correct: 1);
      await expectLater(
        session.login(email: 'om@example.com', password: 'wrong-pass'),
        throwsA(isA<AccountException>().having((e) => e.message, 'message', 'Email or password is wrong.')),
      );
      expect(session.isGuest, isTrue);
      expect(progress.starsFor('c-1'), 1);
    });

    test('guest progress can move into a new account (and leaves the device)', () async {
      await session.playAsGuest();
      progress.recordResult(levelById('java-1')!, stars: 2, correct: 3);
      await settle();
      await session.register(
        name: 'Om',
        email: 'om@example.com',
        password: 'blue-tiger-42',
        bringGuestProgress: true,
      );
      expect(progress.starsFor('java-1'), 2);
      final saved = server.saves['om@example.com']! as Map;
      expect((saved['stars'] as Map)['java-1'], 2);
      expect(GuestSummary.fromJson(guest.data), isNull, reason: 'guest game moved, not copied');
    });

    test('new guest game starts fresh; continue keeps the old one', () async {
      await session.playAsGuest();
      progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
      await settle();
      await session.switchPlayer();
      expect((await session.guestSummary())!.stars, 3);

      await session.playAsGuest();
      expect(progress.starsFor('py-1'), 3);
      await session.switchPlayer();

      await session.playAsGuest(fresh: true);
      expect(progress.starsFor('py-1'), 0);
      expect(await session.guestSummary(), isNull);
    });

    test('settings stay when players switch (high contrast is not lost)', () async {
      progress.updateSettings(const AppSettings(highContrast: true));
      await session.register(name: 'Om', email: 'om@example.com', password: 'blue-tiger-42');
      expect(progress.settings.highContrast, isTrue);
      await session.switchPlayer();
      expect(progress.settings.highContrast, isTrue);
    });

    test('restore logs the player back in after a reload', () async {
      server.addAccount('om@example.com', 'Om', 'blue-tiger-42', progress: {
        'version': 1,
        'stars': {'py-1': 2},
        'xp': 40,
      });
      server.loggedIn = 'om@example.com'; // the cookie is still there
      await session.restore();
      expect(session.isAccount, isTrue);
      expect(session.displayName, 'Om');
      expect(progress.starsFor('py-1'), 2);
    });

    test('restore when offline leaves the choice to the player', () async {
      server.offline = true;
      await session.restore();
      expect(session.kind, PlayerKind.none);
      expect(session.restoring, isFalse);
    });

    test('deleting the account removes it and its progress', () async {
      await session.register(name: 'Om', email: 'om@example.com', password: 'blue-tiger-42');
      progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
      await settle();
      await expectLater(session.deleteAccount('wrong'), throwsA(isA<AccountException>()));
      await session.deleteAccount('blue-tiger-42');
      expect(server.accounts, isEmpty);
      expect(server.saves, isEmpty);
      expect(session.kind, PlayerKind.none);
      expect(progress.completedLevels, 0);
    });

    test('without a server, accounts are hidden and guest play still works', () async {
      final offline = SessionController(progress: progress, guestStorage: guest);
      expect(offline.accountsEnabled, isFalse);
      await offline.restore();
      await offline.playAsGuest();
      expect(offline.isGuest, isTrue);
      await expectLater(
        offline.login(email: 'om@example.com', password: 'blue-tiger-42'),
        throwsA(isA<AccountException>()),
      );
      offline.dispose();
    });
  });

  group('device storage', () {
    test('the old shared save becomes the guest game, once', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsProgressStorage.legacyKey: '{"xp":90,"stars":{"py-1":3}}',
      });
      await SharedPrefsProgressStorage.migrateLegacy();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SharedPrefsProgressStorage.legacyKey), isNull);
      expect(GuestSummary.fromJson(prefs.getString(SharedPrefsProgressStorage.guestKey))!.stars, 3);
    });

    test('device settings are remembered without any progress', () async {
      SharedPreferences.setMockInitialValues({});
      final progress = ProgressController(storage: MemoryProgressStorage());
      DeviceSettings.keepInSync(progress);
      progress.updateSettings(const AppSettings(highContrast: true, textScale: 1.3));
      progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
      await settle();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(DeviceSettings.key)!;
      expect(stored, isNot(contains('stars')));
      final loaded = await DeviceSettings.load();
      expect(loaded!.highContrast, isTrue);
      expect(loaded.textScale, 1.3);
    });

    test('guest summary ignores empty or broken saves', () {
      expect(GuestSummary.fromJson(null), isNull);
      expect(GuestSummary.fromJson('{}'), isNull);
      expect(GuestSummary.fromJson('not json'), isNull);
      expect(GuestSummary.fromJson('{"xp":0,"stars":{}}'), isNull);
      expect(GuestSummary.fromJson('{"xp":250,"stars":{"py-1":3,"py-2":9}}')!.stars, 6);
    });
  });

  test('switchStorage wipes the old player before loading the new one', () async {
    final a = MemoryProgressStorage(jsonEncode({
      'stars': {'py-1': 3},
      'xp': 100,
      'coins': 50,
      'achievements': ['first_steps'],
    }));
    final progress = ProgressController(storage: a);
    await progress.load();
    expect(progress.hasProgress, isTrue);
    await progress.switchStorage(MemoryProgressStorage());
    expect(progress.hasProgress, isFalse);
    expect(progress.coins, 0);
    expect(progress.hasAchievement('first_steps'), isFalse);
  });
}
