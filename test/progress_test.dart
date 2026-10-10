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
      ..updateSettings(const AppSettings(highContrast: true, timerMode: TimerMode.off, textScale: 1.3));
    await Future<void>.delayed(Duration.zero);
    final loaded = ProgressController(storage: storage, clock: () => now);
    await loaded.load();
    expect(loaded.starsFor('cpp-1'), 3);
    expect(loaded.xp, progress.xp);
    expect(loaded.settings.highContrast, isTrue);
    expect(loaded.settings.timerMode, TimerMode.off);
    expect(loaded.settings.textScale, 1.3);
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

  test('reset clears progress but keeps settings', () {
    progress
      ..updateSettings(const AppSettings(reduceMotion: true))
      ..recordResult(levelById('py-1')!, stars: 3, correct: 5)
      ..resetProgress();
    expect(progress.totalStars, 0);
    expect(progress.xp, 0);
    expect(progress.settings.reduceMotion, isTrue);
  });
}
