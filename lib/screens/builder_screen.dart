import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/builder_levels.dart';
import '../logic/builder.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../services/sound.dart';
import '../theme/app_theme.dart';
import '../widgets/builder_stage.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

enum _Phase { editing, running, acting, done }

/// World Builder: fill the blank in a tiny program, run it, and watch the
/// code change the world - loops build bridges, variables set jumps.
class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key, required this.level, this.challenges});

  final Level level;

  /// Injected by tests; normally loaded for [level].
  final List<BuildChallenge>? challenges;

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> with TickerProviderStateMixin {
  late final BuilderSession _session =
      BuilderSession(widget.challenges ?? builderChallenges(widget.level.id));
  late final AnimationController _act =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..addListener(_onActTick);
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 10));
  final GlobalKey _resultKey = GlobalKey();
  final FocusNode _focus = FocusNode(debugLabel: 'builder');

  _Phase _phase = _Phase.editing;
  int _shown = 0;
  late int _hearts = _session.lives;
  bool _hintOpen = false;
  bool _started = false;
  int _winTick = 0;
  int _shakeTick = 0;
  final Set<String> _soundMarks = {};
  Timer? _timer;

  bool get _reduceMotion => reduceMotionOf(context, listen: false);
  BuildChallenge get _challenge => _session.current;
  BuildRun? get _run => _session.lastRun;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = reduceMotionOf(context);
    if (reduce) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
    if (!_started) {
      _started = true;
      if (reduce) {
        _enter.value = 1;
      } else {
        _enter.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _act.dispose();
    _enter.dispose();
    _clock.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  void _select(int index) {
    if (_phase != _Phase.editing) return;
    setState(() => _session.select(index));
  }

  void _runCode() {
    if (_phase != _Phase.editing || _session.isOver) return;
    _session.run();
    _soundMarks.clear();
    setState(() {
      _phase = _Phase.running;
      _shown = 0;
      _hintOpen = false;
    });
    if (_reduceMotion) {
      _finishInstantly();
    } else {
      _step();
    }
  }

  /// Shows the next line of the program running, then waits a moment.
  void _step() {
    final run = _run;
    if (!mounted || run == null) return;
    if (_shown >= run.steps.length) {
      _startAct();
      return;
    }
    final step = run.steps[_shown];
    setState(() => _shown++);
    switch (step.effect) {
      case StepEffect.block || StepEffect.step:
        SoundFx.play(Sfx.block);
      case StepEffect.coins:
        SoundFx.play(Sfx.coin);
      case StepEffect.say || StepEffect.pay:
        SoundFx.play(Sfx.tap);
      case StepEffect.error:
        SoundFx.play(Sfx.wrong);
      case StepEffect.none || StepEffect.jump || StepEffect.skip:
        break;
    }
    final fast = step.effect == StepEffect.block || step.effect == StepEffect.step;
    _timer = Timer(Duration(milliseconds: fast ? 280 : 480), _step);
  }

  void _startAct() {
    setState(() => _phase = _Phase.acting);
    final outcome = _run!.outcome;
    if (_challenge.obstacle == Obstacle.ledge && outcome != BuildOutcome.error) SoundFx.play(Sfx.jump);
    _act.forward(from: 0).then((_) => _onActDone());
  }

  /// Sound cues timed to Byte's movement.
  void _onActTick() {
    final run = _run;
    if (run == null) return;
    final v = _act.value;
    void mark(String key, double at, Sfx sfx) {
      if (v >= at && _soundMarks.add(key)) SoundFx.play(sfx);
    }

    switch (run.outcome) {
      case BuildOutcome.fall:
        mark('fall', 0.45, Sfx.fall);
      case BuildOutcome.trip || BuildOutcome.blocked:
        mark('bump', 0.5, Sfx.hit);
      case BuildOutcome.short:
        mark('bump', _challenge.obstacle == Obstacle.stairs ? 0.6 : 0.5, Sfx.hit);
      case BuildOutcome.bonkCeiling:
        mark('bump', 0.5, Sfx.hit);
      case BuildOutcome.cross || BuildOutcome.land || BuildOutcome.error:
        break;
    }
  }

  void _onActDone() {
    if (!mounted) return;
    _showResult();
  }

  void _finishInstantly() {
    _act.value = 1;
    setState(() => _shown = _run!.steps.length);
    _showResult();
  }

  void _showResult() {
    final run = _run!;
    setState(() {
      _phase = _Phase.done;
      _hearts = _session.lives;
      if (run.success) {
        _winTick++;
      } else {
        _shakeTick++;
      }
    });
    SoundFx.play(run.success ? Sfx.correct : Sfx.wrong);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  void _tryAgain() {
    _session.retry();
    _act.value = 0;
    setState(() {
      _phase = _Phase.editing;
      _shown = 0;
    });
    _focus.requestFocus();
  }

  void _next() {
    if (_session.finished) {
      _finish();
      return;
    }
    _session.next();
    _act.value = 0;
    setState(() {
      _phase = _Phase.editing;
      _shown = 0;
      _hintOpen = false;
    });
    if (_reduceMotion) {
      _enter.value = 1;
    } else {
      _enter.forward(from: 0);
    }
    _focus.requestFocus();
  }

  void _finish() {
    final s = _session;
    finishLevel(
      context,
      GameOutcome(
        level: widget.level,
        won: s.won,
        correct: s.solvedFirstTry,
        total: s.challenges.length,
        stars: puzzleStars(mistakes: s.mistakes, won: s.won),
        review: [
          for (final c in s.missed)
            ReviewItem(
              prompt: c.goal,
              code: c.codeWith(c.answer),
              correctAnswer: c.options[c.answer],
              explanation: c.lesson,
            ),
        ],
      ),
    );
  }

  void _askBuddy() {
    final run = _run;
    openDoubtBuddy(
      context,
      lang: widget.level.lang,
      question: 'Why did my code not work? ${_challenge.goal}',
      extraContext: '${_challenge.codeWith(_session.choice)}\n${run?.message ?? ''}',
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _phase != _Phase.editing) return KeyEventResult.ignored;
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    final i = digits.indexOf(event.logicalKey);
    if (i >= 0 && i < _challenge.options.length) {
      SoundFx.play(Sfx.tap);
      _select(i);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _runCode();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ------------------------------------------------------------ what's shown

  List<TraceStep> get _applied {
    final run = _run;
    if (run == null || _phase == _Phase.editing) return const [];
    return run.steps.take(_shown).toList();
  }

  StageScene _scene() {
    final applied = _applied;
    var built = 0;
    var coins = 0;
    String? speech;
    var speechIsError = false;
    for (final s in applied) {
      switch (s.effect) {
        case StepEffect.block || StepEffect.step:
          built = s.value;
        case StepEffect.coins || StepEffect.pay:
          coins = s.value;
        case StepEffect.say:
          speech = s.text;
        case StepEffect.error:
          speech = s.text;
          speechIsError = true;
        case StepEffect.none || StepEffect.jump || StepEffect.skip:
          break;
      }
    }
    final showOutcome = _phase == _Phase.acting || _phase == _Phase.done;
    return StageScene(
      lang: widget.level.lang,
      obstacle: _challenge.obstacle,
      size: _challenge.size,
      built: built,
      coins: coins,
      speech: speech,
      speechIsError: speechIsError,
      outcome: showOutcome ? _run?.outcome : null,
      act: showOutcome ? _act.value : 0,
      enter: _enter.value,
      clock: _clock.value * 10,
      jump: _run?.amount ?? 0,
    );
  }

  String _describe(StageScene s) {
    final c = _challenge;
    final base = switch (c.obstacle) {
      Obstacle.gap => 'Byte stands before a gap ${c.size} blocks wide.'
          '${s.built > 0 ? ' The code has built ${s.built} blocks.' : ''}',
      Obstacle.ledge => 'Byte stands before a ledge ${c.size} blocks high, with spikes above it.',
      Obstacle.stairs => 'Byte stands before a ledge ${c.size} blocks high.'
          '${s.built > 0 ? ' The code has built ${s.built} steps.' : ''}',
      Obstacle.guard => 'A guard blocks the gate and asks for the password.'
          '${s.speech != null && !s.speechIsError ? ' Byte says ${s.speech}.' : ''}',
      Obstacle.toll => 'A troll guards a gate. The toll is ${c.size} coins.'
          '${s.coins > 0 ? ' Byte has ${s.coins} coins.' : ''}',
    };
    final outcome = s.outcome;
    if (outcome == null || _phase != _Phase.done) return base;
    return '$base ${switch (outcome) {
      BuildOutcome.cross => 'Byte made it through!',
      BuildOutcome.land => 'Byte landed on the ledge!',
      BuildOutcome.fall => 'Byte fell in.',
      BuildOutcome.trip => 'Byte tripped over the extra blocks.',
      BuildOutcome.short => 'Byte could not reach the top.',
      BuildOutcome.bonkCeiling => 'Byte hit the spikes.',
      BuildOutcome.blocked => 'The gate stayed shut.',
      BuildOutcome.error => 'The code did not run.',
    }}';
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final lang = widget.level.lang;

    final goal = _GoalPanel(
      index: _session.index,
      total: _session.challenges.length,
      goal: _challenge.goal,
      hint: _hintOpen ? _challenge.hint : null,
    );
    Widget stageWith(double aspect) => Shake(
          trigger: _shakeTick,
          child: AnimatedBuilder(
            animation: Listenable.merge([_act, _enter, _clock]),
            builder: (context, _) {
              final scene = _scene();
              return BuilderStage(scene: scene, description: _describe(scene), aspect: aspect);
            },
          ),
        );
    final editor = _CodeEditor(
      challenge: _challenge,
      choice: _session.choice,
      fileName: lang.fileName,
      activeLine: _phase == _Phase.running && _shown > 0 ? _run!.steps[_shown - 1].line : null,
      notes: {for (final s in _applied) if (s.note != null) s.line: s.note!},
      failed: _phase == _Phase.done && !(_run?.success ?? true),
    );
    final picker = _BlankPicker(
      options: _challenge.options,
      selected: _session.choice,
      enabled: _phase == _Phase.editing,
      onSelect: _select,
    );
    final controls = Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        GameButton(
          tone: ButtonTone.mint,
          size: GameButtonSize.large,
          icon: Icons.play_arrow_rounded,
          label: _phase == _Phase.running ? 'Running...' : 'Run code',
          semanticLabel: 'Run code',
          onPressed: _phase == _Phase.editing ? _runCode : null,
        ),
        GameButton(
          tone: ButtonTone.gold,
          icon: Icons.lightbulb_rounded,
          label: _hintOpen ? 'Hide hint' : 'Hint',
          onPressed: _phase == _Phase.editing ? () => setState(() => _hintOpen = !_hintOpen) : null,
        ),
      ],
    );
    final result = _result();

    return QuitGuard(
      active: !_session.isOver,
      child: Stack(
        children: [
          Positioned.fill(child: SceneBackground(kind: sceneFor(lang))),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GameTopBar(
              title: widget.level.title,
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: g.ink.withValues(alpha: g.highContrast ? 1 : 0.82),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2.5),
                  ),
                  child: HeartsBar(lives: _hearts, max: _session.maxLives, size: 22),
                ),
              ],
            ),
            body: Focus(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: _onKey,
              child: LayoutBuilder(
                builder: (context, box) {
                  if (box.maxWidth >= 980) {
                    // Make the stage as tall as the window allows, so the
                    // world (not empty background) fills the screen.
                    final stageWidth = math.min(box.maxWidth, 1360.0) * 11 / 20 - 24;
                    final stageHeight = box.maxHeight - 170;
                    final aspect = stageHeight <= 0
                        ? BuilderStage.maxAspect
                        : (stageWidth / stageHeight).clamp(BuilderStage.minAspect, BuilderStage.maxAspect);
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1360),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: ListView(
                                primary: false,
                                padding: const EdgeInsets.fromLTRB(16, 4, 8, 28),
                                children: [goal, const SizedBox(height: 10), stageWith(aspect)],
                              ),
                            ),
                            Expanded(
                              flex: 9,
                              child: ListView(
                                primary: false,
                                padding: const EdgeInsets.fromLTRB(8, 4, 16, 28),
                                children: [
                                  editor,
                                  const SizedBox(height: 12),
                                  if (_phase != _Phase.done) ...[picker, const SizedBox(height: 4), controls],
                                  if (result != null) result,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return PageBody(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      children: [
                        goal,
                        const SizedBox(height: 10),
                        stageWith(BuilderStage.defaultAspect),
                        const SizedBox(height: 16),
                        editor,
                        const SizedBox(height: 12),
                        if (_phase != _Phase.done) ...[picker, const SizedBox(height: 4), controls],
                        if (result != null) result,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(child: ConfettiBurst(trigger: _winTick)),
        ],
      ),
    );
  }

  Widget? _result() {
    final run = _run;
    if (_phase != _Phase.done || run == null) return null;
    if (run.success) {
      return FeedbackPanel(
        key: _resultKey,
        correct: true,
        headline: _challenge.obstacle == Obstacle.ledge ? 'Nice landing!' : 'It works!',
        explanation: '${run.message} ${_challenge.lesson}',
        continueLabel: _session.finished ? 'See results' : 'Next challenge',
        onContinue: _next,
      );
    }
    final out = _session.lives <= 0;
    return FeedbackPanel(
      key: _resultKey,
      correct: false,
      headline: run.outcome == BuildOutcome.error ? 'Code error!' : 'Bug found!',
      explanation: run.message,
      continueLabel: out ? 'See results' : 'Try again',
      onContinue: out ? _finish : _tryAgain,
      onAskBuddy: _askBuddy,
    );
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.index, required this.total, required this.goal, this.hint});

  final int index;
  final int total;
  final String goal;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ParchmentPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ByteAvatar(size: 50, bob: !reduceMotionOf(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Challenge ${index + 1} of $total',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: g.parchmentDim)),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(goal, style: displayStyle(19, color: g.ink, height: 1.3)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Emoji('💡', size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(hint!, style: TextStyle(fontSize: 16, color: g.parchmentText))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The program in an editor window. The blank shows the chosen value; while
/// the code runs, the current line lights up and notes show what happens.
class _CodeEditor extends StatelessWidget {
  const _CodeEditor({
    required this.challenge,
    required this.choice,
    required this.fileName,
    required this.activeLine,
    required this.notes,
    required this.failed,
  });

  final BuildChallenge challenge;
  final int choice;
  final String fileName;
  final int? activeLine;
  final Map<int, String> notes;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final code = TextStyle(fontFamily: codeFont, fontSize: 16, height: 1.5, color: g.codeText);
    final rows = <Widget>[];
    for (var i = 0; i < challenge.lines.length; i++) {
      final line = challenge.lines[i];
      final parts = line.split(blank);
      final note = notes[i];
      final active = activeLine == i;
      rows.add(
        Semantics(
          label: 'Line ${i + 1}: ${challenge.lineWith(i, choice).trim()}'
              '${note != null ? '. $note' : ''}${active ? '. Running now' : ''}',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.fromLTRB(8, 2, 12, 2),
            decoration: BoxDecoration(
              color: active ? g.gold.withValues(alpha: g.highContrast ? 0.35 : 0.24) : Colors.transparent,
              border: Border(left: BorderSide(color: active ? g.gold : Colors.transparent, width: 4)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text('${i + 1}', textAlign: TextAlign.right, style: code.copyWith(color: g.codeDim)),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: parts.first),
                      if (parts.length > 1) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _BlankChip(text: challenge.options[choice], failed: failed),
                        ),
                        TextSpan(text: parts.sublist(1).join(blank)),
                      ],
                    ],
                  ),
                  style: code,
                  softWrap: false,
                ),
                if (note != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: g.lilac,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: g.ink, width: 1.5),
                    ),
                    child: Text(note, style: TextStyle(fontFamily: codeFont, fontSize: 13, color: g.ink)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'Code, $fileName',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: g.codeBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
          boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Container(
                color: g.codeBar,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    for (final c in const [Color(0xFFFF6B7F), Color(0xFFFFC93C), Color(0xFF3DDC84)])
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                    const SizedBox(width: 6),
                    Text(fileName, style: TextStyle(fontFamily: codeFont, fontSize: 13, color: g.codeDim)),
                  ],
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: box.maxWidth),
                  child: IntrinsicWidth(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlankChip extends StatelessWidget {
  const _BlankChip({required this.text, required this.failed});

  final String text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: failed ? g.coral : g.gold,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: codeFont, fontSize: 16, fontWeight: FontWeight.w800, color: g.ink, height: 1.3),
      ),
    );
  }
}

/// The values the player can put in the blank.
class _BlankPicker extends StatelessWidget {
  const _BlankPicker({
    required this.options,
    required this.selected,
    required this.enabled,
    required this.onSelect,
  });

  final List<String> options;
  final int selected;
  final bool enabled;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ParchmentPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelBanner(text: 'Fill the blank', tone: ButtonTone.lilac, icon: Icons.edit_rounded),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              for (var i = 0; i < options.length; i++)
                GameButton(
                  key: ValueKey('blank-option-$i'),
                  tone: i == selected ? ButtonTone.gold : ButtonTone.parchment,
                  size: GameButtonSize.small,
                  semanticLabel: i == selected ? '${options[i]}, in the blank now' : 'Put ${options[i]} in the blank',
                  onPressed: enabled ? () => onSelect(i) : null,
                  child: Text(
                    options[i],
                    style: TextStyle(fontFamily: codeFont, fontSize: 17, fontWeight: FontWeight.w800, color: g.ink),
                  ),
                ),
            ],
          ),
          Text('Tip: press 1-${options.length} to choose, R to run.',
              style: TextStyle(fontSize: 13, color: g.parchmentDim)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
