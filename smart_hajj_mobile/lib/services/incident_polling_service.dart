import 'dart:async';

/// One foreground clock. Read-only safety snapshots avoid repeatedly creating
/// incidents or consuming telecom quota through the analysis POST endpoint.
class IncidentPollingService {
  IncidentPollingService({required this.onTick});
  final void Function(int tick) onTick;
  Timer? _timer;
  int _tick = 0;
  void start() {
    if (_timer != null) return;
    onTick(0);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => onTick(++_tick));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
