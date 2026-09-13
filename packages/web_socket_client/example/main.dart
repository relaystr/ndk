import 'package:ndk_web_socket_client/ndk_web_socket_client.dart';

void main() {
  final socket = WebSocket(
    Uri.parse('wss://relay.example.com'),
    compressionEnabled: false,
    backoff: BinaryExponentialBackoff(
      initial: const Duration(milliseconds: 500),
      maximumStep: 4,
    ),
  );
  socket.messages.listen(print);
  // Close the socket when your application no longer needs it.
}
