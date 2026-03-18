import 'package:ndk/ndk.dart';

abstract class CliCommand {
  String get name;
  String get description;
  String get usage;

  Future<int> run(List<String> args, Ndk ndk);
}
