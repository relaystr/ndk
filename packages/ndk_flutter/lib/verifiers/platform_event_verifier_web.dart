import 'package:ndk/ndk.dart';

import 'web_event_verifier.dart';

EventVerifier createPlatformEventVerifier() => WebEventVerifier();
