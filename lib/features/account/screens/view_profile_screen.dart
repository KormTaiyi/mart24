import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/network/api_endpoints.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/features/home/models/product.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Product? product = _resolveProduct(context);
    if (product == null) {
      return const _NoProfileDataView();
    }

    final Size size = MediaQuery.of(context).size;
    final double cardWidth = size.width > 400 ? 360 : size.width;

    return Scaffold(
      // backgroundColor: const Color(0xFF1F1E1D),
      body: Center(
        child: Container(
          width: cardWidth,
          height: size.height,
          decoration: const BoxDecoration(color: Colors.white),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(product: product),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: _PostCard(product: product),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Product? _resolveProduct(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is Product) return args;
    return null;
  }
}

class _NoProfileDataView extends StatelessWidget {
  const _NoProfileDataView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'No profile data available.',
          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Product product;

  const _ProfileHeader({required this.product});

  @override
  Widget build(BuildContext context) {
    final String displayName = _displaySellerName(product.agentName);

    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      backgroundImage: _avatarImageProvider(
                        product.agentAvatar,
                      ),
                      child: _avatarImageProvider(product.agentAvatar) == null
                          ? const Icon(Icons.person, color: Colors.black54)
                          : null,
                    ),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: ProfileManager.profileListenable,
                      builder: (context, _) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _buildSocialBubbles(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: Column(
                  children: [
                    _RoundActionButton(
                      icon: EneftyIcons.call_outline,
                      label: 'Call Now',
                      background: Colors.white.withValues(alpha: 0.10),
                      foreground: Colors.white,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _RoundActionButton(
                      icon: EneftyIcons.arrow_right_3_outline,
                      label: 'All Posts',
                      background: const Color(0xFFF2F2F2),
                      foreground: Colors.black,
                      trailingIcon: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSocialBubbles() {
    final List<Widget> bubbles = <Widget>[];

    if (ProfileManager.facebookUrl.value.trim().isNotEmpty) {
      bubbles.add(
        const _SocialBubble(background: Color(0xFF1877F2), label: 'f'),
      );
    }

    if (ProfileManager.telegramUrl.value.trim().isNotEmpty) {
      bubbles.add(
        const _SocialBubble(background: Color(0xFF229ED9), label: 'tg'),
      );
    }

    if (ProfileManager.instagramUrl.value.trim().isNotEmpty) {
      bubbles.add(
        const _SocialBubble(background: Color(0xFFE1306C), label: 'ig'),
      );
    }

    if (ProfileManager.tiktokUrl.value.trim().isNotEmpty) {
      bubbles.add(const _SocialBubble(background: Colors.black, label: 'tt'));
    }

    return bubbles;
  }
}

class _PostCard extends StatelessWidget {
  final Product product;

  const _PostCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final String displayName = _displaySellerName(product.agentName);
    final String displayPostedTime = _displayPostedTime(product.postedTime);
    final String plainName = _toPlainText(product.name);
    final String plainDescription = _toPlainText(product.description);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD3D3D3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: _avatarImageProvider(product.agentAvatar),
                child: _avatarImageProvider(product.agentAvatar) == null
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (displayPostedTime.isNotEmpty)
                      Text(
                        displayPostedTime,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(EneftyIcons.more_outline, size: 26),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plainName.isEmpty ? 'Untitled product' : plainName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plainDescription.isEmpty ? '-' : plainDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                // color: const Color(0xFFE3E3E3),
                padding: const EdgeInsets.all(20),
                child: _buildProductImage(product.image),
              ),
            ),
          ),
          // const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                // padding: const EdgeInsets.symmetric(
                //   horizontal: 10,
                //   vertical: 6,
                // ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String source) {
    final String value = _resolveImageSource(source);
    if (value.isEmpty) {
      return Image.asset(AppAssets.phone, fit: BoxFit.contain);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Image.asset(AppAssets.phone, fit: BoxFit.contain),
      );
    }

    if (value.startsWith('assets/')) {
      return Image.asset(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Image.asset(AppAssets.phone, fit: BoxFit.contain),
      );
    }

    return Image.asset(AppAssets.phone, fit: BoxFit.contain);
  }
}

ImageProvider<Object>? _avatarImageProvider(String source) {
  final String value = _resolveImageSource(source);
  if (value.isEmpty) {
    return null;
  }

  if (value.startsWith('http://') || value.startsWith('https://')) {
    return NetworkImage(value);
  }

  if (value.startsWith('assets/')) {
    return AssetImage(value);
  }

  return null;
}

String _resolveImageSource(String source) {
  final String value = source.trim();
  if (value.isEmpty) {
    return '';
  }

  if (value.startsWith('assets/')) {
    return value;
  }

  final Uri? uri = Uri.tryParse(value);
  if (uri == null) {
    return '';
  }
  if (uri.hasScheme) {
    return value;
  }

  return Uri.parse(ApiConfig.baseUrl).resolve(value).toString();
}

String _toPlainText(String raw) {
  String value = raw.trim();
  if (value.isEmpty) {
    return '';
  }

  value = value
      .replaceAll('<br>', '\n')
      .replaceAll('<br/>', '\n')
      .replaceAll('<br />', '\n')
      .replaceAll('</p>', '\n\n')
      .replaceAll('</P>', '\n\n')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', '\'');

  final StringBuffer plain = StringBuffer();
  bool insideTag = false;
  for (final int codeUnit in value.codeUnits) {
    if (codeUnit == 60) {
      insideTag = true;
      continue;
    }
    if (codeUnit == 62) {
      insideTag = false;
      continue;
    }
    if (!insideTag) {
      plain.writeCharCode(codeUnit);
    }
  }

  String normalized = plain.toString().trim();
  while (normalized.contains('\n\n\n')) {
    normalized = normalized.replaceAll('\n\n\n', '\n\n');
  }
  while (normalized.contains('  ')) {
    normalized = normalized.replaceAll('  ', ' ');
  }
  return normalized.trim();
}

String _displaySellerName(String raw) {
  final String value = raw.trim();
  if (value.isEmpty || _looksLikeIdentifier(value)) {
    return 'Unknown seller';
  }
  return value;
}

bool _looksLikeIdentifier(String value) {
  if (value.contains(' ')) {
    return false;
  }

  if (value.length == 24 && _isHex(value)) {
    return true;
  }

  if (value.length >= 32 && value.contains('-')) {
    return true;
  }

  return false;
}

bool _isHex(String value) {
  for (final int codeUnit in value.codeUnits) {
    final bool isDigit = codeUnit >= 48 && codeUnit <= 57;
    final bool isLowerHex = codeUnit >= 97 && codeUnit <= 102;
    final bool isUpperHex = codeUnit >= 65 && codeUnit <= 70;
    if (!isDigit && !isLowerHex && !isUpperHex) {
      return false;
    }
  }
  return true;
}

String _displayPostedTime(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return '';
  }

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  Duration difference = DateTime.now().difference(parsed.toLocal());
  if (difference.isNegative) {
    difference = Duration.zero;
  }

  if (difference.inMinutes < 1) {
    return '1m';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }
  if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()}w';
  }
  if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()}mo';
  }
  return '${(difference.inDays / 365).floor()}y';
}

class _SocialBubble extends StatelessWidget {
  final Color background;
  final String label;

  const _SocialBubble({required this.background, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool trailingIcon;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.trailingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!trailingIcon) ...[
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (trailingIcon) ...[
              const SizedBox(width: 6),
              Icon(icon, color: foreground, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
