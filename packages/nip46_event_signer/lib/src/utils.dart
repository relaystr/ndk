import 'dart:math';

String generateRandomString({int length = 16}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(
    length,
    (index) => chars[random.nextInt(chars.length)],
  ).join();
}

int someTimeAgo({Duration duration = const Duration(minutes: 5)}) {
  return (DateTime.now().millisecondsSinceEpoch ~/ 1000) - duration.inSeconds;
}
