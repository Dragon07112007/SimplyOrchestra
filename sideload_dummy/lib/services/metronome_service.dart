import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';

class MetronomeBeat {
  const MetronomeBeat({
    required this.beat,
    required this.beatsPerMeasure,
    required this.at,
  });

  final int beat;
  final int beatsPerMeasure;
  final DateTime at;

  bool get isDownbeat => beat == 1;
}

class MetronomeService {
  Timer? _timer;
  DateTime? _startTime;
  Duration _interval = const Duration(milliseconds: 500);
  int _beatsPerMeasure = 4;
  int _beatIndex = 0;

  bool get isRunning => _timer?.isActive ?? false;

  void start({
    required int bpm,
    required int beatsPerMeasure,
    required void Function(MetronomeBeat beat) onBeat,
  }) {
    stop();
    _beatsPerMeasure = beatsPerMeasure;
    _interval = Duration(milliseconds: (60000 / bpm).round());
    _startTime = DateTime.now();
    _beatIndex = 0;

    _emitBeat(onBeat);
    _timer = Timer.periodic(_interval, (_) => _emitBeat(onBeat));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _beatIndex = 0;
  }

  int? offsetFromNearestBeat(DateTime detectedAt) {
    final startTime = _startTime;
    if (startTime == null) {
      return null;
    }

    final elapsedMs = detectedAt.difference(startTime).inMilliseconds;
    final intervalMs = _interval.inMilliseconds;
    final nearestBeat = math.max(0, (elapsedMs / intervalMs).round());
    final expectedMs = nearestBeat * intervalMs;

    return elapsedMs - expectedMs;
  }

  void _emitBeat(void Function(MetronomeBeat beat) onBeat) {
    final beat = (_beatIndex % _beatsPerMeasure) + 1;
    final event = MetronomeBeat(
      beat: beat,
      beatsPerMeasure: _beatsPerMeasure,
      at: DateTime.now(),
    );

    SystemSound.play(SystemSoundType.click);
    if (event.isDownbeat) {
      HapticFeedback.mediumImpact();
    }

    onBeat(event);
    _beatIndex++;
  }
}
