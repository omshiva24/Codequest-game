import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/puzzle_session.dart';
import '../logic/scoring.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';

/// Block Builder: tap code blocks in the right order to build a program.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, required this.level, this.random});

  final Level level;
  final Random? random;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final PuzzleSession _session = PuzzleSession(widget.level.puzzles, random: widget.random);
  final GlobalKey _feedbackKey = GlobalKey();

  PuzzleCheck? _check;
  String? _message;

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

  void _checkAnswer() {
    if (!_session.readyToCheck) return;
    setState(() {
      _check = _session.check();
      if (_check!.solved) {
        _message = null;
      } else {
        final wrong = _check!.lineCorrect.where((ok) => !ok).length;
        _message = _session.lives <= 0
            ? 'Out of hearts! $wrong block${wrong == 1 ? ' is' : 's are'} in the wrong place.'
            : 'Not quite: $wrong block${wrong == 1 ? ' is' : 's are'} in the wrong place. '
                'Tap a block to take it back. You lost a heart.';
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _feedbackKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
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
    final color = widget.level.lang.color;
    final check = _check;
    final solved = _session.currentSolved;

    return QuitGuard(
      active: !_session.isOver,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.level.title),
          actions: [
            HeartsBar(lives: _session.lives, max: _session.maxLives),
            const SizedBox(width: 12),
          ],
        ),
        body: PageBody(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('Puzzle ${_session.index + 1} of ${_session.puzzles.length}',
                  style: TextStyle(color: g.textDim, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Emoji('🎯', size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(spec.goal,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text('Your program',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: g.coin)),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: g.codeBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: solved ? g.good : g.border, width: 2),
                ),
                child: _session.placed.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Tap the blocks below to add them here, in order.',
                            style: TextStyle(color: g.textDim)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < _session.placed.length; i++)
                            _PlacedLine(
                              number: i + 1,
                              token: _session.placed[i],
                              status: check == null || i >= check.lineCorrect.length
                                  ? null
                                  : check.lineCorrect[i],
                              locked: solved,
                              onTap: () => _unplace(_session.placed[i].id),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              if (!solved) ...[
                Semantics(
                  header: true,
                  child: Text('Code blocks',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: g.coin)),
                ),
                const SizedBox(height: 6),
                if (_session.pool.isEmpty)
                  Text('All blocks placed. Press Check!', style: TextStyle(color: g.textDim))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final token in _session.pool)
                        _Block(token: token, color: color, onTap: () => _place(token.id)),
                    ],
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _session.readyToCheck && !_session.isOver ? _checkAnswer : null,
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('Check'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _session.placed.isEmpty ? null : _clear,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Clear'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _session.isOver ? null : _hint,
                      icon: const Icon(Icons.lightbulb_rounded),
                      label: const Text('Hint'),
                    ),
                  ],
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    key: _feedbackKey,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: g.cardRaised,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: check != null ? g.bad : g.coin, width: 2),
                    ),
                    child: Text(_message!, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                if (_session.lives <= 0) ...[
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _finish, child: const Text('See results')),
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
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.token, required this.color, required this.onTap});

  final PuzzleToken token;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      button: true,
      label: 'Add block: ${token.text.trim()}'
          '${token.text.startsWith(' ') ? ' (indented)' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: g.cardRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                token.text,
                style: const TextStyle(fontFamily: codeFont, fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacedLine extends StatelessWidget {
  const _PlacedLine({
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
    return Semantics(
      button: !locked,
      label: 'Line $number: ${token.text.trim()}$statusText${locked ? '' : '. Tap to remove'}',
      excludeSemantics: true,
      onTap: locked ? null : onTap,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('$number',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: codeFont, color: g.textDim)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  token.text,
                  style: TextStyle(fontFamily: codeFont, fontSize: 15, color: g.codeText),
                ),
              ),
              if (status != null)
                Icon(status! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: status! ? g.good : g.bad, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
