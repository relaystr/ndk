import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class NBanner extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;

  String? get _pubkey => pubkey ?? ndk.accounts.getPublicKey();

  const NBanner({super.key, required this.ndk, this.pubkey});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ndk.metadata.loadMetadata(_pubkey!),
      builder: (context, snapshot) {
        return _buildBannerContent(context, snapshot);
      },
    );
  }

  Widget _buildBannerContent(
    BuildContext context,
    AsyncSnapshot<Metadata?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDefaultBanner(context);
    }

    final banner = snapshot.data?.banner;
    if (banner == null) {
      return _buildDefaultBanner(context);
    }

    return _buildImageBanner(context, banner);
  }

  Widget _buildDefaultBanner(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: NdkFlutter.getColorFromPubkey(_pubkey!),
      brightness: Theme.of(context).brightness,
    );

    return Container(
      height: 10,
      width: 10,
      color: colorScheme.primaryContainer,
    );
  }

  Widget _buildImageBanner(BuildContext context, String bannerUrl) {
    return Image.network(
      bannerUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return ColoredBox(
          color: NdkFlutter.getColorFromPubkey(_pubkey!).withValues(alpha: 0.3),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultBanner(context);
      },
    );
  }
}
