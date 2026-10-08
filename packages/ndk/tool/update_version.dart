import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*(.*?)\s*(?:#.*)?$',
    multiLine: true,
  ).firstMatch(pubspec);

  if (match == null) {
    stderr.writeln('pubspec.yaml does not have a version defined.');
    exitCode = 1;
    return;
  }

  var version = match.group(1)!;
  if (version.length >= 2 &&
      ((version.startsWith("'") && version.endsWith("'")) ||
          (version.startsWith('"') && version.endsWith('"')))) {
    version = version.substring(1, version.length - 1);
  }
  if (!RegExp(r'^[0-9A-Za-z.+-]+$').hasMatch(version)) {
    stderr.writeln('Unsupported version in pubspec.yaml: $version');
    exitCode = 1;
    return;
  }

  File('lib/src/version.dart').writeAsStringSync('''
// Generated code. Do not modify.
const packageVersion = '$version';
''');
}
