import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sound/sound_helper_stub.dart'
    if (dart.library.js_interop) 'sound/sound_helper_web.dart';

class SoundService {
  static void playTimerBeep() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    if (kIsWeb) {
      playWebTimerChime();
    } else {
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
