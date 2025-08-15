import 'dart:io';

void configureDefaultUserAgent(String userAgent) {
  WebSocket.userAgent = userAgent;
}
