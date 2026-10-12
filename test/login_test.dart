// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// "Who's playing?" end to end in the app (with a pretend server).

import 'dart:async';

import 'package:codequest/app.dart';
import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/progress.dart';
import 'package:codequest/logic/session.dart';
import 'package:codequest/screens/home_screen.dart';
import 'package:codequest/screens/login_screen.dart';
import 'package:codequest/screens/title_screen.dart';
import 'package:codequest/services/doubt_service.dart';
import 'package:codequest/widgets/game_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_account_server.dart';

const _calm = AppSettings(reduceMotion: true, timerMode: TimerMode.off);

class Rig {
  Rig(this.server, this.progress, this.guest, this.session);

  final FakeAccountServer server;
  final ProgressController progress;
  final MemoryProgressStorage guest;
  final SessionController session;
}

Future<Rig> pumpRig(WidgetTester tester, {FakeAccountServer? server, String? guestSave}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final s = server ?? FakeAccountServer();
  final progress = ProgressController(storage: MemoryProgressStorage())..updateSettings(_calm);
  final guest = MemoryProgressStorage(guestSave);
  final session = SessionController(progress: progress, accounts: s.service(), guestStorage: guest);
  await tester.pumpWidget(CodeQuestApp(controller: progress, session: session, doubtService: DoubtService()));
  // The pretend server answers with microtasks only, so everything runs in
  // the test's fake time (no real waiting).
  unawaited(session.restore());
  await tester.pumpAndSettle();
  return Rig(s, progress, guest, session);
}

/// A game button, or a dialog button, with this label.
Finder labelled(String text) {
  final game = find.widgetWithText(GameButton, text);
  return game.evaluate().isNotEmpty ? game : find.widgetWithText(TextButton, text);
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = labelled(text);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

/// Taps a button whose work talks to the (fake) server.
Future<void> tapAndWait(WidgetTester tester, String text) async {
  await tapText(tester, text);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new visitor must choose who is playing', (tester) async {
    await pumpRig(tester);
    expect(find.textContaining('Play as a guest, or log in'), findsOneWidget);
    await tapText(tester, 'Play');
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('Play as guest'), findsWidgets);
    expect(find.text('Log in'), findsWidgets);
  });

  testWidgets('play as guest goes to the hub', (tester) async {
    final rig = await pumpRig(tester);
    await tapText(tester, 'Play');
    await tapAndWait(tester, 'Play as guest');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(rig.session.isGuest, isTrue);
    expect(find.bySemanticsLabel(RegExp(r'^Guest, ')), findsOneWidget);
  });

  testWidgets('create an account, play, switch player: the next person starts fresh', (tester) async {
    final rig = await pumpRig(tester);
    await tapText(tester, 'Play');
    await tapText(tester, 'New here? Create an account');
    await tester.enterText(find.widgetWithText(TextFormField, 'Player name'), 'Om');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'om@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'blue-tiger-42');
    await tapAndWait(tester, 'Create account');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Om'), findsOneWidget);
    expect(rig.server.accounts.keys, ['om@example.com']);

    // Om plays a level.
    rig.progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
    await tester.pumpAndSettle();
    expect(rig.server.saves['om@example.com'], isNotNull);

    // Switch player from the hub.
    await tester.tap(find.byTooltip('Switch player or log out'));
    await tester.pumpAndSettle();
    await tapAndWait(tester, 'Log out');
    expect(find.byType(TitleScreen), findsOneWidget);
    expect(rig.progress.completedLevels, 0);
    expect(rig.server.loggedIn, isNull);

    // A friend makes their own account on the same device.
    await tapText(tester, 'Play');
    await tapText(tester, 'New here? Create an account');
    await tester.enterText(find.widgetWithText(TextFormField, 'Player name'), 'Priya');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'priya@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'green-lion-77');
    await tapAndWait(tester, 'Create account');
    expect(find.text('Priya'), findsOneWidget);
    expect(rig.progress.completedLevels, 0);
    expect(find.bySemanticsLabel(RegExp(r'^0 of \d+ stars$')), findsOneWidget);
  });

  testWidgets('log in shows a clear error for a wrong password', (tester) async {
    final server = FakeAccountServer()..addAccount('om@example.com', 'Om', 'blue-tiger-42');
    await pumpRig(tester, server: server);
    await tapText(tester, 'Play');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'om@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'not-my-password');
    await tapAndWait(tester, 'Log in');
    expect(find.text('Email or password is wrong.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('the form checks input before sending anything', (tester) async {
    final rig = await pumpRig(tester);
    await tapText(tester, 'Play');
    await tapText(tester, 'New here? Create an account');
    await tester.enterText(find.widgetWithText(TextFormField, 'Player name'), 'O');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'short');
    await tapAndWait(tester, 'Create account');
    expect(find.text('Use 2 to 20 letters or numbers.'), findsOneWidget);
    expect(find.text('That email does not look right.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(rig.server.calls.where((c) => c == 'POST'), isEmpty);
  });

  testWidgets('a returning player is welcomed and can hand over the device', (tester) async {
    final server = FakeAccountServer()
      ..addAccount('om@example.com', 'Om', 'blue-tiger-42', progress: {'version': 1, 'xp': 40})
      ..loggedIn = 'om@example.com';
    final rig = await pumpRig(tester, server: server);
    expect(find.textContaining('Welcome back, Om!'), findsOneWidget);
    await tapAndWait(tester, 'Not you? Switch player');
    expect(rig.session.kind, PlayerKind.none);
    expect(rig.progress.xp, 0);
    expect(find.textContaining('Play as a guest, or log in'), findsOneWidget);
  });

  testWidgets('an existing guest game can be continued or replaced', (tester) async {
    await pumpRig(tester, guestSave: '{"xp":90,"stars":{"py-1":3}}');
    await tapText(tester, 'Play');
    expect(find.text('Continue guest game'), findsOneWidget);
    expect(find.text('New guest game'), findsOneWidget);
    await tapText(tester, 'New here? Create an account');
    expect(find.textContaining('Bring my guest game into this account'), findsOneWidget);
    await tapText(tester, 'New guest game');
    expect(find.text('Start a new guest game?'), findsOneWidget);
    await tapText(tester, 'Cancel');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
