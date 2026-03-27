import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/theme/app_color.dart';

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

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }

    if (!kIsWeb) {
      return FileImage(File(path));
    }

    return const AssetImage(AppAssets.avatar);
  }

  Widget _buildAvatar(String? avatarPath) {
    final bool hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

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
        backgroundImage: hasAvatar ? _imageProvider(avatarPath) : null,
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
