import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
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

/// Cost of the 50/50 power-up, in coins.
const int fiftyFiftyCost = 15;

/// Temple-Run style game: answers are gates rushing down a 3-lane track.
class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key, required this.level, this.random});

  final Level level;

  /// Injected in tests to make option order predictable.
  final Random? random;

  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen> with TickerProviderStateMixin {
  static const _cheers = ['Awesome!', 'Nailed it!', 'Great run!', 'Perfect!', 'Super coder!'];

  late final QuizSession _session = QuizSession(widget.level.questions, random: widget.random);
  late final AnimationController _approach;
  late final AnimationController _scroll;
  late final AnimationController _flash;
  final FocusNode _focus = FocusNode(debugLabel: 'runner-game');
  final GlobalKey _feedbackKey = GlobalKey();

  int _lane = 1;
  AnswerResult? _last;
  bool _started = false;
  int _shakeTick = 0;
  int _popupTick = 0;
  String _popupText = '';

  @override
  void initState() {
    super.initState();
    _approach = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _resolve();
      });
    _scroll = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _startRound();
    }
  }

  @override
  void dispose() {
    _approach.dispose();
    _scroll.dispose();
    _flash.dispose();
    _focus.dispose();
    super.dispose();
  }

  TimerMode get _timerMode => AppScope.read(context).settings.timerMode;
  bool get _reduceMotion => reduceMotionOf(context, listen: false);

  Duration? get _roundDuration => switch (_timerMode) {
        TimerMode.normal => const Duration(seconds: 12),
        TimerMode.relaxed => const Duration(seconds: 24),
        TimerMode.off => null,
      };

  void _startRound() {
    final q = _session.current;
    if (q == null) return;
    _lane = (q.options.length - 1) ~/ 2;
    _last = null;
    _approach
      ..stop()
      ..value = 0;
    final duration = _roundDuration;
    if (duration != null) {
      _approach
        ..duration = duration
        ..forward(from: 0);
    }
    if (_reduceMotion) {
      _scroll.stop();
    } else {
      _scroll.repeat();
    }
  }

  /// Moves to [lane], skipping lanes removed by the 50/50 power-up.
  void _setLane(int lane, {int direction = 0}) {
    final q = _session.current;
    if (_last != null || q == null) return;
    var target = lane.clamp(0, q.options.length - 1);
    while (_session.isHidden(target)) {
      final next = target + (direction == 0 ? 1 : direction);
      if (next < 0 || next >= q.options.length) return;
      target = next;
    }
    setState(() => _lane = target);
  }

  void _resolve() {
    if (_last != null || _session.isOver) return;
    _approach.stop();
    _scroll.stop();
    final result = _session.answer(_lane);
    setState(() {
      _last = result;
      if (result.correct) {
        _popupTick++;
        _popupText = _session.combo >= 2 ? 'Combo x${_session.combo}!' : '+10 XP';
        SoundFx.play(Sfx.coin);
      } else {
        _shakeTick++;
        if (!_reduceMotion) _flash.forward(from: 0);
        SoundFx.play(Sfx.wrong);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  void _useFiftyFifty() {
    if (!_session.canUseFiftyFifty || _last != null) return;
    final progress = AppScope.read(context);
    if (!progress.spendCoins(fiftyFiftyCost)) {
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
      if (_session.isHidden(_lane)) _setLane(_lane + 1, direction: _lane == 0 ? 1 : -1);
      if (_session.isHidden(_lane)) _setLane(0, direction: 1);
    });
    _focus.requestFocus();
  }

  void _next() {
    if (_session.isOver) {
      _finish();
      return;
    }
    setState(_startRound);
    _focus.requestFocus();
  }

  void _finish() {
    final s = _session;
    finishLevel(
      context,
      GameOutcome(
        level: widget.level,
        won: s.won,
        correct: s.solved,
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
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _setLane(_lane - 1, direction: -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _setLane(_lane + 1, direction: 1);
      return KeyEventResult.handled;
    }
    const digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3];
    const numpad = [LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3];
    var index = digits.indexOf(key);
    if (index < 0) index = numpad.indexOf(key);
    if (index >= 0) {
      if (!_session.isHidden(index)) _setLane(index);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      _resolve();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _askBuddy(PlayQuestion q) {
    openDoubtBuddy(
      context,
      lang: widget.level.lang,
      question: 'Why is the answer "${q.correctText}"? ${q.source.prompt}',
      extraContext: '${q.source.code ?? ''}\nExplanation: ${q.source.explanation}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final progress = AppScope.watch(context);
    final level = widget.level;
    final last = _last;
    final question = last?.question ?? _session.current;
    final timerOn = _timerMode != TimerMode.off;
    final answered = _session.history.length;

    return QuitGuard(
      active: !_session.isOver,
      child: Stack(
        children: [
          Positioned.fill(child: SceneBackground(kind: sceneFor(level.lang))),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GameTopBar(
              title: level.title,
              actions: [
                _HeartsPill(lives: _session.lives, max: _session.maxLives),
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
              child: question == null
                  ? const SizedBox.shrink()
                  : Shake(
                      trigger: _shakeTick,
                      child: PageBody(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final trackHeight = (constraints.maxHeight * 0.48).clamp(260.0, 420.0);
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    HudPill(
                                      leading: Icon(Icons.flag_rounded, color: level.lang.color, size: 24),
                                      text: 'Gate ${min(answered + (last == null ? 1 : 0), _session.total)} of ${_session.total}',
                                      semanticLabel: 'Gate ${min(answered + (last == null ? 1 : 0), _session.total)} of ${_session.total}',
                                    ),
                                    if (_session.combo >= 2)
                                      HudPill(
                                        leading: const Emoji('⚡', size: 20),
                                        text: 'Combo x${_session.combo}',
                                        semanticLabel: 'Combo: ${_session.combo} right in a row',
                                        highlight: g.gold,
                                      ),
                                  ],
                                ),
                                if (timerOn) ...[
                                  const SizedBox(height: 8),
                                  AnimatedBuilder(
                                    animation: _approach,
                                    builder: (context, _) => _TimeBar(
                                      value: last == null ? 1 - _approach.value : 0,
                                      color: level.lang.color,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _QuestionCard(question: question.source),
                                const SizedBox(height: 10),
                                SizedBox(height: trackHeight, child: _buildTrack(context, question, trackHeight)),
                                const SizedBox(height: 12),
                                if (last == null)
                                  _buildControls(context, question)
                                else
                                  FeedbackPanel(
                                    key: _feedbackKey,
                                    correct: last.correct,
                                    headline: last.correct
                                        ? _cheers[answered % _cheers.length]
                                        : (_session.lives <= 0 ? 'Out of hearts!' : 'Oops! Wrong gate.'),
                                    reward: last.correct ? '+10 XP' : null,
                                    correctAnswer: last.correct ? null : last.question.correctText,
                                    explanation: last.question.source.explanation,
                                    continueLabel: _session.isOver ? 'See results' : 'Next gate',
                                    onContinue: _next,
                                    onAskBuddy: last.correct ? null : () => _askBuddy(last.question),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayQuestion q) {
    final g = GameColors.of(context);
    final timerOff = _timerMode == TimerMode.off;
    final canFifty = _session.canUseFiftyFifty;
    return Column(
      children: [
        Row(
          children: [
            GameButton(
              tone: ButtonTone.parchment,
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Move left',
              onPressed: _lane > 0 ? () => _setLane(_lane - 1, direction: -1) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                expand: true,
                size: GameButtonSize.large,
                icon: Icons.directions_run_rounded,
                label: timerOff ? 'Go!' : 'Dash!',
                semanticLabel: 'Run through gate ${_lane + 1}: ${q.options[_lane]}',
                onPressed: _resolve,
              ),
            ),
            const SizedBox(width: 10),
            GameButton(
              tone: ButtonTone.parchment,
              icon: Icons.arrow_forward_rounded,
              semanticLabel: 'Move right',
              onPressed: _lane < q.options.length - 1 ? () => _setLane(_lane + 1, direction: 1) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            GameButton(
              tone: ButtonTone.lilac,
              size: GameButtonSize.small,
              semanticLabel: canFifty
                  ? 'Use 50/50 for $fiftyFiftyCost coins: removes a wrong gate'
                  : '50/50 already used on this gate',
              onPressed: canFifty ? _useFiftyFifty : null,
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
              child: Text(
                'Tap a gate, swipe, or use arrow keys / 1-3. Space to dash.',
                style: TextStyle(color: g.onNight, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrack(BuildContext context, PlayQuestion q, double height) {
    final g = GameColors.of(context);
    final level = widget.level;
    final reduceMotion = reduceMotionOf(context);
    final staticGates = reduceMotion || _timerMode == TimerMode.off;
    final last = _last;
    final scene = sceneFor(level.lang);
    final palette = paletteFor(scene, highContrast: g.highContrast);

    return LayoutBuilder(
      builder: (context, constraints) {
        final track = _Track(Size(constraints.maxWidth, height), q.options.length);
        const runnerS = 0.9;
        const runnerW = 72.0;
        const runnerH = 92.0;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -100) _setLane(_lane - 1, direction: -1);
            if (v > 100) _setLane(_lane + 1, direction: 1);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
              boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: Listenable.merge([_approach, _scroll, _flash]),
              builder: (context, _) {
                final p = last != null ? 1.0 : (staticGates ? 0.95 : _approach.value);
                // Gates start mid-distance (still readable) and speed up as they near.
                final gateS = 0.25 + 0.47 * pow(p, 1.2).toDouble();
                final scale = track.scale(gateS);
                final laneW = track.width(gateS) / track.lanes;
                final gateW = laneW * 0.92;
                final gateH = max(56.0, 96 * scale);
                return Stack(
                  children: [
                    Positioned.fill(child: SceneBackground(kind: scene, animate: false)),
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _RoadPainter(
                            track: track,
                            scroll: _scroll.value,
                            palette: palette,
                            scene: scene,
                            ink: g.ink,
                            highContrast: g.highContrast,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < q.options.length; i++)
                      Positioned(
                        left: track.laneCenter(i, gateS) - gateW / 2,
                        top: track.y(gateS) - gateH,
                        width: gateW,
                        height: gateH,
                        child: _Gate(
                          index: i,
                          text: q.options[i],
                          selected: i == _lane,
                          color: level.lang.color,
                          scale: scale,
                          state: _session.isHidden(i) && last == null
                              ? _GateState.removed
                              : last == null
                                  ? _GateState.open
                                  : i == q.correctIndex
                                      ? _GateState.correct
                                      : (i == last.chosenIndex ? _GateState.wrong : _GateState.faded),
                          onTap: () => _setLane(i),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      left: track.laneCenter(_lane, runnerS) - runnerW / 2,
                      top: track.y(runnerS) - runnerH + 8,
                      width: runnerW,
                      height: runnerH,
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _RunnerPainter(
                            phase: _scroll.value * 2 * pi * 2,
                            color: level.lang.color,
                            g: g,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: track.y(gateS) - gateH - 10,
                      child: Center(child: FloatingPopup(trigger: _popupTick, text: _popupText)),
                    ),
                    if (_flash.isAnimating)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(color: g.coral.withValues(alpha: 0.35 * (1 - _flash.value))),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeartsPill extends StatelessWidget {
  const _HeartsPill({required this.lives, required this.max});

  final int lives;
  final int max;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
      ),
      child: HeartsBar(lives: lives, max: max, size: 22),
    );
  }
}

class _TimeBar extends StatelessWidget {
  const _TimeBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final barColor = value < 0.25 ? g.coral : color;
    return Semantics(
      label: 'Time left',
      value: '${(value * 100).round()} percent',
      child: Container(
        height: 16,
        decoration: BoxDecoration(
          color: g.ink,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: barColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ParchmentPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(question.prompt, style: displayStyle(22, color: g.ink, height: 1.25)),
          ),
          if (question.code != null) ...[
            const SizedBox(height: 10),
            CodeBlock(question.code!),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- track maths

/// Simple perspective: the road narrows towards a horizon near the top.
class _Track {
  _Track(this.size, this.lanes);

  final Size size;
  final int lanes;

  double get horizon => size.height * 0.12;
  double get topWidth => size.width * 0.26;
  double get bottomWidth => size.width * 1.02;

  /// Screen y for depth [s] (0 = horizon, 1 = bottom edge).
  double y(double s) => horizon + (size.height - horizon) * s;
  double width(double s) => topWidth + (bottomWidth - topWidth) * s;
  double left(double s) => (size.width - width(s)) / 2;
  double laneCenter(int lane, double s) => left(s) + (lane + 0.5) * width(s) / lanes;
  double scale(double s) => width(s) / bottomWidth;
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({
    required this.track,
    required this.scroll,
    required this.palette,
    required this.scene,
    required this.ink,
    required this.highContrast,
  });

  final _Track track;
  final double scroll;
  final ScenePalette palette;
  final SceneKind scene;
  final Color ink;
  final bool highContrast;

  Offset _pt(double laneFraction, double s) =>
      Offset(track.left(s) + track.width(s) * laneFraction, track.y(s));

  @override
  void paint(Canvas canvas, Size size) {
    final h = track.horizon;
    // Ground on both sides of the road.
    final groundRect = Rect.fromLTRB(0, h, size.width, size.height);
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.groundDark, palette.ground],
        ).createShader(groundRect),
    );

    // Road
    final road = Path()
      ..moveTo(_pt(0, 0).dx, h)
      ..lineTo(_pt(1, 0).dx, h)
      ..lineTo(_pt(1, 1).dx, size.height)
      ..lineTo(_pt(0, 1).dx, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = palette.road);

    // Road edges with ink outline
    for (final f in const [0.0, 1.0]) {
      canvas
        ..drawLine(_pt(f, 0), _pt(f, 1), Paint()
          ..color = ink
          ..strokeWidth = 12)
        ..drawLine(_pt(f, 0), _pt(f, 1), Paint()
          ..color = palette.roadEdge
          ..strokeWidth = 6);
    }

    // Moving lane dashes (spaced by perspective so they speed up near you)
    final dash = Paint()
      ..color = palette.stripe.withValues(alpha: highContrast ? 1 : 0.85)
      ..strokeCap = StrokeCap.round;
    for (var lane = 1; lane < track.lanes; lane++) {
      final f = lane / track.lanes;
      for (var k = 0; k < 10; k++) {
        final d = (k + scroll) / 10;
        final s1 = d * d;
        final s2 = min(1.0, (d + 0.045) * (d + 0.045));
        dash.strokeWidth = 2 + 5 * d;
        canvas.drawLine(_pt(f, s1), _pt(f, s2), dash);
      }
    }

    // Roadside props, far to near
    if (highContrast) return;
    final props = <double>[for (var k = 0; k < 6; k++) ((k / 6) + scroll / 3) % 1];
    props.sort();
    for (final d in props) {
      final s = d * d;
      final sc = 0.25 + track.scale(s) * 0.95;
      final y = track.y(s);
      _prop(canvas, Offset(track.left(s) - 26 * sc, y), sc);
      _prop(canvas, Offset(track.left(s) + track.width(s) + 26 * sc, y), sc);
    }
  }

  void _prop(Canvas canvas, Offset base, double sc) {
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * sc + 0.5;
    switch (scene) {
      case SceneKind.python:
        final trunk = Rect.fromCenter(center: base.translate(0, -18 * sc), width: 9 * sc, height: 36 * sc);
        canvas
          ..drawRect(trunk, Paint()..color = palette.propAccent)
          ..drawCircle(base.translate(0, -48 * sc), 22 * sc, Paint()..color = palette.prop)
          ..drawCircle(base.translate(0, -48 * sc), 22 * sc, outline)
          ..drawCircle(base.translate(-7 * sc, -55 * sc), 7 * sc, Paint()..color = const Color(0xFF3CC08F));
      case SceneKind.c:
        final crystal = Path()
          ..moveTo(base.dx, base.dy - 46 * sc)
          ..lineTo(base.dx + 10 * sc, base.dy - 36 * sc)
          ..lineTo(base.dx + 10 * sc, base.dy)
          ..lineTo(base.dx - 10 * sc, base.dy)
          ..lineTo(base.dx - 10 * sc, base.dy - 36 * sc)
          ..close();
        canvas
          ..drawCircle(base.translate(0, -24 * sc), 26 * sc, Paint()..color = palette.prop.withValues(alpha: 0.18))
          ..drawPath(crystal, Paint()..color = palette.prop)
          ..drawPath(crystal, outline);
      case SceneKind.cpp:
        canvas
          ..drawRect(Rect.fromLTWH(base.dx - 3 * sc, base.dy - 44 * sc, 6 * sc, 44 * sc), Paint()..color = palette.prop)
          ..drawCircle(base.translate(0, -50 * sc), 14 * sc, Paint()..color = palette.propAccent.withValues(alpha: 0.3))
          ..drawCircle(base.translate(0, -50 * sc), 7 * sc, Paint()..color = palette.propAccent);
      case SceneKind.java:
        final rock = Path()
          ..moveTo(base.dx - 18 * sc, base.dy)
          ..lineTo(base.dx - 12 * sc, base.dy - 20 * sc)
          ..lineTo(base.dx + 2 * sc, base.dy - 28 * sc)
          ..lineTo(base.dx + 16 * sc, base.dy - 14 * sc)
          ..lineTo(base.dx + 18 * sc, base.dy)
          ..close();
        canvas
          ..drawPath(rock, Paint()..color = palette.prop)
          ..drawPath(rock, outline)
          ..drawLine(base.translate(-6 * sc, -6 * sc), base.translate(4 * sc, -18 * sc), Paint()
            ..color = palette.propAccent
            ..strokeWidth = 2.5 * sc);
      default:
        canvas.drawCircle(base.translate(0, -10 * sc), 10 * sc, Paint()..color = palette.propAccent);
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) =>
      old.scroll != scroll || old.palette != palette || old.track.size != track.size || old.highContrast != highContrast;
}

/// The player's runner, seen from behind: running legs, swinging arms and a
/// backpack full of code.
class _RunnerPainter extends CustomPainter {
  _RunnerPainter({required this.phase, required this.color, required this.g});

  final double phase;
  final Color color;
  final GameColors g;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;
    final bob = sin(phase).abs() * 4;
    final ink = g.ink;
    final outline = Paint()
      ..color = g.highContrast ? Colors.white : ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 6), width: 46, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Legs
    final leftLift = max(0.0, sin(phase)) * 10;
    final rightLift = max(0.0, -sin(phase)) * 10;
    for (final (dx, lift) in [(-9.0, leftLift), (9.0, rightLift)]) {
      final leg = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + dx, h - 22 - lift), width: 11, height: 26),
        const Radius.circular(5),
      );
      canvas
        ..drawRRect(leg, Paint()..color = const Color(0xFF3B2A5E))
        ..drawRRect(leg, outline);
      final shoe = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + dx, h - 10 - lift), width: 14, height: 8),
        const Radius.circular(4),
      );
      canvas
        ..drawRRect(shoe, Paint()..color = g.parchment)
        ..drawRRect(shoe, outline);
    }

    final top = h - 72 - bob;

    // Arms
    final swing = sin(phase) * 12;
    final skin = Paint()
      ..color = const Color(0xFFFFCFA3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final armOutline = Paint()
      ..color = g.highContrast ? Colors.white : ink
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    for (final (side, s) in [(-1.0, swing), (1.0, -swing)]) {
      final from = Offset(cx + side * 18, top + 12);
      final to = Offset(cx + side * 26, top + 32 + s * 0.6);
      canvas
        ..drawLine(from, to, armOutline)
        ..drawLine(from, to, skin);
    }

    // Body (shirt in the world colour)
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 20, top + 4, 40, 40), const Radius.circular(13));
    canvas
      ..drawRRect(body, Paint()..color = color)
      ..drawRRect(body, outline);

    // Backpack
    final pack = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 13, top + 10, 26, 26), const Radius.circular(7));
    canvas
      ..drawRRect(pack, Paint()..color = g.gold)
      ..drawRRect(pack, outline);
    final tp = TextPainter(
      text: TextSpan(text: '</>', style: TextStyle(fontFamily: displayFont, fontSize: 11, color: ink)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, top + 16));

    // Head (back of the head: hair) with a headband
    final head = Offset(cx, top - 8);
    canvas
      ..drawCircle(head, 15, Paint()..color = const Color(0xFF4A2C1A))
      ..drawCircle(head, 15, outline)
      ..drawLine(head.translate(-14, 2), head.translate(14, 2), Paint()
        ..color = g.coral
        ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(_RunnerPainter old) => old.phase != phase || old.color != color || old.g != g;
}

enum _GateState { open, correct, wrong, faded, removed }

class _Gate extends StatelessWidget {
  const _Gate({
    required this.index,
    required this.text,
    required this.selected,
    required this.color,
    required this.state,
    required this.onTap,
    required this.scale,
  });

  final int index;
  final String text;
  final bool selected;
  final Color color;
  final _GateState state;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final (face, icon) = switch (state) {
      _GateState.correct => (g.mint, Icons.check_circle_rounded),
      _GateState.wrong => (g.coral, Icons.cancel_rounded),
      _GateState.faded => (g.disabled, null),
      _GateState.removed => (g.disabled, Icons.block_rounded),
      _GateState.open => (selected ? g.gold : g.parchment, null),
    };
    final stateText = switch (state) {
      _GateState.correct => ', correct answer',
      _GateState.wrong => ', your answer, wrong',
      _GateState.removed => ', removed by 50/50',
      _ => selected ? ', selected' : '',
    };
    final tappable = state == _GateState.open;
    final badge = max(18.0, 26 * scale);

    return Semantics(
      button: tappable,
      selected: selected,
      label: 'Gate ${index + 1}: $text$stateText',
      excludeSemantics: true,
      onTap: tappable ? onTap : null,
      child: GestureDetector(
        onTap: tappable ? onTap : null,
        child: Opacity(
          opacity: state == _GateState.faded || state == _GateState.removed ? 0.6 : 1,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale + 2, vertical: 4),
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(14 * scale + 4),
                    border: Border.all(color: g.ink, width: selected && tappable ? 4 : 3),
                    boxShadow: [
                      if (selected && tappable) BoxShadow(color: g.gold.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 2),
                      BoxShadow(color: g.ink, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: badge,
                        height: badge,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: g.ink, width: 2),
                        ),
                        child: Text('${index + 1}', style: displayStyle(badge * 0.6, color: g.ink, height: 1)),
                      ),
                      SizedBox(width: 4 * scale + 2),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              state == _GateState.removed ? '—' : text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: codeFont,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: g.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (icon != null) Icon(icon, color: g.ink, size: max(16.0, 24 * scale)),
                    ],
                  ),
                ),
              ),
              // Gate posts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 2; i++)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 14 * scale),
                      width: max(5.0, 9 * scale),
                      height: max(6.0, 14 * scale),
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: g.ink, width: 2),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
