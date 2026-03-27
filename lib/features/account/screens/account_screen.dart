import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/account/screens/setting_screen.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/features/home/models/product.dart';
import 'package:mart24/shared/widgets/user_avatar.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final List<Product> _postedProducts;
  static const int _pageSize = 10;
  int _visiblePostCount = _pageSize;
  static final TextInputFormatter _priceInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final String sanitized = _digitsAndSingleDecimal(newValue.text);

        return TextEditingValue(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length),
        );
      });

  @override
  void initState() {
    super.initState();
    _postedProducts = <Product>[];
  }

  Future<void> _handlePostAction(_PostAction? action, int productIndex) async {
    if (!mounted || action == null) {
      return;
    }

    if (productIndex < 0 || productIndex >= _postedProducts.length) {
      return;
    }

    if (action == _PostAction.update) {
      await _showUpdatePostDialog(productIndex);
      return;
    }

    if (action == _PostAction.delete) {
      await _confirmDeletePost(productIndex);
    }
  }

  Future<void> _showUpdatePostDialog(int productIndex) async {
    final Product product = _postedProducts[productIndex];
    final TextEditingController nameController = TextEditingController(
      text: product.name,
    );
    final TextEditingController priceController = TextEditingController(
      text: _editablePrice(product.newPrice),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: product.description,
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final Product? updatedProduct = await showDialog<Product>(
      context: context,
      builder: (context) {
        final NavigatorState navigator = Navigator.of(context);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Update Post', style: AppTextStyles.subtitle),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: _requiredValidator,
                    decoration: const InputDecoration(labelText: 'Post Name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_priceInputFormatter],
                    validator: _priceValidator,
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    validator: _requiredValidator,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                navigator.pop(
                  product.copyWithDetails(
                    name: nameController.text.trim(),
                    newPrice: _displayPrice(priceController.text),
                    description: descriptionController.text.trim(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();

    if (updatedProduct != null && mounted) {
      setState(() {
        if (productIndex < 0 || productIndex >= _postedProducts.length) {
          return;
        }

        _postedProducts[productIndex] = updatedProduct;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully')),
      );
    }
  }

  Future<void> _confirmDeletePost(int productIndex) async {
    final Product product = _postedProducts[productIndex];
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Delete Post', style: AppTextStyles.subtitle),
          content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      setState(() {
        if (productIndex < 0 || productIndex >= _postedProducts.length) {
          return;
        }

        _postedProducts.removeAt(productIndex);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Post deleted')));
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    if (double.tryParse(value.trim()) == null) {
      return 'Enter numbers only';
    }

    return null;
  }

  String _editablePrice(String value) {
    return _digitsAndSingleDecimal(value);
  }

  String _displayPrice(String value) {
    final String normalized = value.trim();
    return normalized.startsWith('\$') ? normalized : '\$$normalized';
  }

  static String _digitsAndSingleDecimal(String value) {
    final StringBuffer buffer = StringBuffer();
    bool hasDecimalPoint = false;

    for (final int codeUnit in value.codeUnits) {
      final String char = String.fromCharCode(codeUnit);
      final bool isDigit = codeUnit >= 48 && codeUnit <= 57;

      if (isDigit) {
        buffer.write(char);
        continue;
      }

      if (char == '.' && !hasDecimalPoint) {
        buffer.write(char);
        hasDecimalPoint = true;
      }
    }

    return buffer.toString();
  }

  bool _hasMorePosts() => _visiblePostCount < _postedProducts.length;

  int _resolvedVisiblePostCount() {
    return _visiblePostCount.clamp(0, _postedProducts.length);
  }

  void _loadMorePosts() {
    if (!_hasMorePosts()) {
      return;
    }

    setState(() {
      _visiblePostCount = (_visiblePostCount + _pageSize).clamp(
        0,
        _postedProducts.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SessionManager.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3F3),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  postCount: isAuthenticated ? _postedProducts.length : 0,
                  isAuthenticated: isAuthenticated,
                ),
              ),
              if (!isAuthenticated)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _GuestAccountState(),
                )
              else if (_postedProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'You have no posts yet.',
                        style: AppTextStyles.subtitle.copyWith(
                          color: const Color(0xFF6B6464),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index.isOdd) {
                        return const SizedBox(height: 18);
                      }

                      final productIndex = index ~/ 2;
                      return _PostedProductCard(
                        product: _postedProducts[productIndex],
                        onActionSelected: (action) =>
                            _handlePostAction(action, productIndex),
                      );
                    }, childCount: _resolvedVisiblePostCount() * 2 - 1),
                  ),
                ),
              if (isAuthenticated && _hasMorePosts())
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: TextButton(
                        onPressed: _loadMorePosts,
                        child: const Text('Load more products'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _PostAction { update, delete }

class _ProfileHeader extends StatelessWidget {
  final int postCount;
  final bool isAuthenticated;

  const _ProfileHeader({
    required this.postCount,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 15,
            right: 15,
            bottom: 20,
            top: 15,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'My Profile',
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (isAuthenticated)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingScreen(),
                          ),
                        );
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      splashRadius: 22,
                      icon: const Icon(
                        EneftyIcons.setting_2_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: isAuthenticated
                        ? AnimatedBuilder(
                            animation: ProfileManager.profileListenable,
                            builder: (context, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const UserAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    ProfileManager.userName.value.trim().isEmpty
                                        ? 'No user name yet'
                                        : ProfileManager.userName.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ProfileManager.shopName.value.trim().isEmpty
                                        ? 'No shop name yet'
                                        : ProfileManager.shopName.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const UserAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Guest User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No data yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 18),
                  if (isAuthenticated)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderActionTile(
                          icon: EneftyIcons.edit_2_outline,
                          label: 'Edit',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.editProfile);
                          },
                          isLight: false,
                        ),
                        const SizedBox(height: 14),
                        _HeaderActionTile(
                          icon: EneftyIcons.camera_outline,
                          label: '$postCount posts',
                          onTap: () {},
                          isLight: true,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestAccountState extends StatelessWidget {
  const _GuestAccountState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No account data yet',
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5D5656),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Login or register to view your posts and manage your profile.',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF7A7272),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LoginScreen(returnResultOnSuccess: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const RegisterScreen(returnResultOnSuccess: true),
                    ),
                  );
                },
                child: const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLight;

  const _HeaderActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = isLight
        ? const Color(0xFFE8E3E3)
        : Colors.white.withValues(alpha: 0.12);

    final Color foreground = isLight ? const Color(0xFF1C1C1C) : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLight
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostedProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<_PostAction> onActionSelected;

  const _PostedProductCard({
    required this.product,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E0E0),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const UserAvatar(radius: 24, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedBuilder(
                  animation: ProfileManager.userName,
                  builder: (context, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ProfileManager.userName.value.trim().isEmpty
                              ? 'No user name yet'
                              : ProfileManager.userName.value,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${product.postedTime} ago',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8A8A8A),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.subtitle.copyWith(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF5F5A5A),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: Image.asset(product.image, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECEC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  product.newPrice,
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<_PostAction>(
                onSelected: onActionSelected,
                tooltip: 'Post actions',
                color: Colors.white,
                elevation: 10,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 112),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                position: PopupMenuPosition.under,
                itemBuilder: (context) => const [
                  PopupMenuItem<_PostAction>(
                    value: _PostAction.update,
                    height: 32,
                    child: _CompactActionItem(
                      icon: EneftyIcons.edit_2_outline,
                      label: 'Update',
                    ),
                  ),
                  PopupMenuItem<_PostAction>(
                    value: _PostAction.delete,
                    height: 32,
                    child: _CompactActionItem(
                      icon: EneftyIcons.trash_outline,
                      label: 'Delete',
                      color: Colors.redAccent,
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    EneftyIcons.more_2_outline,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _CompactActionItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
