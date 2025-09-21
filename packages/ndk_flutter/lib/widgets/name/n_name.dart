import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:nip19/nip19.dart';

class NName extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;
  final Metadata? metadata;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool displayNpub;

  String? get _pubkey => pubkey ?? ndk.accounts.getPublicKey();

  const NName({
    super.key,
    required this.ndk,
    this.pubkey,
    this.metadata,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.displayNpub = false,
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
          displayNpub ? _formatNpub(_pubkey!) : _formatPubkey(_pubkey!),
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

  String _formatPubkey(String pubkey) {
    return '${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}';
  }

  String _formatNpub(String pubkey) {
    try {
      final npub = Nip19.npubFromHex(pubkey);
      return '${npub.substring(0, 6)}...${npub.substring(npub.length - 6)}';
    } catch (e) {
      return _formatPubkey(pubkey);
    }
  }
}
