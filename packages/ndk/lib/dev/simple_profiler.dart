class SimpleProfiler {
  final String name;
  final DateTime startTime;

  SimpleProfiler(this.name) : startTime = DateTime.now() {
    print('Starting $name at $startTime');
  }

  void checkpoint(String description) {
    final duration = DateTime.now().difference(startTime);
    print('$name - $description: ${duration.inMilliseconds}ms');
  }

  void end() {
    final duration = DateTime.now().difference(startTime);
    print('Ended $name - Total time: ${duration.inMilliseconds}ms');
  }
}


/**

// Usage:
Future<void> someFunction() async {
  final profiler = SimpleProfiler('MyOperation');
  
  await step1();
  profiler.checkpoint('Step 1 completed');
  
  await step2();
  profiler.checkpoint('Step 2 completed');
  
  profiler.end();
}
 */