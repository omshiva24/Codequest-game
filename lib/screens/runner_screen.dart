import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../logic/progress.dart';
import '../logic/quiz_session.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// Temple-Run style game: answers are gates on a 3-lane track.
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
  final FocusNode _focus = FocusNode(debugLabel: 'runner-game');
  final GlobalKey _feedbackKey = GlobalKey();

  int _lane = 1;
  AnswerResult? _last;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _approach = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _resolve();
      });
    _scroll = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
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
    _focus.dispose();
    super.dispose();
  }

  TimerMode get _timerMode => AppScope.read(context).settings.timerMode;

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.stop();
    } else {
      _scroll.repeat();
    }
  }

  void _setLane(int lane) {
    final q = _session.current;
    if (_last != null || q == null) return;
    setState(() => _lane = lane.clamp(0, q.options.length - 1));
  }

  void _resolve() {
    if (_last != null || _session.isOver) return;
    _approach.stop();
    _scroll.stop();
    final result = _session.answer(_lane);
    setState(() => _last = result);
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
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _setLane(_lane - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _setLane(_lane + 1);
      return KeyEventResult.handled;
    }
    const digits = [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3];
    const numpad = [LogicalKeyboardKey.numpad1, LogicalKeyboardKey.numpad2, LogicalKeyboardKey.numpad3];
    var index = digits.indexOf(key);
    if (index < 0) index = numpad.indexOf(key);
    if (index >= 0) {
      _setLane(index);
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
    final level = widget.level;
    final last = _last;
    final question = last?.question ?? _session.current;
    final timerOn = _timerMode != TimerMode.off;
    final answeredCount = _session.history.length;

    return QuitGuard(
      active: !_session.isOver,
      child: Scaffold(
        appBar: AppBar(
          title: Text(level.title),
          actions: [
            HeartsBar(lives: _session.lives, max: _session.maxLives),
            const SizedBox(width: 8),
            StatPill(
              icon: Icons.monetization_on_rounded,
              value: '${_session.solved * 5}',
              semanticLabel: '${_session.solved * 5} coins this level',
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: question == null
              ? const SizedBox.shrink()
              : PageBody(
                  maxWidth: 720,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final trackHeight = (constraints.maxHeight * 0.45).clamp(240.0, 380.0);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Row(
                            children: [
                              Text(
                                'Gate ${min(answeredCount + (last == null ? 1 : 0), _session.total)} of ${_session.total}',
                                style: TextStyle(color: g.textDim, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (timerOn && last == null)
                                Text(_timerMode == TimerMode.relaxed ? 'Relaxed timer' : 'Timer on',
                                    style: TextStyle(color: g.textDim)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (timerOn)
                            AnimatedBuilder(
                              animation: _approach,
                              builder: (context, _) => Semantics(
                                label: 'Time left',
                                value: '${((1 - _approach.value) * 100).round()} percent',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: last == null ? 1 - _approach.value : 0,
                                    minHeight: 8,
                                    color: level.lang.color,
                                    backgroundColor: g.cardRaised,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          _QuestionCard(question: question.source),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: trackHeight,
                            child: _buildTrack(context, question, trackHeight),
                          ),
                          const SizedBox(height: 12),
                          if (last == null)
                            _buildControls(context, question)
                          else
                            FeedbackPanel(
                              key: _feedbackKey,
                              correct: last.correct,
                              headline: last.correct
                                  ? _cheers[answeredCount % _cheers.length]
                                  : (_session.lives <= 0 ? 'Out of hearts!' : 'Oops! Wrong gate.'),
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
    );
  }

  Widget _buildControls(BuildContext context, PlayQuestion q) {
    final g = GameColors.of(context);
    final timerOff = _timerMode == TimerMode.off;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _lane > 0 ? () => _setLane(_lane - 1) : null,
                child: const Icon(Icons.arrow_back_rounded, semanticLabel: 'Move left'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Semantics(
                button: true,
                label: 'Run through gate ${_lane + 1}: ${q.options[_lane]}',
                excludeSemantics: true,
                onTap: _resolve,
                child: FilledButton.icon(
                  onPressed: _resolve,
                  icon: const Icon(Icons.directions_run_rounded),
                  label: Text(timerOff ? 'Go!' : 'Dash!'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _lane < q.options.length - 1 ? () => _setLane(_lane + 1) : null,
                child: const Icon(Icons.arrow_forward_rounded, semanticLabel: 'Move right'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a gate, swipe, or use the arrow keys / 1-3. Space to dash.',
          textAlign: TextAlign.center,
          style: TextStyle(color: g.textDim, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTrack(BuildContext context, PlayQuestion q, double height) {
    final g = GameColors.of(context);
    final color = widget.level.lang.color;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final staticGates = reduceMotion || _timerMode == TimerMode.off;
    final last = _last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final lanes = q.options.length;
        final laneWidth = width / lanes;
        const gateHeight = 78.0;
        const playerSize = 64.0;
        final travel = height - gateHeight - playerSize - 28;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -100) _setLane(_lane - 1);
            if (v > 100) _setLane(_lane + 1);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_approach, _scroll]),
            builder: (context, _) {
              final progress = last != null ? 1.0 : (staticGates ? 0.55 : _approach.value);
              final gateTop = 10 + travel * progress;
              final bounce = reduceMotion ? 0.0 : sin(_scroll.value * 2 * pi) * 3;
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: _TrackPainter(
                            lanes: lanes,
                            offset: _scroll.value,
                            road: g.card,
                            line: g.border,
                            accent: color,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < lanes; i++)
                      Positioned(
                        left: i * laneWidth + 6,
                        width: laneWidth - 12,
                        top: gateTop,
                        height: gateHeight,
                        child: _Gate(
                          index: i,
                          text: q.options[i],
                          selected: i == _lane,
                          color: color,
                          state: last == null
                              ? _GateState.open
                              : i == q.correctIndex
                                  ? _GateState.correct
                                  : (i == last.chosenIndex ? _GateState.wrong : _GateState.faded),
                          onTap: () => _setLane(i),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      left: _lane * laneWidth + (laneWidth - playerSize) / 2,
                      bottom: 10 + bounce,
                      width: playerSize,
                      height: playerSize,
                      child: ExcludeSemantics(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 14)],
                          ),
                          child: const Text('🏃', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(question.prompt,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35)),
            ),
            if (question.code != null) ...[
              const SizedBox(height: 10),
              CodeBlock(question.code!),
            ],
          ],
        ),
      ),
    );
  }
}

enum _GateState { open, correct, wrong, faded }

class _Gate extends StatelessWidget {
  const _Gate({
    required this.index,
    required this.text,
    required this.selected,
    required this.color,
    required this.state,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final Color color;
  final _GateState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final (border, icon) = switch (state) {
      _GateState.correct => (g.good, Icons.check_circle_rounded),
      _GateState.wrong => (g.bad, Icons.cancel_rounded),
      _GateState.faded => (g.border, null),
      _GateState.open => (selected ? Colors.white : color, null),
    };
    final stateText = switch (state) {
      _GateState.correct => ', correct answer',
      _GateState.wrong => ', your answer, wrong',
      _ => selected ? ', selected' : '',
    };
    return Semantics(
      button: state == _GateState.open,
      selected: selected,
      label: 'Gate ${index + 1}: $text$stateText',
      excludeSemantics: true,
      onTap: state == _GateState.open ? onTap : null,
      child: GestureDetector(
        onTap: state == _GateState.open ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected && state == _GateState.open ? g.cardRaised : g.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: selected || state != _GateState.open ? 4 : 2),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text('${index + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: g.onAccent)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: codeFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: border, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.lanes,
    required this.offset,
    required this.road,
    required this.line,
    required this.accent,
  });

  final int lanes;
  final double offset;
  final Color road;
  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = road);
    final laneWidth = size.width / lanes;
    final dash = Paint()
      ..color = line
      ..strokeWidth = 3;
    const dashLength = 18.0;
    const gap = 14.0;
    final shift = offset * (dashLength + gap);
    for (var i = 1; i < lanes; i++) {
      final x = i * laneWidth;
      for (var y = -dashLength + shift; y < size.height; y += dashLength + gap) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashLength), dash);
      }
    }
    final edge = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..strokeWidth = 5;
    canvas
      ..drawLine(const Offset(2, 0), Offset(2, size.height), edge)
      ..drawLine(Offset(size.width - 2, 0), Offset(size.width - 2, size.height), edge);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.offset != offset || old.lanes != lanes || old.road != road || old.accent != accent;
}
