import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/quiz_session.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// Pokémon-style battle: right answers fire a code bolt at the bug monster.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, required this.level, this.random});

  final Level level;
  final Random? random;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> with TickerProviderStateMixin {
  static const _moveTones = [ButtonTone.coral, ButtonTone.sky, ButtonTone.mint, ButtonTone.gold];

  late final QuizSession _session = QuizSession(
    widget.level.questions,
    random: widget.random,
    requeueWrong: true,
  );
  late final AnimationController _bolt;
  late final AnimationController _enemyHit;
  late final AnimationController _lunge;
  final FocusNode _focus = FocusNode(debugLabel: 'battle-game');
  final GlobalKey _feedbackKey = GlobalKey();

  AnswerResult? _last;
  late String _log;
  int _shakeTick = 0;
  int _damageTick = 0;
  int _victoryTick = 0;

  Enemy get _enemy => widget.level.enemy ?? const Enemy('Bug', '🐛');

  @override
  void initState() {
    super.initState();
    _bolt = AnimationController(vsync: this, duration: const Duration(milliseconds: 560))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          _enemyHit.forward(from: 0);
          setState(() => _damageTick++);
        }
      });
    _enemyHit = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _lunge = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _log = 'A wild ${_enemy.name} appeared! Answer correctly to attack.';
  }

  @override
  void dispose() {
    _bolt.dispose();
    _enemyHit.dispose();
    _lunge.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _reduceMotion => reduceMotionOf(context, listen: false);

  void _answer(int index) {
    if (_last != null || _session.isOver || _session.isHidden(index)) return;
    final result = _session.answer(index);
    setState(() {
      _last = result;
      if (result.correct) {
        final combo = _session.combo >= 2 ? ' Combo x${_session.combo}!' : '';
        _log = _session.won
            ? 'Critical hit! ${_enemy.name} is defeated!'
            : "It's super effective! ${_enemy.name} took a hit.$combo";
        if (_session.won) _victoryTick++;
        SoundFx.play(Sfx.hit);
      } else {
        _log = _session.lives <= 0
            ? '${_enemy.name} knocked you out!'
            : '${_enemy.name} attacks! You lost a heart. This question will come back.';
        _shakeTick++;
        SoundFx.play(Sfx.wrong);
      }
    });
    if (_reduceMotion) {
      if (result.correct) _damageTick++;
    } else {
      (result.correct ? _bolt : _lunge).forward(from: 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  void _useFiftyFifty() {
    if (!_session.canUseFiftyFifty || _last != null) return;
    if (!AppScope.read(context).spendCoins(fiftyFiftyCost)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('You need $fiftyFiftyCost coins for 50/50. Finish levels to earn coins.'),
        ));
      return;
    }
    SoundFx.play(Sfx.powerUp);
    setState(() {
      _session.useFiftyFifty();
      _log = 'You used 50/50! Two wrong moves are gone.';
    });
    _focus.requestFocus();
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
        bestCombo: s.bestCombo,
        review: [
          for (final q in s.missed)
            ReviewItem(prompt: q.prompt, code: q.code, correctAnswer: q.correctText, explanation: q.explanation),
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
    final progress = AppScope.watch(context);
    final last = _last;
    final question = last?.question ?? _session.current;
    final scene = sceneFor(widget.level.lang);

    return QuitGuard(
      active: !_session.isOver,
      child: Stack(
        children: [
          Positioned.fill(child: SceneBackground(kind: scene)),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GameTopBar(
              title: widget.level.title,
              actions: [
                HudPill(
                  leading: const CoinIcon(),
                  text: '${progress.coins}',
                  semanticLabel: '${progress.coins} coins',
                ),
              ],
            ),
            body: Focus(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: _onKey,
              child: PageBody(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  children: [
                    Shake(trigger: _shakeTick, child: _buildArena(context, scene)),
                    const SizedBox(height: 12),
                    // Battle text box - read out by screen readers.
                    ParchmentPanel(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Typewriter(_log, style: displayStyle(19, color: g.ink, height: 1.3)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (question != null) ...[
                      ParchmentPanel(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(question.source.prompt,
                                  style: displayStyle(22, color: g.ink, height: 1.25)),
                            ),
                            if (question.source.code != null) ...[
                              const SizedBox(height: 10),
                              CodeBlock(question.source.code!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (last == null) ...[
                        _MoveGrid(
                          options: question.options,
                          hidden: [for (var i = 0; i < question.options.length; i++) _session.isHidden(i)],
                          tones: _moveTones,
                          onSelected: _answer,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GameButton(
                              tone: ButtonTone.lilac,
                              size: GameButtonSize.small,
                              semanticLabel: _session.canUseFiftyFifty
                                  ? 'Use 50/50 for $fiftyFiftyCost coins: removes two wrong moves'
                                  : '50/50 already used on this question',
                              onPressed: _session.canUseFiftyFifty ? _useFiftyFifty : null,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('50/50', style: displayStyle(18, color: g.ink)),
                                  const SizedBox(width: 8),
                                  const CoinIcon(size: 20),
                                  const SizedBox(width: 3),
                                  Text('$fiftyFiftyCost', style: displayStyle(18, color: g.ink)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Tip: press 1-4 on your keyboard to attack.',
                                  style: TextStyle(color: g.onNight, fontSize: 14)),
                            ),
                          ],
                        ),
                      ] else
                        FeedbackPanel(
                          key: _feedbackKey,
                          correct: last.correct,
                          headline: last.correct ? 'Hit!' : 'Missed!',
                          reward: last.correct ? (_session.combo >= 2 ? 'Combo x${_session.combo}' : '+10 XP') : null,
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
          Positioned.fill(child: ConfettiBurst(trigger: _victoryTick)),
        ],
      ),
    );
  }

  Widget _buildArena(BuildContext context, SceneKind scene) {
    final g = GameColors.of(context);
    final palette = paletteFor(scene, highContrast: g.highContrast);
    final hp = (_session.total - _session.solved) / _session.total;
    final big = widget.level.isBoss;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const h = 300.0;
        final enemyCenter = Offset(w * 0.74, 112);
        final playerCenter = Offset(w * 0.24, h - 78);
        final plateW = min(w * 0.52, 300.0);

        return Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
            boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(child: SceneBackground(kind: scene, animate: false)),
              // Platforms
              _platform(Offset(enemyCenter.dx, enemyCenter.dy + 52), 190, palette, g),
              _platform(Offset(playerCenter.dx, playerCenter.dy + 46), 170, palette, g),
              // Enemy
              Positioned(
                left: enemyCenter.dx - 60,
                top: enemyCenter.dy - 62,
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_enemyHit, _lunge]),
                  builder: (context, child) {
                    final hit = _enemyHit.value;
                    final shake = (hit == 0 || hit == 1) ? 0.0 : sin(hit * pi * 8) * 10 * (1 - hit);
                    final lunge = sin(_lunge.value * pi);
                    final defeated = _session.won;
                    return Transform.translate(
                      offset: Offset(shake - lunge * (enemyCenter.dx - playerCenter.dx) * 0.45,
                          lunge * (playerCenter.dy - enemyCenter.dy) * 0.45),
                      child: Opacity(
                        opacity: defeated && !_enemyHit.isAnimating ? 0.25 : (hit > 0 && hit < 1 && (hit * 10).floor().isEven ? 0.35 : 1),
                        child: child,
                      ),
                    );
                  },
                  child: Bob(child: Center(child: Emoji(_enemy.emoji, size: big ? 96 : 80))),
                ),
              ),
              // Player
              Positioned(
                left: playerCenter.dx - 50,
                top: playerCenter.dy - 52,
                width: 100,
                height: 100,
                child: const Bob(phase: 0.5, child: Center(child: Emoji('🧑‍💻', size: 66))),
              ),
              // Code bolt
              AnimatedBuilder(
                animation: _bolt,
                builder: (context, _) {
                  if (!_bolt.isAnimating) return const SizedBox.shrink();
                  final t = Curves.easeIn.transform(_bolt.value);
                  final pos = Offset.lerp(playerCenter, enemyCenter, t)!;
                  return Positioned(
                    left: pos.dx - 26,
                    top: pos.dy - 26 - sin(t * pi) * 40,
                    child: Transform.rotate(angle: t * pi * 2, child: const _CodeBolt()),
                  );
                },
              ),
              // Damage number
              Positioned(
                left: enemyCenter.dx - 70,
                width: 140,
                top: enemyCenter.dy - 10,
                child: Center(
                  child: FloatingPopup(
                    trigger: _damageTick,
                    text: '-${(100 / _session.total).round()} HP',
                    color: g.coral,
                  ),
                ),
              ),
              // Enemy name plate
              Positioned(
                left: 10,
                top: 10,
                width: plateW,
                child: _NamePlate(
                  name: _enemy.name,
                  tag: big ? 'Boss' : 'Lv ${widget.level.number}',
                  child: Semantics(
                    label: '${_enemy.name} health',
                    value: '${(hp * 100).round()} percent',
                    container: true,
                    child: ExcludeSemantics(child: _HpBar(value: hp)),
                  ),
                ),
              ),
              // Player name plate
              Positioned(
                right: 10,
                bottom: 12,
                width: plateW,
                child: _NamePlate(
                  name: 'You',
                  tag: _session.combo >= 2 ? 'Combo x${_session.combo}' : 'Coder',
                  child: HeartsBar(lives: _session.lives, max: _session.maxLives, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _platform(Offset center, double width, ScenePalette palette, GameColors g) => Positioned(
        left: center.dx - width / 2,
        top: center.dy - 18,
        width: width,
        height: 36,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: OvalBorder(side: BorderSide(color: g.ink, width: 3)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.platformTop, palette.platform],
              ),
            ),
          ),
        ),
      );
}

class _CodeBolt extends StatelessWidget {
  const _CodeBolt();

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: g.gold,
          border: Border.all(color: g.ink, width: 3),
          boxShadow: [BoxShadow(color: g.gold.withValues(alpha: 0.8), blurRadius: 18, spreadRadius: 4)],
        ),
        child: Text('</>', style: displayStyle(18, color: g.ink)),
      ),
    );
  }
}

class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.name, required this.tag, required this.child});

  final String name;
  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ParchmentPanel(
      lip: 4,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: displayStyle(19, color: g.ink)),
              ),
              Text(tag, style: displayStyle(15, color: g.parchmentDim)),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _HpBar extends StatelessWidget {
  const _HpBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final color = value > 0.5 ? g.mint : (value > 0.25 ? g.gold : g.coral);
    return Row(
      children: [
        Text('HP', style: displayStyle(14, color: g.ink)),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: g.ink,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: g.ink, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value.clamp(0.0, 1.0)),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v,
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveGrid extends StatelessWidget {
  const _MoveGrid({
    required this.options,
    required this.hidden,
    required this.tones,
    required this.onSelected,
  });

  final List<String> options;
  final List<bool> hidden;
  final List<ButtonTone> tones;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 440 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < options.length; i++)
              SizedBox(
                width: width,
                child: GameButton(
                  tone: tones[i % tones.length],
                  expand: true,
                  semanticLabel: hidden[i] ? 'Move ${i + 1}: removed by 50/50' : 'Move ${i + 1}: ${options[i]}',
                  onPressed: hidden[i] ? null : () => onSelected(i),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: g.parchment,
                          shape: BoxShape.circle,
                          border: Border.all(color: g.ink, width: 2.5),
                        ),
                        child: Text('${i + 1}', style: displayStyle(17, color: g.ink, height: 1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hidden[i] ? '—' : options[i],
                          style: TextStyle(
                            fontFamily: codeFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: g.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
