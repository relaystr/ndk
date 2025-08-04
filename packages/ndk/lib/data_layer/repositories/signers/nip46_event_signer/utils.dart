int someTimeAgo({Duration duration = const Duration(minutes: 5)}) {
  return (DateTime.now().millisecondsSinceEpoch ~/ 1000) - duration.inSeconds;
}
