/// DO NOT USE IN PRODUCTION CODE! Only for debugging and testing purposes.
class SimpleProfiler {
  final String name;
  final DateTime startTime;
  DateTime _lastCheckpoint;

  SimpleProfiler(this.name)
      : startTime = DateTime.now(),
        _lastCheckpoint = DateTime.now() {
    // ignore: avoid_print
    print('Starting $name at $startTime');
  }

  void checkpoint(String description) {
    final now = DateTime.now();
    final totalDuration = now.difference(startTime);
    final checkpointDuration = now.difference(_lastCheckpoint);

    // ignore: avoid_print
    print('$name - $description:'
        '\n\tTotal: ${totalDuration.inMilliseconds}ms'
        '\n\tSince last checkpoint: ${checkpointDuration.inMilliseconds}ms');

    _lastCheckpoint = now;
  }

  void end() {
    final now = DateTime.now();
    final totalDuration = now.difference(startTime);
    final checkpointDuration = now.difference(_lastCheckpoint);

    // ignore: avoid_print
    print('Ended $name:'
        '\n\tTotal time: ${totalDuration.inMilliseconds}ms'
        '\n\tSince last checkpoint: ${checkpointDuration.inMilliseconds}ms');
  }
}
