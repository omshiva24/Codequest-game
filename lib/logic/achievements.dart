// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:flutter/foundation.dart';

/// A badge the player can unlock. Badges reward good learning habits
/// (finishing levels, perfect answers, asking questions, coming back daily).
@immutable
class Achievement {
  const Achievement(this.id, this.emoji, this.title, this.description);

  final String id;
  final String emoji;
  final String title;
  final String description;
}

const List<Achievement> achievements = [
  Achievement('first_steps', '👣', 'First steps', 'Finish your first level.'),
  Achievement('flawless', '💎', 'Flawless', 'Get 3 stars on a level.'),
  Achievement('combo_5', '⚡', 'Combo king', 'Answer 5 questions right in a row.'),
  Achievement('curious', '🦉', 'Curious mind', 'Ask Byte the Doubt Buddy a question.'),
  Achievement('boss_slayer', '⚔️', 'Boss slayer', 'Beat a boss level.'),
  Achievement('polyglot', '🌍', 'Polyglot', 'Finish a level in all four languages.'),
  Achievement('streak_3', '🔥', 'On fire', 'Play three days in a row.'),
  Achievement('rich', '💰', 'Coin hoarder', 'Have 300 coins at once.'),
  Achievement('star_30', '⭐', 'Star collector', 'Collect 30 stars.'),
  Achievement('world_champ', '🏆', 'World champion', 'Finish every level in one world.'),
  Achievement('code_master', '👑', 'Code master', 'Finish all 20 levels.'),
];

Achievement? achievementById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}

/// What the player has done so far, used to check badges.
@immutable
class PlayerStats {
  const PlayerStats({
    required this.levelsDone,
    required this.totalLevels,
    required this.threeStarLevels,
    required this.bossesBeaten,
    required this.languagesStarted,
    required this.worldsCompleted,
    required this.totalStars,
    required this.bestCombo,
    required this.askedDoubt,
    required this.streak,
    required this.coins,
  });

  final int levelsDone;
  final int totalLevels;
  final int threeStarLevels;
  final int bossesBeaten;
  final int languagesStarted;
  final int worldsCompleted;
  final int totalStars;
  final int bestCombo;
  final bool askedDoubt;
  final int streak;
  final int coins;
}

bool isEarned(Achievement a, PlayerStats s) => switch (a.id) {
      'first_steps' => s.levelsDone >= 1,
      'flawless' => s.threeStarLevels >= 1,
      'combo_5' => s.bestCombo >= 5,
      'curious' => s.askedDoubt,
      'boss_slayer' => s.bossesBeaten >= 1,
      'polyglot' => s.languagesStarted >= 4,
      'streak_3' => s.streak >= 3,
      'rich' => s.coins >= 300,
      'star_30' => s.totalStars >= 30,
      'world_champ' => s.worldsCompleted >= 1,
      'code_master' => s.totalLevels > 0 && s.levelsDone >= s.totalLevels,
      _ => false,
    };
