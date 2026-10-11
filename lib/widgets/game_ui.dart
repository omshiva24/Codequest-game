import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'scenes.dart';

/// Colour of a [GameButton].
enum ButtonTone { gold, mint, sky, coral, lilac, parchment }

(Color face, Color lip) toneColors(ButtonTone tone, GameColors g) => switch (tone) {
      ButtonTone.gold => (g.gold, g.goldLip),
      ButtonTone.mint => (g.mint, g.mintLip),
      ButtonTone.sky => (g.sky, g.skyLip),
      ButtonTone.coral => (g.coral, g.coralLip),
      ButtonTone.lilac => (g.lilac, g.lilacLip),
      ButtonTone.parchment => (g.parchment, g.parchmentShade),
    };

enum GameButtonSize {
  small(48, 17, 14, 5),
  medium(56, 20, 20, 6),
  large(66, 26, 28, 7);

  const GameButtonSize(this.minHeight, this.fontSize, this.hPad, this.lip);

  final double minHeight;
  final double fontSize;
  final double hPad;
  final double lip;
}

/// A chunky, toy-like 3D button: bright face, ink outline and a hard "lip"
/// underneath that squishes down when pressed.
///
/// Works with touch, mouse and keyboard (Tab to focus, Enter/Space to press),
/// and announces itself to screen readers as a button.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    required this.onPressed,
    this.tone = ButtonTone.gold,
    this.size = GameButtonSize.medium,
    this.expand = false,
    this.circle = false,
    this.semanticLabel,
    this.tooltip,
    this.autofocus = false,
    this.focusNode,
    this.alignment = MainAxisAlignment.center,
  }) : assert(label != null || child != null || icon != null);

  final String? label;
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final GameButtonSize size;
  final bool expand;
  final bool circle;
  final String? semanticLabel;
  final String? tooltip;
  final bool autofocus;
  final FocusNode? focusNode;
  final MainAxisAlignment alignment;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;

  void _activate() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
    widget.onPressed!();
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final size = widget.size;
    var (face, lip) = toneColors(widget.tone, g);
    if (!_enabled) {
      face = g.disabled;
      lip = Color.lerp(g.disabled, g.ink, 0.35)!;
    } else if (_hovered && !_pressed) {
      face = Color.lerp(face, Colors.white, 0.12)!;
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sink = _pressed ? size.lip - 2 : 0.0;
    final radius = widget.circle
        ? BorderRadius.circular(999)
        : BorderRadius.circular(size == GameButtonSize.large ? 22 : 18);
    final ow = g.outlineWidth;

    final label = widget.label;
    Widget content = widget.child ??
        Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: widget.alignment,
          children: [
            if (widget.icon != null)
              Icon(widget.icon, color: g.ink, size: size.fontSize + (label == null ? 8 : 4)),
            if (widget.icon != null && label != null) const SizedBox(width: 8),
            if (label != null)
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: displayStyle(size.fontSize, color: g.ink),
                ),
              ),
          ],
        );

    content = DefaultTextStyle.merge(
      style: TextStyle(color: g.ink),
      child: IconTheme.merge(data: IconThemeData(color: g.ink), child: content),
    );

    Widget button = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 70),
      transform: Matrix4.translationValues(0, sink, 0),
      constraints: BoxConstraints(
        minHeight: size.minHeight,
        minWidth: widget.circle ? size.minHeight : 48,
      ),
      padding: widget.circle
          ? const EdgeInsets.all(6)
          : EdgeInsets.symmetric(horizontal: size.hPad, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: g.ink, width: ow),
        gradient: g.highContrast
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(face, Colors.white, 0.28)!, face],
                stops: const [0, 0.55],
              ),
        color: g.highContrast ? face : null,
        boxShadow: [
          if (_focused) BoxShadow(color: g.focus, spreadRadius: ow + 3),
          BoxShadow(color: g.ink, offset: Offset(0, size.lip - sink), spreadRadius: ow * 0.5),
          BoxShadow(color: lip, offset: Offset(0, size.lip - sink - ow * 0.5)),
        ],
      ),
      alignment: widget.expand ? Alignment.center : null,
      child: content,
    );

    if (widget.circle) {
      button = SizedBox.square(dimension: size.minHeight, child: button);
    }

    button = Padding(
      padding: EdgeInsets.only(bottom: size.lip),
      child: FocusableActionDetector(
        enabled: _enabled,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _activate();
            return null;
          }),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: () => _setPressed(false),
          onTap: _enabled ? _activate : null,
          child: button,
        ),
      ),
    );

    button = Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      focusable: _enabled,
      label: widget.semanticLabel ?? widget.label ?? widget.tooltip,
      excludeSemantics: widget.semanticLabel != null || widget.label != null || widget.child == null,
      onTap: _enabled ? _activate : null,
      child: button,
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip, excludeFromSemantics: true, child: button);
    }
    return button;
  }
}

/// Round icon-only [GameButton] (back, settings, trophies...).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = ButtonTone.parchment,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) => GameButton(
        icon: icon,
        tooltip: tooltip,
        semanticLabel: tooltip,
        onPressed: onPressed,
        tone: tone,
        circle: true,
        size: GameButtonSize.medium,
      );
}

/// Big game-title text with an ink outline and a drop shadow.
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    this.size = 28,
    this.color,
    this.strokeColor,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.header = false,
  });

  final String text;
  final double size;
  final Color? color;
  final Color? strokeColor;
  final TextAlign textAlign;
  final int? maxLines;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final stroke = strokeColor ?? g.ink;
    final strokeWidth = math.max(3.0, size / 6);
    final base = displayStyle(size);
    return Semantics(
      header: header,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: Text(
              text,
              textAlign: textAlign,
              maxLines: maxLines,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth
                  ..strokeJoin = StrokeJoin.round
                  ..color = stroke,
                shadows: [Shadow(color: stroke, offset: Offset(0, size * 0.09))],
              ),
            ),
          ),
          Text(
            text,
            textAlign: textAlign,
            maxLines: maxLines,
            style: base.copyWith(color: color ?? g.onNight),
          ),
        ],
      ),
    );
  }
}

/// A cream "parchment" card with an ink outline - the place for reading.
class ParchmentPanel extends StatelessWidget {
  const ParchmentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.radius = 22,
    this.lip = 6,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final double lip;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: lip),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? g.parchment,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor ?? g.ink, width: g.outlineWidth),
          boxShadow: [BoxShadow(color: g.ink, offset: Offset(0, lip))],
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: g.parchmentText, fontSize: 16, height: 1.45),
          child: IconTheme.merge(data: IconThemeData(color: g.ink), child: child),
        ),
      ),
    );
  }
}

/// Coloured title strip used at the top of panels.
class PanelBanner extends StatelessWidget {
  const PanelBanner({super.key, required this.text, this.tone = ButtonTone.gold, this.icon});

  final String text;
  final ButtonTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final (face, _) = toneColors(tone, g);
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: g.ink, width: g.outlineWidth * 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: g.ink, size: 22), const SizedBox(width: 6)],
            Flexible(child: Text(text, style: displayStyle(19, color: g.ink))),
          ],
        ),
      ),
    );
  }
}

/// Dark pill used in the game HUD (coins, streak, combo...).
class HudPill extends StatelessWidget {
  const HudPill({
    super.key,
    required this.leading,
    required this.text,
    required this.semanticLabel,
    this.highlight,
  });

  final Widget leading;
  final String text;
  final String semanticLabel;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
          decoration: BoxDecoration(
            color: g.highContrast ? Colors.black : g.ink.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlight ?? (g.highContrast ? Colors.white : g.ink),
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 28, height: 28, child: Center(child: leading)),
              const SizedBox(width: 4),
              Text(text, style: displayStyle(18, color: g.onNight)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gold coin drawn with shapes (no image needed).
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: g.gold,
          border: Border.all(color: g.goldLip, width: size / 9),
        ),
        child: Text('C', style: displayStyle(size * 0.55, color: g.goldLip, height: 1)),
      ),
    );
  }
}

/// XP progress bar.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.progress, this.height = 14});

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    return Semantics(
      label: 'Experience to next level',
      value: '${(progress * 100).round()} percent',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: g.ink,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: g.highContrast ? Colors.white : g.ink, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(g.gold, Colors.white, 0.45)!, g.gold],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Speech bubble with a tail on the left, for Byte the owl.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child, this.color, this.tailLeft = true});

  final Widget child;
  final Color? color;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final fill = color ?? g.parchment;
    return CustomPaint(
      painter: _TailPainter(fill: fill, ink: g.ink, left: tailLeft, width: g.outlineWidth),
      child: Padding(
        padding: EdgeInsets.only(left: tailLeft ? 12 : 0, right: tailLeft ? 0 : 12),
        child: ParchmentPanel(
          color: fill,
          lip: 4,
          radius: 20,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: child,
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter({required this.fill, required this.ink, required this.left, required this.width});

  final Color fill;
  final Color ink;
  final bool left;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    const y = 26.0;
    final path = left
        ? (Path()
          ..moveTo(14, y - 9)
          ..lineTo(0, y + 2)
          ..lineTo(14, y + 9))
        : (Path()
          ..moveTo(size.width - 14, y - 9)
          ..lineTo(size.width, y + 2)
          ..lineTo(size.width - 14, y + 9));
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round,
      )
      ..drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.fill != fill || old.ink != ink;
}

/// Gentle floating motion for characters. Still when motion is reduced.
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.amplitude = 6, this.period = 2400, this.phase = 0});

  final Widget child;
  final double amplitude;
  final int period;
  final double phase;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.period));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, math.sin((_c.value + widget.phase) * 2 * math.pi) * widget.amplitude),
          child: child,
        ),
        child: widget.child,
      );
}

/// Byte the owl, the game's mascot and tutor.
class ByteAvatar extends StatelessWidget {
  const ByteAvatar({super.key, this.size = 72, this.bob = true});

  final double size;
  final bool bob;

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final avatar = ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: g.sky,
          border: Border.all(color: g.ink, width: g.outlineWidth),
          boxShadow: [BoxShadow(color: g.ink, offset: const Offset(0, 4))],
        ),
        child: Text('🦉', style: TextStyle(fontSize: size * 0.58, height: 1.15)),
      ),
    );
    return bob ? Bob(child: avatar) : avatar;
  }
}

/// Top bar shown over the world scenes: round back button, outlined title,
/// optional actions on the right.
class GameTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GameTopBar({super.key, required this.title, this.actions = const [], this.showBack = true});

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (ModalRoute.of(context)?.canPop ?? false);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              if (canPop) ...[
                RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: OutlinedText(title, size: 26, header: true, maxLines: 1),
                  ),
                ),
              ),
              for (final a in actions) ...[const SizedBox(width: 8), a],
            ],
          ),
        ),
      ),
    );
  }
}

/// A screen with an animated world scene behind a transparent game top bar.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.scene,
    required this.title,
    required this.body,
    this.actions = const [],
    this.showBack = true,
    this.bottom,
  });

  final SceneKind scene;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: SceneBackground(kind: scene)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GameTopBar(title: title, actions: actions, showBack: showBack),
          body: body,
          bottomNavigationBar: bottom,
        ),
      ],
    );
  }
}

/// Makes any child a big game "card button": press squish, keyboard focus
/// ring, Enter/Space activation and one clear screen-reader label.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.radius = 24,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final double radius;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;

  void _tap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final g = GameColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: _tap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _tap();
            return null;
          }),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _tap,
          child: AnimatedScale(
            scale: _pressed && !reduceMotion ? 0.96 : 1,
            duration: const Duration(milliseconds: 90),
            child: Container(
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.radius + 4),
                      border: Border.all(color: g.focus, width: 4),
                    )
                  : null,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
