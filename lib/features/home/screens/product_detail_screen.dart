import 'package:flutter/material.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/favorite_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/utils/favorite_auth_gate.dart';
import 'package:mart24/features/chat/screens/chat_screen.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:enefty_icons/enefty_icons.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _pageController;
  late int _selectedSizeIndex;
  int _selectedImageIndex = 0;

  List<String> get _galleryImages {
    final Set<String> values = <String>{};
    for (final String item in widget.product.galleryImages) {
      final String normalized = item.trim();
      if (!_shouldIgnoreProductImage(normalized)) {
        values.add(normalized);
      }
    }

    final String primaryImage = widget.product.image.trim();
    if (!_shouldIgnoreProductImage(primaryImage)) {
      values.add(primaryImage);
    }

    if (values.isEmpty) {
      // Keep one page slot so the gallery layout size remains stable.
      return const <String>[''];
    }

    return values.toList();
  }

  List<String> get _sizes => widget.product.sizes;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _selectedSizeIndex = _sizes.isEmpty ? 0 : (_sizes.length > 1 ? 1 : 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width > 400 ? 300 : size.width;
    final product = widget.product;
    final String plainDescription = _toPlainText(product.description);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1E1D),
      body: Center(
        child: Container(
          width: cardWidth,
          height: size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
            // borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGallerySection(),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsRow(product),
                              const SizedBox(height: 15),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width -
                                          120,
                                    ),
                                    child: Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: Colors.black,
                                            height: 1.3,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (product.date.trim().isNotEmpty)
                                    Text(
                                      '•',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontSize: 22,
                                            color: const Color(0xFFB0B0B0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  if (product.date.trim().isNotEmpty)
                                    Text(
                                      'date: ${product.date}',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontSize: 14,
                                            color: const Color(0xFFB0B0B0),
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                ],
                              ),
                              if (product.capacity.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Capacity: ${product.capacity}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              const _SectionTitle(title: 'Description'),
                              const SizedBox(height: 8),
                              Text(
                                plainDescription.isEmpty
                                    ? '-'
                                    : plainDescription,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: Color(0xFF181818),
                                ),
                              ),
                              const SizedBox(height: 15),
                              if (_sizes.isNotEmpty) ...[
                                const _SectionTitle(title: 'Size'),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: List.generate(_sizes.length, (
                                    index,
                                  ) {
                                    final bool isSelected =
                                        index == _selectedSizeIndex;

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedSizeIndex = index;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 54,
                                        height: 54,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFF5F5F5)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFE1E1E1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _sizes[index],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 5),
                              ],
                              const _SectionTitle(title: 'Contact Agent'),
                              const SizedBox(height: 14),
                              _buildAgentRow(product),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        SizedBox(
          height: 330,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _galleryImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF1F0EE), Color(0xFFD9D8D6)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 40, 36, 44),
                      child: _buildGalleryImage(
                        _galleryImages[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 20,
                left: 10,
                child: _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
              Positioned(
                top: 20,
                right: 10,
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: FavoriteManager.favorites,
                  builder: (context, favorites, _) {
                    return _CircleFavoriteButton(
                      isFavorite: favorites.contains(
                        widget.product.favoriteKey,
                      ),
                      onTap: () => handleFavoriteTap(context, widget.product),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_galleryImages.length, (index) {
                    final bool isActive = index == _selectedImageIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 10 : 8,
                      height: isActive ? 10 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 66,
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _galleryImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final bool isSelected = index == _selectedImageIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 56,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF5454)
                                : Colors.transparent,
                            width: 1.8,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: _buildGalleryImage(
                            _galleryImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_selectedImageIndex + 1}/${_galleryImages.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(EneftyIcons.arrow_right_3_outline, size: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Product product) {
    final String likes = product.likes.trim();
    final String postedTime = _displayPostedTime(product.postedTime);

    return Row(
      children: [
        const Icon(
          EneftyIcons.heart_outline,
          color: Color(0xFFFF4A4A),
          size: 30,
        ),
        const SizedBox(width: 6),
        Text(
          likes.isEmpty ? '0' : likes,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (postedTime.isNotEmpty) ...[
          const SizedBox(width: 8),
          const Text(
            '|',
            style: TextStyle(fontSize: 18, color: Color(0xFFB9B9B9)),
          ),
          const SizedBox(width: 8),
          Text(
            postedTime,
            style: const TextStyle(fontSize: 16, color: Color(0xFFA7A7A7)),
          ),
        ],
        const Spacer(),
        Text(
          '(${product.views} views)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildGalleryImage(String source, {BoxFit fit = BoxFit.cover}) {
    final String value = source.trim();
    if (_shouldIgnoreProductImage(value)) {
      return const SizedBox.expand();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      );
    }

    return Image.asset(
      value,
      fit: fit,
      errorBuilder: (_, _, _) => const SizedBox.expand(),
    );
  }

  bool _shouldIgnoreProductImage(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty || normalized == AppAssets.phone;
  }

  Widget _buildAgentRow(Product product) {
    final String agentName = _displayAgentName(product.agentName);
    final String agentRole = _displayAgentRole(product.agentRole);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: _avatarImageProvider(product.agentAvatar),
                child: _avatarImageProvider(product.agentAvatar) == null
                    ? const Icon(Icons.person, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      agentName.isEmpty ? '-' : agentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (agentRole.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        agentRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppRoutes.viewProfile,
              arguments: product,
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'View Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Product product) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  product.oldPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB7B7B7),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Color(0xFFB7B7B7),
                  ),
                ),
                Text(
                  product.newPrice,
                  maxLines: 1,
                  // overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF493C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Call Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE3E3E3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _openChatWithOwner(product),
                    icon: Icon(EneftyIcons.message_bold),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChatWithOwner(Product product) {
    final String ownerName = _displayAgentName(product.agentName);
    final String resolvedOwnerName = ownerName.trim().isEmpty
        ? 'Unknown seller'
        : ownerName;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactName: resolvedOwnerName,
          avatarAssetPath: _chatAvatarAssetPath(product.agentAvatar),
        ),
      ),
    );
  }

  String? _chatAvatarAssetPath(String source) {
    final String value = source.trim();
    if (value.startsWith('assets/')) {
      return value;
    }
    return null;
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

  String _displayAgentName(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return 'Unknown seller';
    }
    if (_looksLikeIdentifier(value)) {
      return 'Unknown seller';
    }
    return value;
  }

  String _displayAgentRole(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    if (_looksLikeStructuredPayload(value)) {
      return '';
    }

    return value;
  }

  bool _looksLikeStructuredPayload(String value) {
    final String normalized = value.trim();
    if (normalized.startsWith('{') || normalized.startsWith('[')) {
      return true;
    }

    final String lower = normalized.toLowerCase();
    return lower.contains('createdat:') ||
        lower.contains('updatedat:') ||
        lower.contains('deletedat:');
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
}

ImageProvider<Object>? _avatarImageProvider(String source) {
  final String value = source.trim();
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}

class _CircleFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _CircleFavoriteButton({required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            isFavorite ? EneftyIcons.heart_bold : EneftyIcons.heart_outline,
            size: 22,
            color: isFavorite ? const Color(0xFFFF4A4A) : Colors.black54,
          ),
        ),
      ),
    );
  }
}
