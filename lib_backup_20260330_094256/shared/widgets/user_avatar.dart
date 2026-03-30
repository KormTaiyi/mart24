import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/utils/image_source_resolver.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BoxFit fit;
  final bool bindToProfile;
  final String? imagePath;

  const UserAvatar({
    super.key,
    required this.radius,
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.borderWidth = 0,
    this.fit = BoxFit.cover,
    this.bindToProfile = true,
    this.imagePath,
  });

  ImageProvider<Object>? _imageProvider(String path) {
    final ImageProvider<Object>? resolved = ImageSourceResolver.toImageProvider(
      path,
    );
    if (resolved != null) {
      return resolved;
    }

    final String value = ImageSourceResolver.resolve(path);
    if (value.isEmpty || kIsWeb) {
      return null;
    }

    if (ImageSourceResolver.isNetwork(value) || ImageSourceResolver.isAsset(value)) {
      return null;
    }

    return FileImage(File(value));
  }

  Widget _buildAvatar(String? avatarPath) {
    final ImageProvider<Object>? avatarProvider = avatarPath == null
        ? null
        : _imageProvider(avatarPath);
    final bool hasAvatar = avatarProvider != null;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: avatarProvider,
        onBackgroundImageError: hasAvatar ? (_, _) {} : null,
        child: hasAvatar
            ? null
            : const Icon(
                EneftyIcons.profile_circle_outline,
                color: AppColors.primary,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!bindToProfile) {
      return _buildAvatar(imagePath);
    }

    return ValueListenableBuilder<String?>(
      valueListenable: ProfileManager.avatarPath,
      builder: (context, avatarPath, _) {
        return _buildAvatar(avatarPath);
      },
    );
  }
}
