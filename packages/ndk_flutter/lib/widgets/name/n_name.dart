import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class NName extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;
  final Metadata? metadata;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  String? get _pubkey =>
      metadata?.pubKey ?? pubkey ?? ndk.accounts.getPublicKey();

  const NName({
    super.key,
    required this.ndk,
    this.pubkey,
    this.metadata,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getName(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Text(
            snapshot.data!,
            style: style,
            maxLines: maxLines,
            overflow: overflow,
          );
        }

        return Text(
          NdkFlutter.formatNpub(_pubkey!),
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }

  Future<String?> _getName() async {
    try {
      // Use provided metadata if available, otherwise load it
      final userMetadata =
          metadata ?? await ndk.metadata.loadMetadata(_pubkey!);
      return userMetadata?.getName();
    } catch (e) {
      return null;
    }
  }
}
