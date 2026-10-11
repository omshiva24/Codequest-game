import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// All effects here are decoration: they are hidden from screen readers and
/// switched off when the player (or their device) asks for reduced motion.
bool _still(BuildContext context) => MediaQuery.disableAnimationsOf(context);

// ---------------------------------------------------------------- confetti

/// Bursts confetti every time [trigger] changes to a new positive value.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.trigger, this.origin = const Alignment(0, -0.3)});

  final int trigger;
  final Alignment origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Bit {
  _Bit(math.Random r)
      : angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.4,
        speed = 380 + r.nextDouble() * 520,
        spin = (r.nextDouble() - 0.5) * 18,
        size = 6 + r.nextDouble() * 8,
        color = _colors[r.nextInt(_colors.length)],
        round = r.nextBool();

  static const _colors = [
    Color(0xFFFFC93C),
    Color(0xFF3DDC84),
    Color(0xFF5BC0FF),
    Color(0xFFFF6B7F),
    Color(0xFFC3A0FF),
    Color(0xFFFFF4D6),
  ];

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final Color color;
  final bool round;
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  List<_Bit> _bits = const [];
  int _seed = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFire(widget.trigger));
  }

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _maybeFire(widget.trigger);
  }

  void _maybeFire(int trigger) {
    if (!mounted || trigger <= 0 || _still(context)) return;
    final r = math.Random(_seed++);
    setState(() => _bits = List.generate(90, (_) => _Bit(r)));
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => (_c.isAnimating && _bits.isNotEmpty)
                ? CustomPaint(
                    painter: _ConfettiPainter(_bits, _c.value * 2.2, widget.origin),
                    child: const SizedBox.expand(),
                  )
                : const SizedBox.expand(),
          ),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.time, this.origin);

  final List<_Bit> bits;
  final double time;
  final Alignment origin;

  @override
  void paint(Canvas canvas, Size size) {
    final o = origin.alongSize(size);
    final paint = Paint();
    final fade = (1 - (time - 1.4) / 0.8).clamp(0.0, 1.0);
    for (final b in bits) {
      final x = o.dx + math.cos(b.angle) * b.speed * time;
      final y = o.dy + math.sin(b.angle) * b.speed * time + 0.5 * 900 * time * time;
      paint.color = b.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(b.spin * time);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2.4, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.5), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ------------------------------------------------------------------- shake

/// Shakes its child sideways whenever [trigger] changes (e.g. a wrong answer).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child, this.strength = 12});

  final int trigger;
  final Widget child;
  final double strength;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0 && !_still(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = _c.value;
          final dx = (v == 0 || v == 1) ? 0.0 : math.sin(v * math.pi * 8) * widget.strength * (1 - v);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: widget.child,
      );
}

// ------------------------------------------------------------------- popup

/// Text such as "+10" that floats up and fades out each time [trigger] changes.
class FloatingPopup extends StatefulWidget {
  const FloatingPopup({super.key, required this.trigger, required this.text, this.color});

  final int trigger;
  final String text;
  final Color? color;

  @override
  State<FloatingPopup> createState() => _FloatingPopupState();
}

class _FloatingPopupState extends State<FloatingPopup> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didUpdateWidget(FloatingPopup old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0 && !_still(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            if (!_c.isAnimating) return const SizedBox.shrink();
            final v = _c.value;
            return Transform.translate(
              offset: Offset(0, -70 * Curves.easeOut.transform(v)),
              child: Opacity(
                opacity: (1 - v).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + 0.5 * Curves.elasticOut.transform(math.min(1, v * 2.5)),
                  child: _Outlined(widget.text, color: widget.color ?? g.gold, ink: g.ink),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Outlined extends StatelessWidget {
  const _Outlined(this.text, {required this.color, required this.ink});

  final String text;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Text(
            text,
            style: displayStyle(34).copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 6
                ..strokeJoin = StrokeJoin.round
                ..color = ink,
            ),
          ),
          Text(text, style: displayStyle(34, color: color)),
        ],
      );
}

// ------------------------------------------------------------------ pop in

/// Pops a child in with a springy scale after [delay].
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.delay + const Duration(milliseconds: 650),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay.inMilliseconds + 650),
      1,
      curve: Curves.elasticOut,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (_still(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      );
}

// --------------------------------------------------------------- count up

/// Counts a number up from 0 (instantly when motion is reduced).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.prefix = ''});

  final int value;
  final TextStyle style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return Text('$prefix$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix${v.round()}', style: style),
    );
  }
}

// -------------------------------------------------------------- typewriter

/// Types text out letter by letter, like an RPG dialogue box. Screen readers
/// get the whole text at once.
class Typewriter extends StatelessWidget {
  const Typewriter(this.text, {super.key, required this.style, this.charMs = 22});

  final String text;
  final TextStyle style;
  final int charMs;

  @override
  Widget build(BuildContext context) {
    if (_still(context)) return Text(text, style: style);
    return Semantics(
      label: text,
      liveRegion: true,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<int>(
          key: ValueKey(text),
          tween: IntTween(begin: 0, end: text.length),
          duration: Duration(milliseconds: charMs * text.length),
          builder: (context, n, _) => Stack(
            children: [
              // Invisible full text keeps the box from jumping in size.
              Opacity(opacity: 0, child: Text(text, style: style)),
              Text(text.substring(0, n), style: style),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- pulse

/// Expanding rings that draw the eye to the next level on the map.
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              return SizedBox.square(
                dimension: widget.size * 1.7,
                child: Center(
                  child: Container(
                    width: widget.size * (1 + 0.6 * v),
                    height: widget.size * (1 + 0.6 * v),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: _c.isAnimating ? (1 - v) : 0.8),
                        width: 5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}
