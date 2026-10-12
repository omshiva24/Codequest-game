// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'dart:convert';

import 'package:codequest/data/curriculum.dart';
import 'package:codequest/logic/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late MemoryProgressStorage storage;
  late ProgressController progress;

  setUp(() {
    now = DateTime(2026, 10, 10, 12);
    storage = MemoryProgressStorage();
    progress = ProgressController(storage: storage, clock: () => now);
  });

  test('only level 1 of each world is unlocked at the start', () {
    for (final level in allLevels) {
      expect(progress.isUnlocked(level), level.number == 1, reason: level.id);
    }
  });

  test('finishing a level unlocks the next one and saves', () async {
    final py1 = levelById('py-1')!;
    final reward = progress.recordResult(py1, stars: 2, correct: 4);
    expect(reward.stars, 2);
    expect(reward.newBest, isTrue);
    expect(reward.unlockedNext?.id, 'py-2');
    expect(progress.isUnlocked(levelById('py-2')!), isTrue);
    expect(progress.xp, reward.xp);
    await Future<void>.delayed(Duration.zero);
    expect(storage.data, contains('"py-1":2'));
  });

  test('a failed attempt (0 stars) keeps the next level locked', () {
    progress.recordResult(levelById('c-1')!, stars: 0, correct: 1);
    expect(progress.isUnlocked(levelById('c-2')!), isFalse);
  });

  test('keeps the best star count', () {
    final level = levelById('java-1')!;
    progress.recordResult(level, stars: 3, correct: 5);
    final again = progress.recordResult(level, stars: 1, correct: 3);
    expect(progress.starsFor('java-1'), 3);
    expect(again.newBest, isFalse);
  });

  test('daily streak grows on consecutive days and resets after a gap', () {
    final level = levelById('py-1')!;
    progress.recordResult(level, stars: 1, correct: 3);
    expect(progress.streak, 1);
    progress.recordResult(level, stars: 1, correct: 3);
    expect(progress.streak, 1, reason: 'same day');
    now = now.add(const Duration(days: 1));
    progress.recordResult(level, stars: 1, correct: 3);
    expect(progress.streak, 2);
    now = now.add(const Duration(days: 3));
    progress.recordResult(level, stars: 1, correct: 3);
    expect(progress.streak, 1);
  });

  test('round-trips through storage', () async {
    progress
      ..recordResult(levelById('cpp-1')!, stars: 3, correct: 5)
      ..updateSettings(const AppSettings(
        highContrast: true,
        timerMode: TimerMode.off,
        textScale: 1.3,
        soundOn: false,
      ));
    await Future<void>.delayed(Duration.zero);
    final loaded = ProgressController(storage: storage, clock: () => now);
    await loaded.load();
    expect(loaded.starsFor('cpp-1'), 3);
    expect(loaded.xp, progress.xp);
    expect(loaded.settings.highContrast, isTrue);
    expect(loaded.settings.timerMode, TimerMode.off);
    expect(loaded.settings.textScale, 1.3);
    expect(loaded.settings.soundOn, isFalse);
  });

  test('sound is on by default, also for saves made before the sound setting existed', () {
    expect(const AppSettings().soundOn, isTrue);
    expect(AppSettings.fromJson({'highContrast': true}).soundOn, isTrue);
    expect(AppSettings.fromJson({'soundOn': 'nope'}).soundOn, isTrue);
    expect(AppSettings.fromJson({'soundOn': false}).soundOn, isFalse);
  });

  test('ignores corrupted saved data', () async {
    storage.data = '{not json';
    await progress.load();
    expect(progress.xp, 0);
    expect(progress.totalStars, 0);
  });

  test('clamps tampered values and drops unknown levels', () async {
    storage.data = jsonEncode({
      'stars': {'py-1': 99, 'hacker-level': 3, 'c-1': -5},
      'xp': -100,
      'coins': 999999999999,
      'streak': 'lots',
      'lastPlayDay': '<script>',
      'settings': {'timerMode': 'turbo', 'textScale': 7, 'highContrast': 'yes'},
    });
    await progress.load();
    expect(progress.starsFor('py-1'), 3);
    expect(progress.starsFor('c-1'), 0);
    expect(progress.starsFor('hacker-level'), 0);
    expect(progress.xp, 0);
    expect(progress.coins, lessThanOrEqualTo(10000000));
    expect(progress.streak, 0);
    expect(progress.settings.timerMode, TimerMode.normal);
    expect(progress.settings.textScale, 1.0);
    expect(progress.settings.highContrast, isFalse);
  });

  test('badges unlock as the player progresses', () {
    final first = progress.recordResult(levelById('py-1')!, stars: 2, correct: 4);
    expect(first.newAchievements.map((a) => a.id), contains('first_steps'));
    expect(progress.hasAchievement('flawless'), isFalse);

    final perfect = progress.recordResult(levelById('py-2')!, stars: 3, correct: 5, bestCombo: 5);
    expect(perfect.newAchievements.map((a) => a.id), containsAll(['flawless', 'combo_5']));

    // Badges are only reported once.
    final again = progress.recordResult(levelById('py-2')!, stars: 3, correct: 5, bestCombo: 5);
    expect(again.newAchievements, isEmpty);

    expect(progress.markAskedDoubt().map((a) => a.id), ['curious']);
    expect(progress.markAskedDoubt(), isEmpty);
  });

  test('beating a boss and every language unlock more badges', () {
    for (final id in ['py-1', 'c-1', 'cpp-1', 'java-1']) {
      progress.recordResult(levelById(id)!, stars: 1, correct: 3);
    }
    expect(progress.hasAchievement('polyglot'), isTrue);
    for (final id in ['py-2', 'py-3', 'py-4', 'py-5']) {
      progress.recordResult(levelById(id)!, stars: 1, correct: 3);
    }
    expect(progress.hasAchievement('boss_slayer'), isTrue);
    expect(progress.hasAchievement('world_champ'), isTrue);
    expect(progress.hasAchievement('code_master'), isFalse);
  });

  test('spending coins only works when the player can afford it', () {
    expect(progress.spendCoins(15), isFalse);
    progress.recordResult(levelById('py-1')!, stars: 3, correct: 5);
    final coins = progress.coins;
    expect(progress.spendCoins(15), isTrue);
    expect(progress.coins, coins - 15);
    expect(progress.spendCoins(100000), isFalse);
    expect(progress.spendCoins(-5), isFalse);
    expect(progress.coins, coins - 15);
  });

  test('badges and combo survive saving, unknown badges are dropped', () async {
    progress
      ..recordResult(levelById('py-1')!, stars: 3, correct: 5, bestCombo: 4)
      ..markAskedDoubt();
    await Future<void>.delayed(Duration.zero);
    final saved = jsonDecode(storage.data!) as Map<String, dynamic>;
    saved['achievements'] = [...(saved['achievements'] as List<dynamic>), 'hacked_badge', 42];
    storage.data = jsonEncode(saved);
    final loaded = ProgressController(storage: storage, clock: () => now);
    await loaded.load();
    expect(loaded.bestCombo, 4);
    expect(loaded.hasAchievement('first_steps'), isTrue);
    expect(loaded.hasAchievement('curious'), isTrue);
    expect(loaded.hasAchievement('hacked_badge'), isFalse);
    expect(loaded.achievementCount, progress.achievementCount);
  });

  test('reset clears progress but keeps settings', () {
    progress
      ..updateSettings(const AppSettings(reduceMotion: true))
      ..recordResult(levelById('py-1')!, stars: 3, correct: 5)
      ..resetProgress();
    expect(progress.totalStars, 0);
    expect(progress.xp, 0);
    expect(progress.settings.reduceMotion, isTrue);
    expect(progress.achievementCount, 0);
    expect(progress.bestCombo, 0);
  });
}
