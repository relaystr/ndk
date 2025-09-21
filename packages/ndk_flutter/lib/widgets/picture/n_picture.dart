import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';

class NPicture extends StatelessWidget {
  final Ndk ndk;
  final String? pubkey;
  final Metadata? metadata;
  final bool useCircleAvatar;
  final double? circleAvatarRadius;

  String? get _pubkey => pubkey ?? ndk.accounts.getPublicKey();

  const NPicture({
    super.key,
    required this.ndk,
    this.pubkey,
    this.metadata,
    this.useCircleAvatar = true,
    this.circleAvatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    // If metadata is already provided, use it directly without loading
    if (metadata != null) {
      final picture = _buildPictureContentFromMetadata(context, metadata);

      if (useCircleAvatar) {
        return CircleAvatar(
          radius: circleAvatarRadius,
          child: ClipOval(child: AspectRatio(aspectRatio: 1, child: picture)),
        );
      }

      return picture;
    }

    // Only load metadata if it's not provided
    return FutureBuilder(
      future: ndk.metadata.loadMetadata(_pubkey!),
      builder: (context, snapshot) {
        final picture = _buildPictureContent(context, snapshot);

        if (useCircleAvatar) {
          return CircleAvatar(
            radius: circleAvatarRadius,
            child: ClipOval(child: AspectRatio(aspectRatio: 1, child: picture)),
          );
        }

        return picture;
      },
    );
  }

  Widget _buildPictureContentFromMetadata(
    BuildContext context,
    Metadata? metadata,
  ) {
    final picture = metadata?.picture;
    if (picture == null) {
      return _buildDefaultPicture(context, metadata?.getName());
    }

    return _buildImagePicture(context, picture);
  }

  Widget _buildPictureContent(
    BuildContext context,
    AsyncSnapshot<Metadata?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDefaultPicture(context, snapshot.data?.getName());
    }

    final picture = snapshot.data?.picture;
    if (picture == null) {
      return _buildDefaultPicture(context, snapshot.data?.getName());
    }

    return _buildImagePicture(context, picture);
  }

  Widget _buildDefaultPicture(BuildContext context, String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '';
    final color = NdkFlutter.getColorFromPubkey(_pubkey!);

    return Container(
      color: color,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildImagePicture(BuildContext context, String pictureUrl) {
    return Image.network(
      pictureUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return ColoredBox(color: NdkFlutter.getColorFromPubkey(_pubkey!));
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultPicture(context, null);
      },
    );
  }
}
