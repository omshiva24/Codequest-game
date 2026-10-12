// CodeQuest - Copyright (c) 2026 P Om Shiva (M.Tech CSE, Pondicherry University).
// All rights reserved. Original work - do not copy or reuse without written permission. See LICENSE.

import 'package:codequest/services/sound.dart';
import 'package:codequest/services/sound_tones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Vibration calls go through Flutter's platform channels.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every sound effect has gentle, valid tones', () {
    const waves = {'square', 'triangle', 'sawtooth', 'sine'};
    for (final sfx in Sfx.values) {
      final tones = sfxTones[sfx];
      expect(tones, isNotNull, reason: '$sfx has no tones');
      expect(tones, isNotEmpty);
      var total = 0.0;
      for (final t in tones!) {
        expect(t.freq, inInclusiveRange(40, 4000), reason: '$sfx frequency');
        expect(t.duration, inInclusiveRange(0.02, 1.0), reason: '$sfx duration');
        expect(t.volume, inInclusiveRange(0.01, 0.1), reason: '$sfx must stay quiet');
        expect(waves, contains(t.wave), reason: '$sfx wave');
        if (t.slideTo != null) expect(t.slideTo, greaterThan(0));
        total += t.gap ?? t.duration;
      }
      expect(total, lessThan(1.6), reason: '$sfx should be short');
    }
  });

  test('playing sounds is safe off the web, with sound on or off', () {
    SoundFx.enabled = true;
    for (final sfx in Sfx.values) {
      SoundFx.play(sfx);
    }
    SoundFx.enabled = false;
    SoundFx.play(Sfx.victory);
    SoundFx.playSequence([(Sfx.victory, Duration.zero), (Sfx.star, const Duration(seconds: 1))]);
    SoundFx.enabled = true;
  });
}
