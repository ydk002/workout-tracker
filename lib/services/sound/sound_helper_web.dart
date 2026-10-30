import 'dart:js_interop';
import 'package:web/web.dart' as web;

void playWebTimerChime() {
  // 1. Trigger vibration on mobile browsers if supported
  try {
    web.window.navigator.vibrate([250.toJS, 100.toJS, 250.toJS].toJS);
  } catch (_) {}

  // 2. Synthesize 3-beep gym timer sound using Web Audio API
  try {
    final ctx = web.AudioContext();
    final now = ctx.currentTime;

    final offsets = [0.0, 0.22, 0.44];
    final freqs = [880.0, 880.0, 1174.66]; // A5, A5, D6

    for (int i = 0; i < offsets.length; i++) {
      final start = now + offsets[i];
      final duration = i == 2 ? 0.35 : 0.15;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freqs[i], start);

      gain.gain.setValueAtTime(0.25, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(start);
      osc.stop(start + duration);
    }
  } catch (_) {}
}
