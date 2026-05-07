import 'package:ndk/ndk.dart';

/// Native implementation of PlatformEventSigner.
/// Uses [Bip340EventSigner] for pure Dart crypto.
typedef PlatformEventSigner = Bip340EventSigner;
