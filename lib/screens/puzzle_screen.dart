import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/puzzle_session.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/game_ui.dart';
import '../widgets/scenes.dart';
import 'navigation.dart';

/// Block Builder: snap code blocks into the editor in the right order, then
/// run the program and watch its output appear in the console.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.level, this.random});

  final Level level;
  final Random? random;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

/// Colour of a code block, by what the line does.
ButtonTone blockTone(String line) {
  final t = line.trim();
  if (RegExp(r'^(if|elif|else|for|while|do|switch|\})').hasMatch(t)) return ButtonTone.lilac;
  if (RegExp(r'print|cout|System\.out').hasMatch(t)) return ButtonTone.mint;
  return ButtonTone.sky;
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final PuzzleSession _session = PuzzleSession(widget.level.puzzles, random: widget.random);
  final GlobalKey _feedbackKey = GlobalKey();

  PuzzleCheck? _check;
  String? _message;
  int _shakeTick = 0;
  int _winTick = 0;

  void _place(int id) => setState(() {
        _session.place(id);
        _check = null;
        _message = null;
      });

  void _unplace(int id) => setState(() {
        _session.unplace(id);
        _check = null;
        _message = null;
      });

  void _clear() => setState(() {
        _session.clear();
        _check = null;
        _message = null;
      });

  void _hint() => setState(() {
        _session.hint();
        _check = null;
        _message = 'Hint used: the first wrong block was fixed for you.';
      });

  void _run() {
    if (!_session.readyToCheck) return;
    setState(() {
      _check = _session.check();
      if (_check!.solved) {
        _message = null;
        _winTick++;
        HapticFeedback.lightImpact();
      } else {
        final wrong = _check!.lineCorrect.where((ok) => !ok).length;
        _shakeTick++;
        HapticFeedback.heavyImpact();
        _message = _session.lives <= 0
            ? 'Out of hearts! $wrong block${wrong == 1 ? ' is' : 's are'} in the wrong place.'
            : 'Bug found: $wrong block${wrong == 1 ? ' is' : 's are'} in the wrong place. '
                'Tap a red line to take it back. You lost a heart.';
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  void _continue() {
    if (_session.isOver) {
      _finish();
      return;
    }
    setState(() {
      _session.nextPuzzle();
      _check = null;
      _message = null;
    });
  }

  void _finish() {
    final s = _session;
    finishLevel(
      context,
      GameOutcome(
        level: widget.level,
        won: s.won,
        correct: s.solvedCount * 3,
        total: s.puzzles.length * 3,
        stars: puzzleStars(mistakes: s.mistakes, won: s.won),
        review: s.won
            ? const []
            : [
                ReviewItem(
                  prompt: s.current.goal,
                  code: s.current.lines.join('\n'),
                  correctAnswer: 'The program above, in this order',
                  explanation: s.current.explanation,
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final spec = _session.current;
    final check = _check;
    final solved = _session.currentSolved;
    final lang = widget.level.lang;

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
                  child: HeartsBar(lives: _session.lives, max: _session.maxLives, size: 22),
                ),
              ],
            ),
            body: PageBody(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: HudPill(
                      leading: const Emoji('🧩', size: 20),
                      text: 'Puzzle ${_session.index + 1} of ${_session.puzzles.length}',
                      semanticLabel: 'Puzzle ${_session.index + 1} of ${_session.puzzles.length}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ParchmentPanel(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Emoji('🎯', size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(spec.goal, style: displayStyle(21, color: g.ink, height: 1.3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shake(
                    trigger: _shakeTick,
                    child: _Editor(
                      fileName: lang.fileName,
                      placed: _session.placed,
                      check: check,
                      locked: solved,
                      onRemove: _unplace,
                    ),
                  ),
                  if (check != null) ...[
                    const SizedBox(height: 10),
                    _Console(spec: spec, solved: check.solved, fileName: lang.fileName),
                  ],
                  const SizedBox(height: 14),
                  if (!solved) ...[
                    ParchmentPanel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PanelBanner(text: 'Code blocks', tone: ButtonTone.lilac, icon: Icons.extension_rounded),
                          const SizedBox(height: 10),
                          if (_session.pool.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('All blocks placed. Press Run code!',
                                  style: TextStyle(color: g.parchmentDim, fontSize: 16)),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 2,
                              children: [
                                for (final token in _session.pool)
                                  GameButton(
                                    key: ValueKey('block-${token.id}'),
                                    tone: blockTone(token.text),
                                    size: GameButtonSize.small,
                                    semanticLabel: 'Add block: ${token.text.trim()}'
                                        '${token.text.startsWith(' ') ? ' (indented)' : ''}',
                                    onPressed: () => _place(token.id),
                                    child: Text(
                                      token.text,
                                      style: TextStyle(
                                        fontFamily: codeFont,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: g.ink,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        GameButton(
                          tone: ButtonTone.mint,
                          onPressed: _session.readyToCheck && !_session.isOver ? _run : null,
                          icon: Icons.play_arrow_rounded,
                          label: 'Run code',
                        ),
                        GameButton(
                          tone: ButtonTone.parchment,
                          onPressed: _session.placed.isEmpty ? null : _clear,
                          icon: Icons.undo_rounded,
                          label: 'Clear',
                        ),
                        GameButton(
                          tone: ButtonTone.gold,
                          onPressed: _session.isOver ? null : _hint,
                          icon: Icons.lightbulb_rounded,
                          label: 'Hint',
                        ),
                      ],
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      container: true,
                      child: ParchmentPanel(
                        key: _feedbackKey,
                        borderColor: check != null ? g.coralLip : null,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Emoji(check != null ? '🐞' : '💡', size: 24),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_message!, style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      ),
                    ),
                    if (_session.lives <= 0) ...[
                      const SizedBox(height: 6),
                      GameButton(onPressed: _finish, label: 'See results', icon: Icons.arrow_forward_rounded),
                    ],
                  ],
                  if (solved) ...[
                    const SizedBox(height: 4),
                    FeedbackPanel(
                      key: _feedbackKey,
                      correct: true,
                      headline: 'Program works!',
                      explanation: spec.explanation,
                      continueLabel: _session.isOver ? 'See results' : 'Next puzzle',
                      onContinue: _continue,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned.fill(child: ConfettiBurst(trigger: _winTick)),
        ],
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.fileName,
    required this.placed,
    required this.check,
    required this.locked,
    required this.onRemove,
  });

  final String fileName;
  final List<PuzzleToken> placed;
  final PuzzleCheck? check;
  final bool locked;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final c = check;
    return Container(
      decoration: BoxDecoration(
        color: g.codeBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: locked ? g.mint : (g.highContrast ? Colors.white : g.ink), width: g.outlineWidth + 0.5),
        boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: g.codeBar,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final dot in const [Color(0xFFFF6B7F), Color(0xFFFFC93C), Color(0xFF3DDC84)])
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                const SizedBox(width: 8),
                Text(fileName, style: TextStyle(fontFamily: codeFont, fontSize: 14, color: g.codeText)),
                const Spacer(),
                Text('${placed.length} line${placed.length == 1 ? '' : 's'}',
                    style: TextStyle(fontFamily: codeFont, fontSize: 13, color: g.codeDim)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 8, 10),
            child: placed.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text('Tap the blocks below to add them here, in order.',
                        style: TextStyle(color: g.codeDim, fontSize: 15)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < placed.length; i++)
                        _Line(
                          number: i + 1,
                          token: placed[i],
                          status: c == null || i >= c.lineCorrect.length ? null : c.lineCorrect[i],
                          locked: locked,
                          onTap: () => onRemove(placed[i].id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.number,
    required this.token,
    required this.status,
    required this.locked,
    required this.onTap,
  });

  final int number;
  final PuzzleToken token;

  /// null = not checked yet, true = right place, false = wrong place.
  final bool? status;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final statusText = status == null ? '' : (status! ? ', correct place' : ', wrong place');
    final stripe = switch (blockTone(token.text)) {
      ButtonTone.lilac => g.lilac,
      ButtonTone.mint => g.mint,
      _ => g.sky,
    };
    return Semantics(
      button: !locked,
      label: 'Line $number: ${token.text.trim()}$statusText${locked ? '' : '. Tap to remove'}',
      excludeSemantics: true,
      onTap: locked ? null : onTap,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: status == false ? g.coral.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('$number',
                    textAlign: TextAlign.right, style: TextStyle(fontFamily: codeFont, color: g.codeDim)),
              ),
              const SizedBox(width: 8),
              Container(width: 4, height: 30, color: stripe),
              const SizedBox(width: 10),
              Expanded(
                child: Text(token.text, style: TextStyle(fontFamily: codeFont, fontSize: 15, color: g.codeText)),
              ),
              if (status != null)
                Icon(status! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: status! ? g.mint : g.coral, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny terminal that "runs" the program.
class _Console extends StatelessWidget {
  const _Console({required this.spec, required this.solved, required this.fileName});

  final PuzzleSpec spec;
  final bool solved;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    const base = TextStyle(fontFamily: codeFont, fontSize: 15, height: 1.5);
    return Semantics(
      container: true,
      label: solved ? 'Program output: ${spec.output}' : 'Program has a bug',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: g.outlineWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$ run $fileName', style: base.copyWith(color: const Color(0xFFBBA8DD))),
              if (spec.input != null && solved)
                Text('> ${spec.input}   (you typed this)', style: base.copyWith(color: const Color(0xFF9BDCFF))),
              if (solved)
                Typewriter(spec.output, style: base.copyWith(color: const Color(0xFF3DDC84), fontWeight: FontWeight.w700), charMs: 60)
              else
                Text('Error: the program ran in the wrong order.',
                    style: base.copyWith(color: const Color(0xFFFF8A9A), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
