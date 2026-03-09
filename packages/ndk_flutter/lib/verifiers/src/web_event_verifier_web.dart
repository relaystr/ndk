import 'dart:async';
import 'dart:js_interop';

import 'package:ndk/ndk.dart';
import 'package:web/web.dart' as web;

import 'js_interop.dart';
import 'nostr_verify_js.dart';

/// Web implementation of EventVerifier using nostr-tools via JS interop.
/// Uses native Web Crypto APIs for fast signature verification.
class WebEventVerifier implements EventVerifier {
  final Completer<bool> _isInitialized = Completer<bool>();
  static bool _jsInjected = false;

  WebEventVerifier() {
    _init();
  }

  Future<void> _init() async {
    if (!_jsInjected) {
      _injectJS();
      _jsInjected = true;
    }
    _isInitialized.complete(true);
  }

  void _injectJS() {
    // Check if already loaded (e.g., via index.html)
    if (nostrVerifier != null) {
      return;
    }

    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.type = 'text/javascript';
    script.text = nostrVerifyJs;
    web.document.head?.appendChild(script);
  }

  @override
  Future<bool> verify(Nip01Event event) async {
    await _isInitialized.future;

    if (event.sig == null) {
      return false;
    }

    final verifier = nostrVerifier;
    if (verifier == null) {
      throw Exception(
        'NostrVerifier not available. JS injection may have failed.',
      );
    }

    final jsEvent = NostrEventJS();
    jsEvent.id = event.id;
    jsEvent.pubkey = event.pubKey;
    jsEvent.created_at = event.createdAt;
    jsEvent.kind = event.kind;
    jsEvent.content = event.content;
    jsEvent.sig = event.sig!;

    // Convert tags
    final jsTags = event.tags
        .map((tag) {
          return tag.map((t) => t.toJS).toList().toJS;
        })
        .toList()
        .toJS;
    jsEvent.tags = jsTags;

    final result = await verifier.verifyEvent(jsEvent).toDart;
    return result.toDart;
  }
}
