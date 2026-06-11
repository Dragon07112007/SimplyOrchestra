import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/session_stats.dart';
import '../services/metronome_service.dart';
import '../services/motion_service.dart';
import '../theme/app_theme.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with SingleTickerProviderStateMixin {
  static const _sessionLength = Duration(seconds: 30);
  static const _timeSignatures = <String, int>{
    '2/4': 2,
    '3/4': 3,
    '4/4': 4,
    '6/8': 6,
  };

  final _metronome = MetronomeService();
  final _motion = MotionService();
  late final AnimationController _pulseController;

  int _bpm = 84;
  String _timeSignature = '4/4';
  int _currentBeat = 1;
  bool _isRunning = false;
  bool _isDownbeat = true;
  String _status = 'Waiting';
  SessionStats _stats = const SessionStats();
  SessionStats? _summary;
  Timer? _sessionTimer;
  Timer? _remainingTimer;
  int _remainingSeconds = _sessionLength.inSeconds;

  int get _beatsPerMeasure => _timeSignatures[_timeSignature]!;

  bool get _showSimulateBeat {
    return kDebugMode ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _remainingTimer?.cancel();
    _metronome.stop();
    _motion.stop();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleTraining() {
    if (_isRunning) {
      _stopTraining();
    } else {
      _startTraining();
    }
  }

  void _startTraining() {
    setState(() {
      _isRunning = true;
      _currentBeat = 1;
      _isDownbeat = true;
      _status = 'Waiting';
      _stats = const SessionStats();
      _summary = null;
      _remainingSeconds = _sessionLength.inSeconds;
    });

    _motion.start(_handleDetectedBeat);
    _metronome.start(
      bpm: _bpm,
      beatsPerMeasure: _beatsPerMeasure,
      onBeat: _handleMetronomeBeat,
    );

    _sessionTimer = Timer(_sessionLength, _finishSession);
    _remainingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) {
        return;
      }
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
      });
    });
  }

  void _stopTraining({bool showSummary = false}) {
    _sessionTimer?.cancel();
    _remainingTimer?.cancel();
    _metronome.stop();
    _motion.stop();

    setState(() {
      _isRunning = false;
      _status = 'Waiting';
      if (showSummary) {
        _summary = _stats;
      }
    });
  }

  void _finishSession() {
    if (!_isRunning) {
      return;
    }
    _stopTraining(showSummary: true);
  }

  void _handleMetronomeBeat(MetronomeBeat beat) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentBeat = beat.beat;
      _isDownbeat = beat.isDownbeat;
    });
    _pulseController.forward(from: 0);
  }

  void _handleDetectedBeat(DateTime detectedAt) {
    final offsetMs = _metronome.offsetFromNearestBeat(detectedAt);
    if (offsetMs == null || !_isRunning) {
      return;
    }

    setState(() {
      _stats = _stats.record(offsetMs);
      _status = _statusForOffset(offsetMs);
    });
  }

  String _statusForOffset(int offsetMs) {
    if (offsetMs.abs() <= 100) {
      return 'Good';
    }
    if (offsetMs < -100) {
      return 'Too early';
    }
    return 'Too late';
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Good' => AppTheme.good,
      'Too early' => AppTheme.warning,
      'Too late' => AppTheme.late,
      _ => AppTheme.textMuted,
    };
  }

  void _changeBpm(int delta) {
    final next = (_bpm + delta).clamp(40, 220);
    setState(() {
      _bpm = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_status);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101827), AppTheme.background, Color(0xFF05070A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      isRunning: _isRunning,
                      remainingSeconds: _remainingSeconds,
                    ),
                    const SizedBox(height: 18),
                    _BeatCard(
                      pulse: _pulseController,
                      beat: _currentBeat,
                      beatsPerMeasure: _beatsPerMeasure,
                      isDownbeat: _isDownbeat,
                      status: _status,
                      statusColor: statusColor,
                    ),
                    const SizedBox(height: 16),
                    _BpmCard(
                      bpm: _bpm,
                      enabled: !_isRunning,
                      onDecrease: () => _changeBpm(-1),
                      onIncrease: () => _changeBpm(1),
                      onChanged: (value) {
                        setState(() {
                          _bpm = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _SignatureCard(
                      value: _timeSignature,
                      enabled: !_isRunning,
                      options: _timeSignatures.keys.toList(),
                      onChanged: (value) {
                        setState(() {
                          _timeSignature = value;
                          _currentBeat = 1;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _toggleTraining,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isRunning
                            ? AppTheme.late
                            : AppTheme.accent,
                      ),
                      child: Text(
                        _isRunning ? 'Stop Training' : 'Start Training',
                      ),
                    ),
                    if (_showSimulateBeat) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isRunning
                            ? () => _handleDetectedBeat(DateTime.now())
                            : null,
                        child: const Text('Simulate Beat'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _LiveStats(stats: _stats),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 420),
                      switchInCurve: Curves.easeOutCubic,
                      child: _summary == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _SummaryCard(stats: _summary!),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isRunning, required this.remainingSeconds});

  final bool isRunning;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Taktstock Trainer',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Conducting timing practice',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        _Pill(text: isRunning ? '${remainingSeconds}s' : 'Ready'),
      ],
    );
  }
}

class _BeatCard extends StatelessWidget {
  const _BeatCard({
    required this.pulse,
    required this.beat,
    required this.beatsPerMeasure,
    required this.isDownbeat,
    required this.status,
    required this.statusColor,
  });

  final Animation<double> pulse;
  final int beat;
  final int beatsPerMeasure;
  final bool isDownbeat;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              final progress = Curves.easeOutCubic.transform(pulse.value);
              final pulseScale = isDownbeat ? 0.18 : 0.11;
              final scale = 1 + ((1 - progress) * pulseScale);
              final glow = (1 - progress) * (isDownbeat ? 34.0 : 20.0);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 194,
                  height: 194,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(
                          alpha: isDownbeat ? 0.92 : 0.78,
                        ),
                        AppTheme.accent.withValues(
                          alpha: isDownbeat ? 0.74 : 0.48,
                        ),
                        const Color(0xFF0B1220),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(
                          alpha: 0.20 + glow / 120,
                        ),
                        blurRadius: 28 + glow,
                        spreadRadius: isDownbeat ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$beat',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: const Color(0xFF041016),
                        fontSize: isDownbeat ? 82 : 72,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Beat $beat / $beatsPerMeasure',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Container(
              key: ValueKey(status),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.34)),
              ),
              child: Text(
                status,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: statusColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BpmCard extends StatelessWidget {
  const _BpmCard({
    required this.bpm,
    required this.enabled,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
  });

  final int bpm;
  final bool enabled;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tempo', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onPressed: enabled ? onDecrease : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$bpm',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: 44, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'BPM',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onPressed: enabled ? onIncrease : null,
              ),
            ],
          ),
          Slider(
            min: 40,
            max: 220,
            divisions: 180,
            value: bpm.toDouble(),
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.value,
    required this.enabled,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final bool enabled;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Signature',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                for (final option in options)
                  ButtonSegment(value: option, label: Text(option)),
              ],
              selected: {value},
              onSelectionChanged: enabled
                  ? (values) => onChanged(values.first)
                  : null,
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStats extends StatelessWidget {
  const _LiveStats({required this.stats});

  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(label: 'Detected', value: '${stats.total}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(label: 'Good', value: '${stats.good}'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(label: 'Offset', value: '${stats.averageOffsetMs}ms'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(stats.accuracy * 100).round()}%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppTheme.good,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'accuracy',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Good', value: '${stats.good}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(label: 'Early', value: '${stats.early}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(label: 'Late', value: '${stats.late}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Metric(
            label: 'Average offset',
            value: '${stats.averageOffsetMs} ms',
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.wide = false});

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 18 : 12,
        vertical: wide ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: wide
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      style: IconButton.styleFrom(
        fixedSize: const Size(54, 54),
        backgroundColor: AppTheme.surfaceHigh,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.surfaceHigh.withValues(alpha: 0.48),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
