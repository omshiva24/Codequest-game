/// The "notes" behind every sound effect. Sounds are made in code by a tiny
/// 8-bit style synthesizer, so the game ships no audio files at all.
library;

/// Every sound effect in the game.
enum Sfx {
  tap,
  correct,
  wrong,
  coin,
  hit,
  powerUp,
  star,
  victory,
  defeat,
  levelUp,
  badge,
}

/// One beep: a frequency (Hz) played for [duration] seconds.
class Tone {
  const Tone(
    this.freq,
    this.duration, {
    this.wave = 'square',
    this.slideTo,
    this.volume = 0.06,
    this.gap,
  });

  final double freq;
  final double duration;

  /// Oscillator shape: 'square', 'triangle', 'sawtooth' or 'sine'.
  final String wave;

  /// If set, the pitch slides to this frequency (for whooshes and "boing"s).
  final double? slideTo;

  /// Loudness from 0 to 1. Kept low so effects never startle anyone.
  final double volume;

  /// Seconds until the next tone starts (defaults to [duration]).
  final double? gap;
}

// Musical notes (Hz) used below.
const double _c4 = 261.63, _e4 = 329.63, _g4 = 392.0;
const double _c5 = 523.25, _e5 = 659.25, _g5 = 783.99;
const double _a5 = 880.0, _b5 = 987.77;
const double _c6 = 1046.5, _d6 = 1174.66, _e6 = 1318.51, _g6 = 1567.98;

const Map<Sfx, List<Tone>> sfxTones = {
  Sfx.tap: [Tone(_a5, 0.035, volume: 0.03)],
  Sfx.correct: [
    Tone(_g5, 0.07),
    Tone(_c6, 0.14),
  ],
  Sfx.wrong: [Tone(220, 0.28, wave: 'sawtooth', slideTo: 110, volume: 0.05)],
  // The classic "collect a coin" jump from B to E.
  Sfx.coin: [
    Tone(_b5, 0.07),
    Tone(_e6, 0.26),
  ],
  Sfx.hit: [
    Tone(180, 0.12, slideTo: 60, volume: 0.08),
    Tone(_c6, 0.06, wave: 'triangle', volume: 0.05),
  ],
  Sfx.powerUp: [
    Tone(_c5, 0.05, wave: 'triangle', volume: 0.07),
    Tone(_e5, 0.05, wave: 'triangle', volume: 0.07),
    Tone(_g5, 0.05, wave: 'triangle', volume: 0.07),
    Tone(_c6, 0.12, wave: 'triangle', volume: 0.07),
  ],
  Sfx.star: [Tone(_g6, 0.14, wave: 'triangle', volume: 0.07)],
  Sfx.victory: [
    Tone(_c5, 0.1),
    Tone(_e5, 0.1),
    Tone(_g5, 0.1),
    Tone(_c6, 0.18, gap: 0.22),
    Tone(_g5, 0.1),
    Tone(_c6, 0.4),
  ],
  Sfx.defeat: [
    Tone(_g4, 0.18, wave: 'triangle', volume: 0.07),
    Tone(_e4, 0.18, wave: 'triangle', volume: 0.07),
    Tone(_c4, 0.45, wave: 'triangle', slideTo: 200, volume: 0.07),
  ],
  Sfx.levelUp: [
    Tone(_c5, 0.06),
    Tone(_e5, 0.06),
    Tone(_g5, 0.06),
    Tone(_c6, 0.06),
    Tone(_e6, 0.06),
    Tone(_g6, 0.22),
  ],
  Sfx.badge: [
    Tone(_a5, 0.08, wave: 'triangle', volume: 0.07),
    Tone(_d6, 0.08, wave: 'triangle', volume: 0.07),
    Tone(_g6, 0.24, wave: 'triangle', volume: 0.07),
  ],
};
