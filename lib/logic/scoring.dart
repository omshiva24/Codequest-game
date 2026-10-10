/// Pure scoring rules, kept separate from the UI so they are easy to test.
library;

/// Stars for a quiz-style level (runner or battle).
///
/// 3 = every answer right first time, 2 = 80%+, 1 = finished the level.
/// 0 = the player ran out of hearts.
int quizStars({
  required int firstTryCorrect,
  required int total,
  required bool won,
}) {
  if (!won || total <= 0) return 0;
  final ratio = firstTryCorrect / total;
  if (ratio >= 1) return 3;
  if (ratio >= 0.8) return 2;
  return 1;
}

/// Stars for a puzzle level. Wrong checks and hints both count as mistakes.
int puzzleStars({required int mistakes, required bool won}) {
  if (!won) return 0;
  if (mistakes <= 0) return 3;
  if (mistakes <= 2) return 2;
  return 1;
}

/// XP earned for finishing a level.
int xpFor({required int correct, required int stars, required bool isBoss}) {
  final safeCorrect = correct < 0 ? 0 : correct;
  final safeStars = stars.clamp(0, 3);
  final bossBonus = (isBoss && safeStars > 0) ? 30 : 0;
  return safeCorrect * 10 + safeStars * 10 + bossBonus;
}

/// Coins earned for finishing a level.
int coinsFor({required int correct, required int stars}) {
  final safeCorrect = correct < 0 ? 0 : correct;
  return safeCorrect * 5 + stars.clamp(0, 3) * 5;
}

const int xpPerPlayerLevel = 150;

int playerLevelFor(int xp) => 1 + (xp < 0 ? 0 : xp) ~/ xpPerPlayerLevel;

/// Progress (0..1) towards the next player level.
double levelProgressFor(int xp) =>
    ((xp < 0 ? 0 : xp) % xpPerPlayerLevel) / xpPerPlayerLevel;

String rankTitleFor(int playerLevel) {
  if (playerLevel >= 12) return 'Code Wizard';
  if (playerLevel >= 8) return 'Loop Legend';
  if (playerLevel >= 5) return 'Bug Squasher';
  if (playerLevel >= 3) return 'Junior Coder';
  return 'Newbie Coder';
}
