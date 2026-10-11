import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
import '../logic/quiz_session.dart';
import '../logic/run_engine.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/run_world.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

enum _Phase { countdown, running, paused, wrong, caught, finishing }

class _Toast {
  _Toast(this.title, this.body, this.color, {this.seconds = 3.5}) : left = seconds;

  final String title;
  final String? body;
  final Color color;
  final double seconds;
  double left;
}

class _Frame extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// The Temple-Run style code runner (see [RunEngine] for the rules).
class TempleRun extends StatefulWidget {
  const TempleRun({super.key, required this.level, this.random, this.onEngineReady});

  final Level level;
  final Random? random;

  /// Lets tests drive the engine directly (an autopilot).
  @visibleForTesting
  final ValueChanged<RunEngine>? onEngineReady;

  @override
  State<TempleRun> createState() => _TempleRunState();
}

class _TempleRunState extends State<TempleRun> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _cheers = ['Nailed it!', 'Correct!', 'Perfect!', 'Great run!', 'Super coder!'];

  late final QuizSession _session = QuizSession(widget.level.questions, random: widget.random);
  late RunEngine _engine;
  late final Ticker _ticker = createTicker(_onTick);
  final _Frame _frame = _Frame();
  final RunFx _fx = RunFx();
  final FocusNode _focus = FocusNode(debugLabel: 'code-runner');

  bool _started = false;
  bool _done = false;
  _Phase _phase = _Phase.countdown;
  _Phase _pausedFrom = _Phase.running;
  double _countdown = 3;
  double _clock = 0;
  double _hudTimer = 0;
  double _finishWait = 0;
  Duration _lastTick = Duration.zero;
  AnswerResult? _wrong;
  _Toast? _toast;
  int _confetti = 0;
  Size _size = Size.zero;
  Offset? _swipeStart;
  bool _swiped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final relaxed = AppScope.read(context).settings.timerMode == TimerMode.relaxed;
    _engine = RunEngine(
      session: _session,
      config: relaxed ? RunConfig.relaxed : RunConfig.normal,
      random: widget.random,
    );
    widget.onEngineReady?.call(_engine);
    _ticker.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Switching apps or tabs pauses the run.
    if (state != AppLifecycleState.resumed) _pause();
  }

  // --------------------------------------------------------------- the loop

  void _onTick(Duration now) {
    if (!mounted) return;
    final dt = ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;
    _clock += dt;
    _fx.update(dt);
    switch (_phase) {
      case _Phase.countdown:
        final before = _countdown.ceil();
        _countdown -= dt;
        if (_countdown <= 0) {
          SoundFx.play(Sfx.star);
          setState(() => _phase = _Phase.running);
        } else if (_countdown.ceil() != before) {
          SoundFx.play(Sfx.tick);
          setState(() {});
        }
      case _Phase.running:
        final lane = _engine.lane;
        final events = _engine.update(dt);
        if (events.isNotEmpty) _handle(events);
        _hudTimer += dt;
        if (_hudTimer > 0.12 || lane != _engine.lane) {
          _hudTimer = 0;
          if (mounted) setState(() {});
        }
      case _Phase.finishing:
        _finishWait -= dt;
        if (_finishWait <= 0) {
          _ticker.stop();
          _finish();
          return;
        }
      case _Phase.paused || _Phase.wrong || _Phase.caught:
        break;
    }
    final toast = _toast;
    if (toast != null) {
      toast.left -= dt;
      if (toast.left <= 0 && mounted) setState(() => _toast = null);
    }
    _frame.tick();
  }

  Offset get _runnerSpot {
    if (_size.isEmpty) return const Offset(0.5, 0.75);
    final p = RunCamera(_size, 0).p(_engine.laneX - 1, _engine.height + 0.5, 0);
    return Offset(p.dx / _size.width, p.dy / _size.height);
  }

  void _say(String title, String? body, Color color, {double seconds = 3.5}) {
    _toast = _Toast(title, body, color, seconds: seconds);
  }

  void _handle(List<RunEvent> events) {
    final g = GameColors.of(context);
    for (final event in events) {
      switch (event) {
        case CoinPicked():
          SoundFx.play(Sfx.pickup);
          _fx.sparkle(_runnerSpot, count: 5);
        case PowerUpPicked(:final kind, :final removedLanes, :final bonusCoins):
          SoundFx.play(Sfx.powerUp);
          if (kind == RunItemKind.shield) {
            _fx.glow(g.sky);
            _say('Shield on!', 'It saves you from your next crash.', g.sky);
          } else {
            _fx.glow(g.gold);
            _say(
              'Hint orb!',
              removedLanes.isNotEmpty
                  ? 'A wrong gate for the next question is blocked off.'
                  : 'No gate left to block, so you get $bonusCoins coins.',
              g.gold,
            );
          }
        case ObstacleHit(:final shielded, :final lostHeart):
          if (shielded) {
            SoundFx.play(Sfx.powerUp);
            _fx.glow(g.sky);
            _say('Saved by your shield!', null, g.sky, seconds: 2);
          } else {
            SoundFx.play(lostHeart ? Sfx.wrong : Sfx.hit);
            _fx
              ..hit(g.coral)
              ..dust(_runnerSpot);
            _say(
              lostHeart ? 'Ouch! You lost a heart.' : 'Stumble! The Bug Monster is right behind you!',
              lostHeart ? null : 'Watch the arrows: ⬆ means jump, ⬇ means slide.',
              g.coral,
              seconds: 2.6,
            );
          }
        case GatePassed(:final result, :final bonusCoins):
          if (result.correct) {
            SoundFx.play(Sfx.coin);
            _fx
              ..glow(g.mint)
              ..sparkle(_runnerSpot, count: 16);
            final combo = _session.combo >= 2 ? '  Combo x${_session.combo}!' : '';
            _say(
              '${_cheers[_session.history.length % _cheers.length]} +$bonusCoins coins$combo',
              result.question.source.explanation,
              g.mint,
              seconds: 4.5,
            );
          } else {
            SoundFx.play(Sfx.wrong);
            _fx.hit(g.coral);
            _toast = null;
            _wrong = result;
            _phase = _Phase.wrong;
            _ticker.stop();
          }
        case RunCaught():
          if (_phase != _Phase.wrong) {
            _toast = null;
            _phase = _Phase.caught;
            _ticker.stop();
          }
        case RunFinished():
          SoundFx.play(Sfx.levelUp);
          _confetti++;
          _phase = _Phase.finishing;
          _finishWait = reduceMotionOf(context, listen: false) ? 0.2 : 1.8;
      }
    }
    if (mounted) setState(() {});
  }

  // ----------------------------------------------------------------- input

  bool get _canSteer => _phase == _Phase.running;

  void _steer(bool Function() action) {
    if (!_canSteer) return;
    if (action()) setState(() {});
  }

  void _left() => _steer(() => _engine.move(-1));
  void _right() => _steer(() => _engine.move(1));
  void _toLane(int lane) => _steer(() => _engine.goToLane(lane));

  void _jump() {
    if (_canSteer && _engine.jump()) SoundFx.play(Sfx.jump);
  }

  void _slide() {
    if (_canSteer && _engine.slide()) SoundFx.play(Sfx.slide);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      if (_phase == _Phase.paused) {
        _resume();
      } else {
        _pause();
      }
      return KeyEventResult.handled;
    }
    if (!_canSteer) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _left();
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _right();
    } else if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.space) {
      _jump();
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _slide();
    } else {
      const digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3];
      const numpad = [LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3];
      var index = digits.indexOf(key);
      if (index < 0) index = numpad.indexOf(key);
      if (index < 0) return KeyEventResult.ignored;
      _toLane(index);
    }
    return KeyEventResult.handled;
  }

  void _onPanStart(DragStartDetails d) {
    _swipeStart = d.localPosition;
    _swiped = false;
  }

  /// Acts as soon as the finger has moved far enough, like Temple Run.
  void _onPanUpdate(DragUpdateDetails d) {
    final start = _swipeStart;
    if (start == null || _swiped) return;
    final delta = d.localPosition - start;
    if (delta.distance < 26) return;
    _swiped = true;
    if (delta.dx.abs() > delta.dy.abs()) {
      if (delta.dx < 0) {
        _left();
      } else {
        _right();
      }
    } else if (delta.dy < 0) {
      _jump();
    } else {
      _slide();
    }
  }

  void _useFiftyFifty() {
    if (!_canSteer || !_session.canUseFiftyFifty) return;
    final g = GameColors.of(context);
    if (!AppScope.read(context).spendCoins(fiftyFiftyCost)) {
      setState(() => _say('Not enough coins', 'You need $fiftyFiftyCost coins for 50/50. Grab coins on the track!', g.coral));
      return;
    }
    SoundFx.play(Sfx.powerUp);
    _session.useFiftyFifty();
    setState(() => _say('50/50!', 'A wrong gate is blocked off.', g.lilac, seconds: 2.5));
  }

  // ------------------------------------------------------- pause & results

  void _pause() {
    if (_phase != _Phase.running && _phase != _Phase.countdown) return;
    _pausedFrom = _phase;
    _ticker.stop();
    if (mounted) setState(() => _phase = _Phase.paused);
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    setState(() => _phase = _pausedFrom);
    _restartTicker();
  }

  void _keepRunning() {
    if (_session.lives <= 0 || _engine.over) {
      _finish();
      return;
    }
    setState(() {
      _wrong = null;
      _phase = _Phase.running;
    });
    _restartTicker();
  }

  void _restartTicker() {
    _lastTick = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
    _focus.requestFocus();
  }

  void _onBack() {
    if (_phase == _Phase.paused) {
      Navigator.of(context).pop();
    } else {
      _pause();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
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
        bonusCoins: _engine.coins,
        review: [
          for (final q in s.missed)
            ReviewItem(prompt: q.prompt, code: q.code, correctAnswer: q.correctText, explanation: q.explanation),
        ],
      ),
    );
  }

  void _askBuddy(PlayQuestion q) {
    openDoubtBuddy(
      context,
      lang: widget.level.lang,
      question: 'Why is the answer "${q.correctText}"? ${q.source.prompt}',
      extraContext: '${q.source.code ?? ''}\nExplanation: ${q.source.explanation}',
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final level = widget.level;
    final theme = runThemeFor(sceneFor(level.lang), g);
    final q = _session.current;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: theme.sky.first,
          body: LayoutBuilder(
            builder: (context, constraints) {
              _size = constraints.biggest;
              final compact = constraints.maxWidth < 600;
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: RunWorldPainter(
                            engine: _engine,
                            theme: theme,
                            accent: level.lang.color,
                            runnerShirt: level.lang.color,
                            fx: _fx,
                            time: () => _clock,
                            repaint: _frame,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(compact ? 10 : 16, 8, compact ? 10 : 16, 10),
                      child: Column(
                        children: [
                          _topBar(g),
                          const SizedBox(height: 8),
                          _statusRow(g),
                          const SizedBox(height: 8),
                          if (q != null && _phase != _Phase.finishing)
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 780),
                                child: _questionCard(g, q, compact),
                              ),
                            ),
                          const Spacer(),
                          if (_toast != null) _toastView(g, _toast!),
                          const SizedBox(height: 8),
                          _controls(g),
                        ],
                      ),
                    ),
                  ),
                  if (_phase == _Phase.countdown) _countdownOverlay(g),
                  if (_phase == _Phase.paused) _pauseOverlay(g),
                  if (_phase == _Phase.wrong && _wrong != null) _wrongOverlay(g, _wrong!),
                  if (_phase == _Phase.caught) _caughtOverlay(g),
                  if (_phase == _Phase.finishing) _finishBanner(),
                  Positioned.fill(child: IgnorePointer(child: ConfettiBurst(trigger: _confetti))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(GameColors g) {
    return Row(
      children: [
        RoundIconButton(icon: Icons.pause_rounded, tooltip: 'Pause', onPressed: _phase == _Phase.paused ? null : _pause),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OutlinedText(widget.level.title, size: 24, header: true, maxLines: 1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
          ),
          child: HeartsBar(lives: _session.lives, max: _session.maxLives, size: 22),
        ),
        const SizedBox(width: 8),
        HudPill(
          leading: const CoinIcon(),
          text: '${_engine.coins}',
          semanticLabel: '${_engine.coins} coins collected in this run',
        ),
      ],
    );
  }

  Widget _statusRow(GameColors g) {
    return Row(
      children: [
        Expanded(child: _RunProgress(engine: _engine, color: widget.level.lang.color)),
        if (_session.combo >= 2) ...[
          const SizedBox(width: 8),
          HudPill(
            leading: const Emoji('⚡', size: 18),
            text: 'x${_session.combo}',
            semanticLabel: 'Combo: ${_session.combo} right in a row',
            highlight: g.gold,
          ),
        ],
        if (_engine.shield) ...[
          const SizedBox(width: 8),
          HudPill(
            leading: Icon(Icons.shield_rounded, color: g.sky, size: 20),
            text: 'On',
            semanticLabel: 'Shield on: your next crash is free',
            highlight: g.sky,
          ),
        ],
      ],
    );
  }

  Widget _questionCard(GameColors g, PlayQuestion q, bool compact) {
    final number = _session.history.length + 1;
    final toGate = _engine.distanceToGate;
    final chooseNow = toGate != null && toGate < RunEngine.gateLockDistance;
    final distanceText = toGate == null ? '' : (chooseNow ? 'Choose now!' : 'in ${(toGate / 5).round() * 5} m');
    final canFifty = _session.canUseFiftyFifty && _canSteer;
    return ParchmentPanel(
      padding: EdgeInsets.fromLTRB(12, 10, 12, compact ? 10 : 12),
      lip: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: widget.level.lang.color, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Code gate $number of ${_session.total}',
                  style: displayStyle(compact ? 15 : 17, color: g.parchmentDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (distanceText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: chooseNow ? g.gold : g.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(distanceText, style: displayStyle(14, color: chooseNow ? g.ink : g.onNight)),
                ),
              const Spacer(),
              GameButton(
                tone: ButtonTone.lilac,
                size: GameButtonSize.small,
                semanticLabel: _session.canUseFiftyFifty
                    ? 'Use 50/50 for $fiftyFiftyCost coins: blocks a wrong gate'
                    : '50/50 already used on this gate',
                onPressed: canFifty ? _useFiftyFifty : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('50/50', style: displayStyle(16, color: g.ink)),
                    const SizedBox(width: 6),
                    const CoinIcon(size: 18),
                    const SizedBox(width: 2),
                    Text('$fiftyFiftyCost', style: displayStyle(16, color: g.ink)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(q.source.prompt, style: displayStyle(compact ? 18 : 21, color: g.ink, height: 1.2)),
          ),
          if (q.source.code != null) ...[
            const SizedBox(height: 6),
            CodeBlock(q.source.code!, fontSize: compact ? 13 : 14),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < q.options.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _LaneChip(
                    index: i,
                    text: q.options[i],
                    selected: _engine.lane == i,
                    blocked: _session.isHidden(i),
                    color: widget.level.lang.color,
                    onTap: () => _toLane(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _toastView(GameColors g, _Toast toast) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ParchmentPanel(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          borderColor: toast.color,
          lip: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(toast.title, style: displayStyle(19, color: g.ink)),
              if (toast.body != null) ...[
                const SizedBox(height: 2),
                Text(toast.body!, style: TextStyle(color: g.parchmentDim, fontSize: 15, height: 1.3)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(GameColors g) {
    final enabled = _canSteer;
    Widget pad(IconData icon, String label, VoidCallback action) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GameButton(
            icon: icon,
            semanticLabel: label,
            tooltip: label,
            circle: true,
            tone: ButtonTone.parchment,
            onPressed: enabled ? action : null,
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pad(Icons.arrow_back_rounded, 'Move left', _left),
          pad(Icons.keyboard_double_arrow_up_rounded, 'Jump', _jump),
          pad(Icons.keyboard_double_arrow_down_rounded, 'Slide', _slide),
          pad(Icons.arrow_forward_rounded, 'Move right', _right),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- overlays

  Widget _dim({required Widget child}) => Positioned.fill(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: child),
              ),
            ),
          ),
        ),
      );

  Widget _countdownOverlay(GameColors g) {
    final n = _countdown.ceil();
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedText(n > 0 ? '$n' : 'GO!', size: 110, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ParchmentPanel(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Get ready to run!', style: displayStyle(22, color: g.ink)),
                          const SizedBox(height: 6),
                          Text(
                            'Swipe, or use the arrow keys: ← → switch lanes, ↑ jump, ↓ slide. '
                            'Run through the gate with the right answer! P pauses.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: g.parchmentDim, fontSize: 15, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseOverlay(GameColors g) {
    return _dim(
      child: ParchmentPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(header: true, child: Text('Paused', style: displayStyle(34, color: g.ink))),
            const SizedBox(height: 14),
            GameButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              expand: true,
              autofocus: true,
              onPressed: _resume,
            ),
            const SizedBox(height: 10),
            GameButton(
              label: 'Restart',
              icon: Icons.replay_rounded,
              tone: ButtonTone.sky,
              expand: true,
              onPressed: () => startGame(context, widget.level),
            ),
            const SizedBox(height: 10),
            GameButton(
              label: 'Quit level',
              icon: Icons.logout_rounded,
              tone: ButtonTone.parchment,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
            Text(
              'Too fast? In Settings, set Runner timer to Relaxed for a slower run, '
              'or No timer for a calm, step-by-step mode.',
              textAlign: TextAlign.center,
              style: TextStyle(color: g.parchmentDim, fontSize: 14, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrongOverlay(GameColors g, AnswerResult result) {
    final out = _session.lives <= 0;
    final q = result.question;
    return _dim(
      child: ParchmentPanel(
        borderColor: g.coral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                out ? 'Out of hearts!' : 'Wrong gate!',
                style: displayStyle(30, color: g.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(q.source.prompt, style: displayStyle(19, color: g.ink, height: 1.25)),
            if (q.source.code != null) ...[
              const SizedBox(height: 8),
              CodeBlock(q.source.code!, fontSize: 14),
            ],
            const SizedBox(height: 10),
            _answerLine(g, 'You ran through', result.chosenText, g.coral, Icons.cancel_rounded),
            const SizedBox(height: 6),
            _answerLine(g, 'Right answer', q.correctText, g.mint, Icons.check_circle_rounded),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Emoji('💡', size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(q.source.explanation, style: TextStyle(color: g.parchmentText, fontSize: 16, height: 1.4)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                GameButton(
                  label: out ? 'See results' : 'Keep running',
                  icon: out ? Icons.emoji_events_rounded : Icons.directions_run_rounded,
                  autofocus: true,
                  onPressed: _keepRunning,
                ),
                GameButton(
                  label: 'Ask Doubt Buddy',
                  icon: Icons.support_agent_rounded,
                  tone: ButtonTone.sky,
                  onPressed: () => _askBuddy(q),
                ),
              ],
            ),
            if (!out) ...[
              const SizedBox(height: 10),
              Text(
                'The Bug Monster is right behind you now - careful!',
                style: TextStyle(color: g.parchmentDim, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerLine(GameColors g, String label, String answer, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: g.ink, size: 22),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: g.parchmentText, fontSize: 16)),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: g.ink, width: 2),
            ),
            child: Text(answer, style: TextStyle(fontFamily: codeFont, fontWeight: FontWeight.w700, color: g.ink)),
          ),
        ),
      ],
    );
  }

  Widget _caughtOverlay(GameColors g) {
    return _dim(
      child: ParchmentPanel(
        borderColor: g.coral,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Emoji('👾', size: 56),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                'The Bug Monster caught you!',
                textAlign: TextAlign.center,
                style: displayStyle(28, color: g.ink),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You ran out of hearts. Tip: crashing once lets the monster catch up - '
              'crash again while it is close and you lose a heart. Watch the arrows: ⬆ jump, ⬇ slide.',
              textAlign: TextAlign.center,
              style: TextStyle(color: g.parchmentDim, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 14),
            GameButton(
              label: 'Try again',
              icon: Icons.replay_rounded,
              expand: true,
              autofocus: true,
              onPressed: () => startGame(context, widget.level),
            ),
            const SizedBox(height: 10),
            GameButton(
              label: 'See results',
              icon: Icons.emoji_events_rounded,
              tone: ButtonTone.sky,
              expand: true,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _finishBanner() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: const OutlinedText('You made it!', size: 64, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

/// An answer, lined up with its lane. Tap it to run into that lane.
class _LaneChip extends StatelessWidget {
  const _LaneChip({
    required this.index,
    required this.text,
    required this.selected,
    required this.blocked,
    required this.color,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool blocked;
  final Color color;
  final VoidCallback onTap;

  static const _side = ['left', 'middle', 'right'];

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final face = blocked
        ? g.disabled
        : selected
            ? g.gold
            : g.parchment;
    return Semantics(
      button: !blocked,
      selected: selected,
      label: 'Lane ${index + 1}: $text'
          '${blocked ? ', blocked by a hint' : ''}'
          '${selected && !blocked ? ', you are in this lane' : ''}',
      hint: blocked ? null : 'Run in the ${_side[index.clamp(0, 2)]} lane',
      excludeSemantics: true,
      onTap: blocked ? null : onTap,
      child: GestureDetector(
        onTap: blocked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: g.ink, width: selected ? 3.5 : 2.5),
            boxShadow: [BoxShadow(color: g.ink, offset: Offset(0, selected ? 2 : 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: blocked ? g.parchmentShade : color,
                  shape: BoxShape.circle,
                  border: Border.all(color: g.ink, width: 2),
                ),
                child: Text('${index + 1}', style: displayStyle(14, color: g.ink, height: 1)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    blocked ? '×' : text,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: codeFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: g.ink,
                      decoration: blocked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Distance bar with a flag for every code gate and the finish line.
class _RunProgress extends StatelessWidget {
  const _RunProgress({required this.engine, required this.color});

  final RunEngine engine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final passed = engine.session.history.length;
    final total = engine.gatePositions.length;
    final metresLeft = max(0, (engine.finishPos - engine.distance).round());
    return Semantics(
      label: 'Run progress',
      value: '$passed of $total gates passed, $metresLeft metres to the finish',
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 28,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
                    ),
                  ),
                  Container(
                    height: 14,
                    width: max(14, w * engine.progress),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
                    ),
                  ),
                  for (var i = 0; i < total; i++)
                    Positioned(
                      left: (w * engine.gatePositions[i] / engine.finishPos) - 9,
                      child: Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: i < passed ? g.gold : (g.highContrast ? Colors.white : g.parchment),
                      ),
                    ),
                  const Positioned(right: -4, child: Emoji('🏁', size: 18)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
