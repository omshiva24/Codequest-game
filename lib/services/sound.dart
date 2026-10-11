import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sound_stub.dart' if (dart.library.js_interop) 'sound_web.dart' as synth;
import 'sound_tones.dart';

export 'sound_tones.dart' show Sfx;

/// Plays game sound effects and phone vibrations.
///
/// Sound never carries information on its own - every event also has text,
/// icons and colour - so turning it off (Settings) loses nothing.
class SoundFx {
  SoundFx._();

  /// Set from the player's "Sound effects" setting.
  static bool enabled = true;

  static void play(Sfx sfx) {
    _vibrate(sfx);
    if (!enabled) return;
    final tones = sfxTones[sfx];
    if (tones != null) synth.playTones(tones);
  }

  /// Plays several effects one after another, e.g. victory then level up.
  static void playSequence(List<(Sfx, Duration)> steps) {
    if (!kIsWeb) {
      // No synthesizer here: one vibration is enough (and no timers are left
      // running, which keeps widget tests clean).
      if (steps.isNotEmpty) play(steps.first.$1);
      return;
    }
    for (final (sfx, delay) in steps) {
      if (delay == Duration.zero) {
        play(sfx);
      } else {
        Timer(delay, () => play(sfx));
      }
    }
  }

  static void _vibrate(Sfx sfx) {
    if (kIsWeb) return;
    final Future<void> Function() haptic = switch (sfx) {
      Sfx.tap => HapticFeedback.selectionClick,
      Sfx.correct || Sfx.coin || Sfx.star || Sfx.powerUp => HapticFeedback.lightImpact,
      Sfx.hit || Sfx.victory || Sfx.levelUp || Sfx.badge => HapticFeedback.mediumImpact,
      Sfx.wrong || Sfx.defeat => HapticFeedback.heavyImpact,
    };
    unawaited(haptic());
  }
}
