import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/curriculum.dart';
import '../models/models.dart';
import 'achievements.dart';
import 'scoring.dart';

enum TimerMode {
  normal('Normal', 'Gates move at normal speed.'),
  relaxed('Relaxed', 'Twice as much time to think.'),
  off('No timer', 'Gates wait until you press Go.');

  const TimerMode(this.label, this.description);

  final String label;
  final String description;
}

/// Player-chosen accessibility and game options.
@immutable
class AppSettings {
  const AppSettings({
    this.highContrast = false,
    this.reduceMotion = false,
    this.timerMode = TimerMode.normal,
    this.textScale = 1.0,
    this.soundOn = true,
  });

  static const List<double> textScales = [1.0, 1.15, 1.3];

  final bool highContrast;
  final bool reduceMotion;
  final TimerMode timerMode;
  final double textScale;
  final bool soundOn;

  AppSettings copyWith({
    bool? highContrast,
    bool? reduceMotion,
    TimerMode? timerMode,
    double? textScale,
    bool? soundOn,
  }) =>
      AppSettings(
        highContrast: highContrast ?? this.highContrast,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        timerMode: timerMode ?? this.timerMode,
        textScale: textScale ?? this.textScale,
        soundOn: soundOn ?? this.soundOn,
      );

  Map<String, Object> toJson() => {
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
        'timerMode': timerMode.name,
        'textScale': textScale,
        'soundOn': soundOn,
      };

  /// Reads settings defensively: anything unexpected falls back to defaults.
  factory AppSettings.fromJson(Object? json) {
    if (json is! Map) return const AppSettings();
    final mode = TimerMode.values
        .where((m) => m.name == json['timerMode'])
        .firstOrNull;
    final scale = json['textScale'];
    return AppSettings(
      highContrast: json['highContrast'] == true,
      reduceMotion: json['reduceMotion'] == true,
      timerMode: mode ?? TimerMode.normal,
      textScale: (scale is num && textScales.contains(scale.toDouble()))
          ? scale.toDouble()
          : 1.0,
      // Sound is on unless the player switched it off.
      soundOn: json['soundOn'] != false,
    );
  }
}

/// Where progress is saved. Swappable so tests can use memory.
abstract class ProgressStorage {
  Future<String?> read();
  Future<void> write(String data);
}

class MemoryProgressStorage implements ProgressStorage {
  MemoryProgressStorage([this.data]);

  String? data;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String value) async => data = value;
}

/// Saves to the browser's localStorage (web) or app preferences (mobile).
/// Only game progress is stored - no names, emails or other personal data.
class SharedPrefsProgressStorage implements ProgressStorage {
  static const String key = 'codequest.progress.v1';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }
}

class LevelReward {
  const LevelReward({
    required this.stars,
    required this.xp,
    required this.coins,
    required this.newBest,
    required this.leveledUp,
    required this.unlockedNext,
    this.newAchievements = const [],
  });

  final int stars;
  final int xp;
  final int coins;
  final bool newBest;
  final bool leveledUp;
  final Level? unlockedNext;
  final List<Achievement> newAchievements;
}

/// Holds the player's progress and settings, and saves them.
class ProgressController extends ChangeNotifier {
  ProgressController({required ProgressStorage storage, DateTime Function()? clock})
      : _storage = storage,
        _clock = clock ?? DateTime.now;

  static const int _maxCounter = 10000000;

  final ProgressStorage _storage;
  final DateTime Function() _clock;

  final Map<String, int> _stars = {};
  int _xp = 0;
  int _coins = 0;
  int _streak = 0;
  String? _lastPlayDay;
  int _bestCombo = 0;
  bool _askedDoubt = false;
  final Set<String> _achievements = {};
  AppSettings _settings = const AppSettings();

  int get xp => _xp;
  int get coins => _coins;
  int get streak => _streak;
  AppSettings get settings => _settings;
  int get playerLevel => playerLevelFor(_xp);
  double get levelProgress => levelProgressFor(_xp);
  String get rankTitle => rankTitleFor(playerLevel);

  int get bestCombo => _bestCombo;

  int starsFor(String levelId) => _stars[levelId] ?? 0;

  bool hasAchievement(String id) => _achievements.contains(id);

  int get achievementCount => _achievements.length;

  PlayerStats get stats {
    final done = allLevels.where((l) => starsFor(l.id) > 0).toList();
    return PlayerStats(
      levelsDone: done.length,
      totalLevels: allLevels.length,
      threeStarLevels: done.where((l) => starsFor(l.id) >= 3).length,
      bossesBeaten: done.where((l) => l.isBoss).length,
      languagesStarted: done.map((l) => l.lang).toSet().length,
      worldsCompleted: Lang.values
          .where((lang) => levelsFor(lang).every((l) => starsFor(l.id) > 0))
          .length,
      totalStars: totalStars,
      bestCombo: _bestCombo,
      askedDoubt: _askedDoubt,
      streak: _streak,
      coins: _coins,
    );
  }

  /// Unlocks any newly earned badges and returns them.
  List<Achievement> _checkAchievements() {
    final s = stats;
    final unlocked = <Achievement>[];
    for (final a in achievements) {
      if (!_achievements.contains(a.id) && isEarned(a, s)) {
        _achievements.add(a.id);
        unlocked.add(a);
      }
    }
    return unlocked;
  }

  int worldStars(Lang lang) =>
      levelsFor(lang).fold(0, (sum, l) => sum + starsFor(l.id));

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get completedLevels => _stars.values.where((s) => s > 0).length;

  bool isUnlocked(Level level) {
    final list = levelsFor(level.lang);
    final i = list.indexWhere((l) => l.id == level.id);
    if (i <= 0) return true;
    return starsFor(list[i - 1].id) > 0;
  }

  /// Loads saved data. Corrupted or tampered data is ignored safely.
  Future<void> load() async {
    String? raw;
    try {
      raw = await _storage.read();
    } catch (_) {
      raw = null;
    }
    if (raw != null && raw.length < 100000) {
      try {
        _applyJson(jsonDecode(raw));
      } on FormatException {
        // Ignore unreadable data and start fresh.
      }
    }
    notifyListeners();
  }

  void _applyJson(Object? json) {
    if (json is! Map) return;
    final stars = json['stars'];
    if (stars is Map) {
      stars.forEach((key, value) {
        if (key is String && value is int && levelById(key) != null) {
          _stars[key] = value.clamp(0, 3);
        }
      });
    }
    _xp = _readCounter(json['xp']);
    _coins = _readCounter(json['coins']);
    _streak = _readCounter(json['streak']).clamp(0, 100000);
    final day = json['lastPlayDay'];
    _lastPlayDay = (day is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day))
        ? day
        : null;
    _bestCombo = _readCounter(json['bestCombo']).clamp(0, 1000);
    _askedDoubt = json['askedDoubt'] == true;
    final badges = json['achievements'];
    if (badges is List) {
      for (final id in badges) {
        if (id is String && achievementById(id) != null) _achievements.add(id);
      }
    }
    _settings = AppSettings.fromJson(json['settings']);
  }

  int _readCounter(Object? v) => v is int ? v.clamp(0, _maxCounter) : 0;

  Map<String, Object?> toJson() => {
        'version': 1,
        'stars': Map<String, int>.of(_stars),
        'xp': _xp,
        'coins': _coins,
        'streak': _streak,
        'lastPlayDay': _lastPlayDay,
        'bestCombo': _bestCombo,
        'askedDoubt': _askedDoubt,
        'achievements': _achievements.toList(),
        'settings': _settings.toJson(),
      };

  Future<void> _save() async {
    try {
      await _storage.write(jsonEncode(toJson()));
    } catch (e) {
      debugPrint('CodeQuest: could not save progress ($e)');
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _touchStreak() {
    final now = _clock();
    final today = _dayKey(now);
    if (_lastPlayDay == today) return;
    final yesterday = _dayKey(DateTime(now.year, now.month, now.day - 1));
    _streak = (_lastPlayDay == yesterday) ? _streak + 1 : 1;
    _lastPlayDay = today;
  }

  /// Records a finished level and returns what the player earned.
  LevelReward recordResult(
    Level level, {
    required int stars,
    required int correct,
    int bestCombo = 0,
  }) {
    final safeStars = stars.clamp(0, 3);
    final oldLevel = playerLevel;
    final previousBest = starsFor(level.id);
    final wasNextLocked = nextLevel(level) != null && !isUnlocked(nextLevel(level)!);

    final xpGain = xpFor(correct: correct, stars: safeStars, isBoss: level.isBoss);
    final coinGain = coinsFor(correct: correct, stars: safeStars);
    _xp = (_xp + xpGain).clamp(0, _maxCounter);
    _coins = (_coins + coinGain).clamp(0, _maxCounter);
    if (safeStars > previousBest) _stars[level.id] = safeStars;
    if (bestCombo > _bestCombo) _bestCombo = bestCombo.clamp(0, 1000);
    _touchStreak();
    final newBadges = _checkAchievements();

    final next = nextLevel(level);
    final unlocked = (wasNextLocked && next != null && isUnlocked(next)) ? next : null;
    unawaited(_save());
    notifyListeners();
    return LevelReward(
      stars: safeStars,
      xp: xpGain,
      coins: coinGain,
      newBest: safeStars > previousBest,
      leveledUp: playerLevel > oldLevel,
      unlockedNext: unlocked,
      newAchievements: newBadges,
    );
  }

  /// Pays for a power-up. Returns false (and spends nothing) if the player
  /// does not have enough coins.
  bool spendCoins(int amount) {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    unawaited(_save());
    notifyListeners();
    return true;
  }

  /// Called when the player asks the Doubt Buddy something.
  List<Achievement> markAskedDoubt() {
    if (_askedDoubt) return const [];
    _askedDoubt = true;
    final newBadges = _checkAchievements();
    unawaited(_save());
    notifyListeners();
    return newBadges;
  }

  void updateSettings(AppSettings value) {
    _settings = value;
    unawaited(_save());
    notifyListeners();
  }

  /// Clears game progress but keeps accessibility settings.
  void resetProgress() {
    _stars.clear();
    _xp = 0;
    _coins = 0;
    _streak = 0;
    _lastPlayDay = null;
    _bestCombo = 0;
    _askedDoubt = false;
    _achievements.clear();
    unawaited(_save());
    notifyListeners();
  }
}
