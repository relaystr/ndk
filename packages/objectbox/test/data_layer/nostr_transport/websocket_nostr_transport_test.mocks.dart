// Mocks generated by Mockito 5.4.4 from annotations
// in ndk/test/data_layer/nostr_transport/websocket_nostr_transport_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:ndk/data_layer/data_sources/websocket.dart' as _i4;
import 'package:web_socket_channel/web_socket_channel.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeWebSocketChannel_0 extends _i1.SmartFake
    implements _i2.WebSocketChannel {
  _FakeWebSocketChannel_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeStreamSubscription_1<T> extends _i1.SmartFake
    implements _i3.StreamSubscription<T> {
  _FakeStreamSubscription_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [WebsocketDS].
///
/// See the documentation for Mockito's code generation for more information.
class MockWebsocketDS extends _i1.Mock implements _i4.WebsocketDS {
  @override
  _i2.WebSocketChannel get webSocketChannel => (super.noSuchMethod(
        Invocation.getter(#webSocketChannel),
        returnValue: _FakeWebSocketChannel_0(
          this,
          Invocation.getter(#webSocketChannel),
        ),
        returnValueForMissingStub: _FakeWebSocketChannel_0(
          this,
          Invocation.getter(#webSocketChannel),
        ),
      ) as _i2.WebSocketChannel);

  @override
  _i3.StreamSubscription<dynamic> listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listen,
          [onData],
          {
            #onError: onError,
            #onDone: onDone,
          },
        ),
        returnValue: _FakeStreamSubscription_1<dynamic>(
          this,
          Invocation.method(
            #listen,
            [onData],
            {
              #onError: onError,
              #onDone: onDone,
            },
          ),
        ),
        returnValueForMissingStub: _FakeStreamSubscription_1<dynamic>(
          this,
          Invocation.method(
            #listen,
            [onData],
            {
              #onError: onError,
              #onDone: onDone,
            },
          ),
        ),
      ) as _i3.StreamSubscription<dynamic>);

  @override
  void send(dynamic data) => super.noSuchMethod(
        Invocation.method(
          #send,
          [data],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.Future<void> ready() => (super.noSuchMethod(
        Invocation.method(
          #ready,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  _i3.Future<void> close() => (super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValue: _i3.Future<void>.value(),
        returnValueForMissingStub: _i3.Future<void>.value(),
      ) as _i3.Future<void>);

  @override
  bool isOpen() => (super.noSuchMethod(
        Invocation.method(
          #isOpen,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);
}