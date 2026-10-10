import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/quiz_session.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// Pokemon-style battle: right answers hit the bug monster.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.level, this.random});

  final Level level;
  final Random? random;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  late final QuizSession _session = QuizSession(
    widget.level.questions,
    random: widget.random,
    requeueWrong: true,
  );
  late final AnimationController _enemyHit;
  late final AnimationController _playerHit;
  final FocusNode _focus = FocusNode(debugLabel: 'battle-game');
  final GlobalKey _feedbackKey = GlobalKey();

  AnswerResult? _last;
  late String _log;

  Enemy get _enemy => widget.level.enemy ?? const Enemy('Bug', '🐛');

  @override
  void initState() {
    super.initState();
    _enemyHit = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _playerHit = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _log = 'A wild ${_enemy.name} appeared! Answer correctly to attack.';
  }

  @override
  void dispose() {
    _enemyHit.dispose();
    _playerHit.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _answer(int index) {
    if (_last != null || _session.isOver) return;
    final result = _session.answer(index);
    final reduceMotion = reduceMotionOf(context, listen: false);
    setState(() {
      _last = result;
      if (result.correct) {
        _log = _session.won
            ? 'Critical hit! ${_enemy.name} is defeated!'
            : "It's super effective! ${_enemy.name} took a hit.";
      } else {
        _log = _session.lives <= 0
            ? '${_enemy.name} knocked you out!'
            : '${_enemy.name} attacks! You lost a heart. This question will come back.';
      }
    });
    if (!reduceMotion) {
      (result.correct ? _enemyHit : _playerHit).forward(from: 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
      }
    });
  }

  void _next() {
    if (_session.isOver) {
      _finish();
      return;
    }
    setState(() {
      _last = null;
      _log = 'Your move! ${_session.remaining} hit${_session.remaining == 1 ? '' : 's'} to win.';
    });
    _focus.requestFocus();
  }

  void _finish() {
    final s = _session;
    finishLevel(
      context,
      GameOutcome(
        level: widget.level,
        won: s.won,
        correct: s.firstTryCorrect,
        total: s.total,
        stars: quizStars(firstTryCorrect: s.firstTryCorrect, total: s.total, won: s.won),
        review: [
          for (final q in s.missed)
            ReviewItem(
              prompt: q.prompt,
              code: q.code,
              correctAnswer: q.correctText,
              explanation: q.explanation,
            ),
        ],
      ),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _last != null) return KeyEventResult.ignored;
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ];
    const numpad = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
    ];
    var index = digits.indexOf(event.logicalKey);
    if (index < 0) index = numpad.indexOf(event.logicalKey);
    final q = _session.current;
    if (index >= 0 && q != null && index < q.options.length) {
      _answer(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final last = _last;
    final question = last?.question ?? _session.current;
    final enemyHp = (_session.total - _session.solved) / _session.total;

    return QuitGuard(
      active: !_session.isOver,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.level.title)),
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: PageBody(
            maxWidth: 720,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ---- Arena ----
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: g.border, width: 2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [widget.level.lang.color.withValues(alpha: 0.22), g.card],
                    ),
                  ),
                  child: Column(
                    children: [
                      _Fighter(
                        name: _enemy.name,
                        emoji: _enemy.emoji,
                        alignEnd: true,
                        hit: _enemyHit,
                        status: Semantics(
                          label: '${_enemy.name} health',
                          value: '${(enemyHp * 100).round()} percent',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: enemyHp,
                              minHeight: 12,
                              color: g.bad,
                              backgroundColor: g.background,
                            ),
                          ),
                        ),
                        big: widget.level.isBoss,
                      ),
                      const SizedBox(height: 10),
                      _Fighter(
                        name: 'You',
                        emoji: '🧑‍💻',
                        alignEnd: false,
                        hit: _playerHit,
                        status: HeartsBar(lives: _session.lives, max: _session.maxLives),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ---- Battle log (read aloud by screen readers) ----
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: g.codeBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: g.border),
                    ),
                    child: Text(_log, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                if (question != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(question.source.prompt,
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w700, height: 1.35)),
                          ),
                          if (question.source.code != null) ...[
                            const SizedBox(height: 10),
                            CodeBlock(question.source.code!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (last == null)
                    _MoveGrid(
                      options: question.options,
                      color: widget.level.lang.color,
                      onSelected: _answer,
                    )
                  else
                    FeedbackPanel(
                      key: _feedbackKey,
                      correct: last.correct,
                      headline: last.correct ? 'Hit!' : 'Missed!',
                      correctAnswer: last.correct ? null : last.question.correctText,
                      explanation: last.question.source.explanation,
                      continueLabel: _session.isOver ? 'See results' : 'Next move',
                      onContinue: _next,
                      onAskBuddy: last.correct
                          ? null
                          : () => openDoubtBuddy(
                                context,
                                lang: widget.level.lang,
                                question:
                                    'Why is the answer "${last.question.correctText}"? ${last.question.source.prompt}',
                                extraContext:
                                    '${last.question.source.code ?? ''}\nExplanation: ${last.question.source.explanation}',
                              ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fighter extends StatelessWidget {
  const _Fighter({
    required this.name,
    required this.emoji,
    required this.alignEnd,
    required this.hit,
    required this.status,
    this.big = false,
  });

  final String name;
  final String emoji;
  final bool alignEnd;
  final Animation<double> hit;
  final Widget status;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final avatar = AnimatedBuilder(
      animation: hit,
      builder: (context, child) {
        final t = hit.value;
        final shake = t == 0 || t == 1 ? 0.0 : sin(t * pi * 6) * 10 * (1 - t);
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Opacity(opacity: t > 0 && t < 1 ? 0.6 + 0.4 * (1 - sin(t * pi)) : 1, child: child),
        );
      },
      child: Container(
        width: big ? 92 : 76,
        height: big ? 92 : 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: g.cardRaised,
          border: Border.all(color: g.border, width: 3),
        ),
        child: Emoji(emoji, size: big ? 50 : 40),
      ),
    );
    final info = Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: g.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: g.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            status,
          ],
        ),
      ),
    );
    return Row(
      children: alignEnd
          ? [info, const SizedBox(width: 12), avatar]
          : [avatar, const SizedBox(width: 12), info],
    );
  }
}

class _MoveGrid extends StatelessWidget {
  const _MoveGrid({required this.options, required this.color, required this.onSelected});

  final List<String> options;
  final Color color;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 420 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < options.length; i++)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      label: 'Move ${i + 1}: ${options[i]}',
                      excludeSemantics: true,
                      onTap: () => onSelected(i),
                      child: Material(
                        color: g.cardRaised,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: color, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onSelected(i),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 60),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700, color: g.onAccent)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      options[i],
                                      style: const TextStyle(
                                        fontFamily: codeFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Tip: press 1-4 on your keyboard to attack.',
                style: TextStyle(color: g.textDim, fontSize: 14)),
          ],
        );
      },
    );
  }
}
