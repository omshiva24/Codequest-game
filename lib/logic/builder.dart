// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

/// World Builder: the code you write changes the world.
///
/// Each challenge is a tiny program with one blank. The player fills the
/// blank, presses Run, and the program is simulated step by step: loops place
/// bridge blocks, variables set the jump height, print() says a password.
/// The result then plays out in the world - a bridge one block short really
/// does drop Byte into the river - and Byte explains exactly why.
///
/// Everything here is pure Dart (no Flutter), so it is easy to test.
library;

import '../models/models.dart';

/// Marks the blank the player fills in, inside a line of code.
const String blank = '{?}';

/// What stands in Byte's way.
enum Obstacle {
  /// A river / pit / moat / lava gap: build a bridge across it.
  gap,

  /// A raised ledge with spikes above it: jump exactly onto it.
  ledge,

  /// A tall ledge: build stairs up to it.
  stairs,

  /// A guard and a gate: say (print) the password.
  guard,

  /// A troll's toll gate: collect exactly the right number of coins.
  toll,
}

/// How Byte's attempt ends. Drives the animation and the message.
enum BuildOutcome {
  /// Success: walks over the bridge, up the stairs or through the gate.
  cross,

  /// Success: the jump lands exactly on the ledge.
  land,

  /// The bridge is too short: Byte falls into the gap.
  fall,

  /// Too many blocks or steps: the extra one sticks up and trips Byte.
  trip,

  /// Jump too low, or stairs too short: Byte cannot reach the top.
  short,

  /// Jump too high: Byte bumps into the spiky ceiling.
  bonkCeiling,

  /// The guard or troll keeps the gate shut.
  blocked,

  /// The code could not run at all (for example, text without quotes).
  error;

  bool get success => this == cross || this == land;
}

/// What one step of the program does to the world.
enum StepEffect { none, block, step, coins, say, jump, pay, error, skip }

/// One step of the program, as it runs. [line] is the 0-based code line.
class TraceStep {
  const TraceStep(this.line, {this.note, this.effect = StepEffect.none, this.value = 0, this.text});

  final int line;

  /// Short explanation shown next to the line, e.g. "i = 2".
  final String? note;
  final StepEffect effect;

  /// Blocks or steps built so far, coins so far, or the jump height.
  final int value;

  /// Printed text, or an error message.
  final String? text;
}

/// The full result of running one challenge's code.
class BuildRun {
  const BuildRun({
    required this.steps,
    required this.outcome,
    required this.message,
    this.amount = 0,
    this.said,
  });

  final List<TraceStep> steps;
  final BuildOutcome outcome;

  /// Why it worked or failed, in simple words, using the real numbers.
  final String message;

  /// Blocks or steps built, coins collected, or jump height.
  final int amount;

  /// Text the program printed, if any.
  final String? said;

  bool get success => outcome.success;
}

/// One challenge: a tiny program with exactly one blank.
class BuildChallenge {
  BuildChallenge({
    required this.id,
    required this.lang,
    required this.obstacle,
    required this.size,
    required this.goal,
    required this.lines,
    required this.options,
    required this.initial,
    required this.hint,
    required this.lesson,
    required BuildRun Function(String choice) runner,
    this.password,
  }) : _runner = runner {
    assert(lines.where((l) => l.contains(blank)).length == 1, '$id needs exactly one blank');
    assert(initial >= 0 && initial < options.length, '$id has a bad initial choice');
  }

  final String id;
  final Lang lang;
  final Obstacle obstacle;

  /// Gap width, ledge height, stairs height or toll price.
  final int size;

  /// What to do, shown above the world.
  final String goal;

  /// The program. Exactly one line contains [blank].
  final List<String> lines;

  /// Values the player can put in the blank.
  final List<String> options;

  /// The value the blank starts with. It is always a wrong one.
  final int initial;

  /// Byte's tip if the player asks for help.
  final String hint;

  /// The idea this challenge teaches, shown after it works.
  final String lesson;

  /// The password the guard wants (guard challenges only).
  final String? password;

  final BuildRun Function(String choice) _runner;

  BuildRun run(int optionIndex) {
    RangeError.checkValidIndex(optionIndex, options, 'optionIndex');
    return _runner(options[optionIndex]);
  }

  /// Index of the line with the blank.
  int get blankLine => lines.indexWhere((l) => l.contains(blank));

  /// The line with the blank filled in.
  String lineWith(int line, int optionIndex) => lines[line].replaceFirst(blank, options[optionIndex]);

  /// The whole program with the blank filled in.
  String codeWith(int optionIndex) =>
      [for (var i = 0; i < lines.length; i++) lineWith(i, optionIndex)].join('\n');

  /// Index of the first option that solves the challenge, or -1.
  int get answer {
    for (var i = 0; i < options.length; i++) {
      if (run(i).success) return i;
    }
    return -1;
  }
}

// ---------------------------------------------------------------------------
// Real syntax for each language
// ---------------------------------------------------------------------------

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

/// Writes the same idea in Python, C, C++ or Java syntax.
class LangSyntax {
  const LangSyntax(this.lang);

  final Lang lang;

  bool get isPython => lang == Lang.python;

  static const String indent = '    ';

  /// snake_case in Python and C, camelCase in C++ and Java.
  String name(String snake) => (lang == Lang.cpp || lang == Lang.java) ? _camel(snake) : snake;

  /// A call to one of Byte's abilities. C has no objects, so it is a plain
  /// function there; the others call a method on the `hero` object.
  String call(String snake, [String args = '']) => switch (lang) {
        Lang.python => 'hero.$snake($args)',
        Lang.c => '$snake($args);',
        Lang.cpp || Lang.java => 'hero.${_camel(snake)}($args);',
      };

  String declare(String snake, String value) =>
      isPython ? '${name(snake)} = $value' : 'int ${name(snake)} = $value;';

  String assign(String snake, String value) =>
      isPython ? '${name(snake)} = $value' : '${name(snake)} = $value;';

  String increment(String snake) => isPython ? '${name(snake)} += 1' : '${name(snake)}++;';

  String forCount(String limit) =>
      isPython ? 'for i in range($limit):' : 'for (int i = 0; i < $limit; i++) {';

  String forFromOne(String limit) =>
      isPython ? 'for i in range(1, $limit):' : 'for (int i = 1; i < $limit; i++) {';

  String forCompare(String op, int limit) => 'for (int i = 0; i $op $limit; i++) {';

  String whileLoop(String condition) => isPython ? 'while $condition:' : 'while ($condition) {';

  String print(String arg) => switch (lang) {
        Lang.python => 'print($arg)',
        Lang.c => 'printf($arg);',
        Lang.cpp => 'cout << $arg;',
        Lang.java => 'System.out.println($arg);',
      };

  /// Closing brace for C, C++ and Java blocks (Python uses indentation).
  List<String> get close => isPython ? const [] : const ['}'];

  /// How the print command is called, for messages.
  String get printName => switch (lang) {
        Lang.python => 'print()',
        Lang.c => 'printf()',
        Lang.cpp => 'cout <<',
        Lang.java => 'System.out.println()',
      };

  /// The compiler or interpreter's complaint about an unknown name.
  String unknownName(String word) => switch (lang) {
        Lang.python => "NameError: name '$word' is not defined",
        Lang.c => "error: '$word' undeclared",
        Lang.cpp => "error: '$word' was not declared in this scope",
        Lang.java => 'error: cannot find symbol $word',
      };
}

// ---------------------------------------------------------------------------
// Challenge builders
// ---------------------------------------------------------------------------

int _int(String choice) => int.parse(choice.trim());

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

BuildOutcome _gapOutcome(int built, int gap) =>
    built == gap ? BuildOutcome.cross : (built < gap ? BuildOutcome.fall : BuildOutcome.trip);

String _gapMessage(int built, int gap, String how) {
  if (built == gap) return '$how built ${_plural(built, 'block')} - exactly the width of the gap. Perfect bridge!';
  if (built < gap) {
    return '$how built only ${_plural(built, 'block')}, but the gap is $gap wide. '
        'The bridge stopped short and Byte fell in.';
  }
  return '$how built ${_plural(built, 'block')}, but the gap is only $gap wide. '
      'The extra ${built - gap == 1 ? 'block sticks' : 'blocks stick'} up at the end and Byte tripped. '
      'You need exactly $gap.';
}

/// Say the password: teaches print and strings (quotes, exact text).
BuildChallenge guardChallenge({
  required String id,
  required Lang lang,
  required String password,
  required List<String> options,
  required int initial,
}) {
  final s = LangSyntax(lang);
  final quoteRule = s.isPython
      ? 'Text (a string) goes inside quotes'
      : 'Text (a string) goes inside double quotes';
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.guard,
    size: 0,
    password: password,
    goal: 'The guard opens the gate only for the password $password. Make Byte say it with ${s.printName}.',
    lines: [s.print(blank)],
    options: options,
    initial: initial,
    hint: '$quoteRule, like "$password". Capital letters must match too.',
    lesson: '${s.printName} shows text. $quoteRule, and it must match exactly - '
        '"$password" and "${password.toLowerCase()}" are different strings.',
    runner: (choice) {
      final t = choice.trim();
      String? text;
      String? error;
      String why = '';
      if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
        text = t.substring(1, t.length - 1);
      } else if (t.length >= 2 && t.startsWith("'") && t.endsWith("'")) {
        if (s.isPython) {
          text = t.substring(1, t.length - 1);
        } else {
          error = 'error: single quotes are for one character';
          why = "In ${lang.label}, single quotes hold just one character, like 'A'. "
              'Text needs double quotes: "$password".';
        }
      } else {
        error = s.unknownName(t);
        why = 'Without quotes, ${lang.label} thinks $t is a variable name - and there is no '
            'variable called $t. Put the text in quotes: "$password".';
      }
      if (error != null) {
        return BuildRun(
          steps: [TraceStep(0, note: 'error!', effect: StepEffect.error, text: error)],
          outcome: BuildOutcome.error,
          message: 'The code did not run: $error. $why',
        );
      }
      final said = text!;
      final ok = said == password;
      return BuildRun(
        steps: [TraceStep(0, note: 'prints $said', effect: StepEffect.say, text: said)],
        outcome: ok ? BuildOutcome.cross : BuildOutcome.blocked,
        said: said,
        message: ok
            ? 'Byte said "$said" - the exact password. The gate opens!'
            : 'Byte said "$said", but the password is "$password". Strings must match exactly, '
                'and capital letters count.',
      );
    },
  );
}

/// How the jump height is written.
enum JumpForm { direct, plus, minus }

/// Jump onto a ledge: teaches variables and simple maths.
BuildChallenge jumpChallenge({
  required String id,
  required Lang lang,
  required int height,
  required JumpForm form,
  required int initial,
}) {
  final s = LangSyntax(lang);
  final v = s.name('jump_height');
  final expression = switch (form) {
    JumpForm.direct => blank,
    JumpForm.plus => '1 + $blank',
    JumpForm.minus => '$blank - 1',
  };
  final options = [for (var n = 1; n <= 6; n++) '$n'];
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.ledge,
    size: height,
    goal: switch (form) {
      JumpForm.direct => 'This ledge is $height blocks high, with spikes above it. '
          'Set $v so Byte lands exactly on top.',
      _ => 'The ledge is $height blocks high, with spikes above it. '
          'Fill the blank so $v works out to exactly $height.',
    },
    lines: [s.declare('jump_height', expression), s.call('jump', v)],
    options: options,
    initial: initial,
    hint: switch (form) {
      JumpForm.direct => 'A variable is a box with a value. Put the ledge height, $height, in $v.',
      JumpForm.plus => '1 + ? must make $height. What number plus 1 is $height?',
      JumpForm.minus => '? - 1 must make $height. Which number minus 1 is $height?',
    },
    lesson: switch (form) {
      JumpForm.direct => 'A variable stores a value under a name. $v held $height, and '
          '${s.call('jump', v).replaceAll(';', '')} used it.',
      _ => 'A variable can store the result of a sum. The computer works out the maths first, '
          'then stores the answer in $v.',
    },
    runner: (choice) {
      final n = _int(choice);
      final jump = switch (form) {
        JumpForm.direct => n,
        JumpForm.plus => 1 + n,
        JumpForm.minus => n - 1,
      };
      final working = switch (form) {
        JumpForm.direct => '$v = $jump',
        JumpForm.plus => '$v = 1 + $n = $jump',
        JumpForm.minus => '$v = $n - 1 = $jump',
      };
      final outcome = jump == height
          ? BuildOutcome.land
          : (jump < height ? BuildOutcome.short : BuildOutcome.bonkCeiling);
      return BuildRun(
        steps: [
          TraceStep(0, note: working, value: jump),
          TraceStep(1, note: 'jump $jump', effect: StepEffect.jump, value: jump),
        ],
        outcome: outcome,
        amount: jump,
        message: switch (outcome) {
          BuildOutcome.land => '$v was $jump, so Byte jumped exactly $jump blocks and landed on the ledge.',
          BuildOutcome.short => '$v was $jump, but the ledge is $height blocks high. '
              'Byte hit the wall - the jump needs to be bigger.',
          _ => '$v was $jump - too high! Byte bumped into the spikes above the ledge. '
              'The ledge is $height blocks high.',
        },
      );
    },
  );
}

/// How the bridge size is worked out.
enum BridgeForm { plus, times }

/// Build a bridge from a variable: teaches variables and arithmetic.
BuildChallenge bridgeChallenge({
  required String id,
  required Lang lang,
  required int gap,
  required BridgeForm form,
  required int initial,
}) {
  final s = LangSyntax(lang);
  final v = s.name('planks');
  final expression = form == BridgeForm.plus ? '2 + $blank' : '$blank * 2';
  final options = [for (var n = 1; n <= 6; n++) '$n'];
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.gap,
    size: gap,
    goal: 'The gap is $gap blocks wide. Fill the blank so $v is exactly $gap, then build the bridge.',
    lines: [s.declare('planks', expression), s.call('build_bridge', v)],
    options: options,
    initial: initial,
    hint: form == BridgeForm.plus
        ? '2 + ? must make $gap. What number plus 2 is $gap?'
        : '? * 2 means "? times 2". Which number times 2 is $gap?',
    lesson: 'The computer did the maths, stored the answer in the variable $v, '
        'and the bridge used that value.',
    runner: (choice) {
      final n = _int(choice);
      final built = form == BridgeForm.plus ? 2 + n : n * 2;
      final working = form == BridgeForm.plus ? '$v = 2 + $n = $built' : '$v = $n * 2 = $built';
      return BuildRun(
        steps: [
          TraceStep(0, note: working, value: built),
          for (var k = 1; k <= built; k++)
            TraceStep(1, note: 'block $k of $built', effect: StepEffect.block, value: k),
        ],
        outcome: _gapOutcome(built, gap),
        amount: built,
        message: _gapMessage(built, gap, '$v was $built, so the bridge'),
      );
    },
  );
}

/// The kind of loop used to build a bridge.
enum LoopForm {
  /// for i in range(n) / for (i = 0; i < n; i++)
  count,

  /// for i in range(1, n) / for (i = 1; i < n; i++) - one fewer round!
  fromOne,

  /// The comparison is the blank: < or <= or > (off-by-one lesson).
  compare,
}

/// Build a bridge with a loop: teaches counting loops and off-by-one errors.
BuildChallenge loopBridgeChallenge({
  required String id,
  required Lang lang,
  required int gap,
  required LoopForm form,
  required int initial,
}) {
  final s = LangSyntax(lang);
  final body = '${LangSyntax.indent}${s.call('build_block')}';
  late final List<String> lines;
  late final List<String> options;
  // Python writes the comparison lesson as a while loop.
  final pythonCompare = s.isPython && form == LoopForm.compare;
  switch (form) {
    case LoopForm.count:
      lines = [s.forCount(blank), body, ...s.close];
      options = [for (var n = 1; n <= 7; n++) '$n'];
    case LoopForm.fromOne:
      lines = [s.forFromOne(blank), body, ...s.close];
      options = [for (var n = 2; n <= 8; n++) '$n'];
    case LoopForm.compare:
      options = const ['<', '<=', '>'];
      lines = pythonCompare
          ? ['i = 0', s.whileLoop('i $blank 4'), body, '${LangSyntax.indent}i += 1']
          : [s.forCompare(blank, 4), body, ...s.close];
  }
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.gap,
    size: gap,
    goal: 'The gap is $gap blocks wide. Each round of the loop builds one block. '
        'Make the loop run exactly $gap times.',
    lines: lines,
    options: options,
    initial: initial,
    hint: switch (form) {
      LoopForm.count => s.isPython
          ? 'range(n) counts 0, 1, 2 ... up to n - 1, so it runs n times.'
          : 'i starts at 0 and the loop runs while i < n, so it runs n times.',
      LoopForm.fromOne => s.isPython
          ? 'range(1, n) starts at 1, not 0, so it runs n - 1 times.'
          : 'i starts at 1, so the loop runs n - 1 times.',
      LoopForm.compare => 'i < 4 stops before 4 (0, 1, 2, 3 = 4 rounds). '
          'i <= 4 also runs when i is 4 (5 rounds).',
    },
    lesson: switch (form) {
      LoopForm.count => 'A loop repeats its body. Each round built one block, so the number of rounds '
          'is the number of blocks.',
      LoopForm.fromOne => 'Watch where a loop starts! Starting at 1 instead of 0 means one round fewer. '
          'Off-by-one mistakes like this are the most common loop bug.',
      LoopForm.compare => '< and <= look alike but differ by one round. Checking the stop condition '
          'carefully avoids off-by-one bugs.',
    },
    runner: (choice) {
      final steps = <TraceStep>[];
      var built = 0;
      void build(int bodyLine) {
        built++;
        steps.add(TraceStep(bodyLine, note: 'block $built', effect: StepEffect.block, value: built));
      }

      String how;
      switch (form) {
        case LoopForm.count:
          final n = _int(choice);
          for (var i = 0; i < n && i < 12; i++) {
            steps.add(TraceStep(0, note: 'i = $i'));
            build(1);
          }
          steps.add(TraceStep(0, note: s.isPython ? 'range($n) is done' : 'i = $n: $n < $n is false, stop'));
          how = 'The loop ran ${_plural(n, 'time')} and';
        case LoopForm.fromOne:
          final n = _int(choice);
          for (var i = 1; i < n && i < 12; i++) {
            steps.add(TraceStep(0, note: 'i = $i'));
            build(1);
          }
          steps.add(TraceStep(0, note: s.isPython ? 'range(1, $n) is done' : 'i = $n: $n < $n is false, stop'));
          how = s.isPython ? 'range(1, $n) counts 1 to ${n - 1}, so the loop' : 'Starting at 1, the loop';
        case LoopForm.compare:
          bool test(int i) => switch (choice) {
                '<' => i < 4,
                '<=' => i <= 4,
                _ => i > 4,
              };
          final loopLine = pythonCompare ? 1 : 0;
          final bodyLine = loopLine + 1;
          if (pythonCompare) steps.add(const TraceStep(0, note: 'i = 0'));
          var i = 0;
          while (test(i) && i < 12) {
            steps.add(TraceStep(loopLine, note: '$i $choice 4 is true'));
            build(bodyLine);
            if (pythonCompare) steps.add(TraceStep(3, note: 'i = ${i + 1}'));
            i++;
          }
          steps.add(TraceStep(loopLine,
              note: i == 0 ? '0 $choice 4 is false - the loop never runs' : '$i $choice 4 is false, stop'));
          how = 'With i $choice 4 the loop ran ${_plural(built, 'time')} and';
      }
      return BuildRun(
        steps: steps,
        outcome: _gapOutcome(built, gap),
        amount: built,
        message: _gapMessage(built, gap, how),
      );
    },
  );
}

/// Build stairs with a while loop: teaches while, conditions and counters.
BuildChallenge stairsChallenge({
  required String id,
  required Lang lang,
  required int height,
  required int initial,
}) {
  final s = LangSyntax(lang);
  final v = s.name('steps');
  final lines = [
    s.declare('steps', '0'),
    s.whileLoop('$v < $blank'),
    '${LangSyntax.indent}${s.call('build_step')}',
    '${LangSyntax.indent}${s.increment('steps')}',
    ...s.close,
  ];
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.stairs,
    size: height,
    goal: 'The ledge is $height blocks high. Every round of the while loop adds one step. '
        'Build stairs that reach exactly the top.',
    lines: lines,
    options: [for (var n = 1; n <= 6; n++) '$n'],
    initial: initial,
    hint: 'The loop keeps going while $v < ?. It stops when $v reaches ?, '
        'so ? is the number of steps.',
    lesson: 'A while loop repeats as long as its condition is true. $v counted the steps, '
        'and the loop stopped when the condition became false.',
    runner: (choice) {
      final n = _int(choice);
      final steps = <TraceStep>[const TraceStep(0, note: 'steps = 0')];
      var built = 0;
      while (built < n && built < 12) {
        steps
          ..add(TraceStep(1, note: '$built < $n is true'))
          ..add(TraceStep(2, note: 'step ${built + 1}', effect: StepEffect.step, value: built + 1))
          ..add(TraceStep(3, note: '$v = ${built + 1}'));
        built++;
      }
      steps.add(TraceStep(1, note: '$built < $n is false, stop'));
      final outcome = built == height
          ? BuildOutcome.cross
          : (built < height ? BuildOutcome.short : BuildOutcome.trip);
      return BuildRun(
        steps: steps,
        outcome: outcome,
        amount: built,
        message: switch (outcome) {
          BuildOutcome.cross => 'The loop ran ${_plural(built, 'time')} and built ${_plural(built, 'step')} - '
              'right up to the ledge!',
          BuildOutcome.short => 'The loop stopped after ${_plural(built, 'step')}, but the ledge is '
              '$height high. The stairs do not reach the top.',
          _ => 'The loop built ${_plural(built, 'step')}, but the ledge is only $height high. '
              'The extra steps stick up above the ledge and Byte tripped.',
        },
      );
    },
  );
}

/// Pay a toll by adding coins in a loop: teaches accumulating a total.
BuildChallenge tollChallenge({
  required String id,
  required Lang lang,
  required int toll,
  required int initial,
}) {
  const rounds = 4;
  final s = LangSyntax(lang);
  final v = s.name('coins');
  final lines = [
    s.declare('coins', '0'),
    s.forCount('$rounds'),
    '${LangSyntax.indent}${s.assign('coins', '$v + $blank')}',
    ...s.close,
    s.call('pay', v),
  ];
  final payLine = lines.length - 1;
  return BuildChallenge(
    id: id,
    lang: lang,
    obstacle: Obstacle.toll,
    size: toll,
    goal: 'The troll wants exactly $toll coins. The loop runs $rounds times. '
        'How many coins should each round add?',
    lines: lines,
    options: [for (var n = 1; n <= 5; n++) '$n'],
    initial: initial,
    hint: '$rounds rounds x ? coins = $toll coins. What times $rounds is $toll?',
    lesson: 'This is a running total: $v starts at 0 and each round adds to it. '
        'Totals like this are everywhere - scores, prices, counters.',
    runner: (choice) {
      final n = _int(choice);
      final steps = <TraceStep>[const TraceStep(0, note: 'coins = 0')];
      var total = 0;
      for (var i = 0; i < rounds; i++) {
        steps.add(TraceStep(1, note: 'i = $i'));
        steps.add(TraceStep(2, note: '$v = $total + $n = ${total + n}', effect: StepEffect.coins, value: total + n));
        total += n;
      }
      steps.add(TraceStep(1, note: s.isPython ? 'range($rounds) is done' : 'i = $rounds: $rounds < $rounds is false'));
      steps.add(TraceStep(payLine, note: 'pays $total', effect: StepEffect.pay, value: total));
      final ok = total == toll;
      return BuildRun(
        steps: steps,
        outcome: ok ? BuildOutcome.cross : BuildOutcome.blocked,
        amount: total,
        message: ok
            ? '$rounds rounds x $n coins = $total coins. Exact change - the troll lifts the barrier!'
            : '$rounds rounds x $n coins = $total coins, but the toll is $toll. '
                'The troll only takes the exact amount.',
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Playing a level
// ---------------------------------------------------------------------------

/// Rules for one World Builder level: hearts, retries and scoring.
class BuilderSession {
  BuilderSession(this.challenges, {this.maxLives = 3})
      : assert(challenges.isNotEmpty, 'A level needs at least one challenge') {
    lives = maxLives;
    choice = challenges.first.initial;
  }

  final List<BuildChallenge> challenges;
  final int maxLives;

  late int lives;
  int index = 0;

  /// The option currently in the blank.
  late int choice;

  int mistakes = 0;
  int solved = 0;
  int solvedFirstTry = 0;
  bool _missedCurrent = false;

  /// Challenges the player got wrong at least once, for the review.
  final List<BuildChallenge> missed = [];

  /// The last run of the current challenge, if any.
  BuildRun? lastRun;

  BuildChallenge get current => challenges[index];
  bool get currentSolved => lastRun?.success ?? false;
  bool get finished => solved >= challenges.length;
  bool get won => finished && lives > 0;
  bool get isOver => lives <= 0 || finished;
  bool get isLast => index == challenges.length - 1;

  /// Puts option [optionIndex] in the blank.
  void select(int optionIndex) {
    if (isOver || currentSolved) return;
    RangeError.checkValidIndex(optionIndex, current.options, 'optionIndex');
    choice = optionIndex;
    lastRun = null;
  }

  /// Runs the code. A failed run costs one heart.
  BuildRun run() {
    if (isOver) throw StateError('The level is already over.');
    if (currentSolved) throw StateError('This challenge is already solved.');
    final result = current.run(choice);
    lastRun = result;
    if (result.success) {
      solved++;
      if (!_missedCurrent) solvedFirstTry++;
    } else {
      lives--;
      mistakes++;
      if (!_missedCurrent) {
        _missedCurrent = true;
        missed.add(current);
      }
    }
    return result;
  }

  /// After a failed run: clear it so the player can change the code.
  void retry() {
    if (lastRun != null && !lastRun!.success) lastRun = null;
  }

  /// Moves on after the current challenge is solved.
  void next() {
    if (!currentSolved || isLast) return;
    index++;
    choice = current.initial;
    lastRun = null;
    _missedCurrent = false;
  }
}
