import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

Future<void> registerProtocol(String scheme) async {
  if (!Platform.isWindows) return;

  final appPath = Platform.resolvedExecutable;
  final protocolKey = CURRENT_USER.create('Software\\Classes\\$scheme');
  try {
    protocolKey
      ..setValue('', RegistryValue.string('URL:$scheme'))
      ..setValue('URL Protocol', const RegistryValue.string(''));

    final commandKey = protocolKey.create(r'shell\open\command');
    try {
      commandKey.setValue(
        '',
        RegistryValue.string('"$appPath" "%1"'),
      );
    } finally {
      commandKey.close();
    }
  } finally {
    protocolKey.close();
  }
}
