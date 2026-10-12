// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

// Web version: plays tones with the browser's Web Audio API.
import 'package:web/web.dart' as web;

import 'sound_tones.dart';

web.AudioContext? _context;

void playTones(List<Tone> tones) {
  try {
    // Browsers only allow sound after the player has tapped something, and
    // every sound here is played in response to a tap or a game event.
    final ctx = _context ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
    var start = ctx.currentTime + 0.02;
    for (final tone in tones) {
      final osc = ctx.createOscillator()..type = tone.wave;
      osc.frequency.setValueAtTime(tone.freq, start);
      final slide = tone.slideTo;
      if (slide != null) {
        osc.frequency.exponentialRampToValueAtTime(slide, start + tone.duration);
      }
      final gain = ctx.createGain();
      gain.gain
        ..setValueAtTime(tone.volume, start)
        ..exponentialRampToValueAtTime(0.0001, start + tone.duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc
        ..start(start)
        ..stop(start + tone.duration + 0.02);
      start += tone.gap ?? tone.duration;
    }
  } catch (_) {
    // Sound is a bonus. If the browser blocks or lacks Web Audio, stay quiet.
  }
}
