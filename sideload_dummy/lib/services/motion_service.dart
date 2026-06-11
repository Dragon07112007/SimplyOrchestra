import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class MotionService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastDetection;
  double? _previousMagnitude;

  bool get isListening => _subscription != null;

  void start(void Function(DateTime detectedAt) onBeatDetected) {
    stop();

    _subscription =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 16),
        ).listen(
          (event) {
            final detectedAt = DateTime.now();
            final magnitude = math.sqrt(
              event.x * event.x + event.y * event.y + event.z * event.z,
            );
            final previous = _previousMagnitude ?? magnitude;
            final impulse = (magnitude - previous).abs();

            _previousMagnitude = magnitude;

            final lastDetection = _lastDetection;
            if (lastDetection != null &&
                detectedAt.difference(lastDetection).inMilliseconds < 250) {
              return;
            }

            // A conducting beat is approximated as a sharp acceleration impulse.
            // This stays orientation-tolerant for iPhone sideloading and desktop tests.
            if (magnitude >= 16 || impulse >= 7.5) {
              _lastDetection = detectedAt;
              onBeatDetected(detectedAt);
            }
          },
          onError: (_) {
            stop();
          },
          cancelOnError: true,
        );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _lastDetection = null;
    _previousMagnitude = null;
  }
}
