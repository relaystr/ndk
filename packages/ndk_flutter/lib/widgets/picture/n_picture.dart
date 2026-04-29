import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_flutter/ndk_flutter.dart';
import '../../utils/nip_avatar.dart';

class NPicture extends StatelessWidget {
  final NdkFlutter ndkFlutter;
  final String? pubkey;
  final Metadata? metadata;
  final bool useCircleAvatar;
  final double? circleAvatarRadius;

  Ndk get ndk => ndkFlutter.ndk;

  String? get _pubkey =>
      metadata?.pubKey ?? pubkey ?? ndk.accounts.getPublicKey();

  const NPicture({
    super.key,
    required this.ndkFlutter,
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
      return _buildDefaultPicture(context, metadata);
    }

    return _buildImagePicture(context, picture, metadata);
  }

  Widget _buildPictureContent(
    BuildContext context,
    AsyncSnapshot<Metadata?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildDefaultPicture(context, snapshot.data);
    }

    final picture = snapshot.data?.picture;
    if (picture == null) {
      return _buildDefaultPicture(context, snapshot.data);
    }

    return _buildImagePicture(context, picture, snapshot.data);
  }

  Widget _buildDefaultPicture(BuildContext context, Metadata? metadata) {
    final initial = NipAvatar.getInitial(_pubkey!, metadata);
    final avatarColor = NipAvatar.getColor(_pubkey!);

    return Container(
      color: avatarColor.background,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize = constraints.maxHeight > 0
                ? constraints.maxHeight * 0.4
                : 16.0;
            return Text(
              initial,
              style: TextStyle(
                color: avatarColor.text,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagePicture(
    BuildContext context,
    String pictureUrl,
    Metadata? metadata,
  ) {
    return Image.network(
      pictureUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return _buildDefaultPicture(context, metadata);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultPicture(context, metadata);
      },
    );
  }
}
