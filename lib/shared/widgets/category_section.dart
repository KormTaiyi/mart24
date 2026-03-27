import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/constants/app_assets.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class CategorySection extends StatelessWidget {
  final String? title;
  final bool isGrid;
  final bool isMore;
  final List<Map<String, String>>? items;

  const CategorySection({
    super.key,
    this.title,
    this.isGrid = false,
    this.isMore = false,
    this.items,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories =
        items ?? const <Map<String, String>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isMore)
                    GestureDetector(
                      onTap: () {
                        // Navigator.pushNamed(context, AppRoutes.category);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ទាំងអស់",
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            EneftyIcons.arrow_right_3_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (title != null && title!.isNotEmpty) const SizedBox(height: 10),
          if (isGrid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 4,
                // mainAxisSpacing: 4,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, idx) {
                final category = categories[idx];
                final label = category["label"] ?? "";
                final image = category["image"] ?? "";

                return GestureDetector(
                  onTap: () {},
                  child: _CategoryItem(label: label, image: image),
                );
              },
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(categories.length, (idx) {
                  final category = categories[idx];
                  final label = category["label"] ?? "";
                  final image = category["image"] ?? "";

                  return Padding(
                    padding: EdgeInsets.only(
                      right: idx == categories.length - 1 ? 0 : 10,
                    ),
                    child: GestureDetector(
                      onTap: () {},
                      child: _CategoryItem(label: label, image: image),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String image;

  const _CategoryItem({required this.label, required this.image});

  @override
  Widget build(BuildContext context) {
    final String source = image.trim();
    final Widget avatarImage =
        source.startsWith('http://') || source.startsWith('https://')
        ? Image.network(
            source,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset(AppAssets.phone, fit: BoxFit.cover),
          )
        : Image.asset(
            source.isEmpty ? AppAssets.phone : source,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Image.asset(AppAssets.phone, fit: BoxFit.cover),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          // height: 55,
          width: 60,
          decoration: const BoxDecoration(
            color: AppColors.circleBackground,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(5),
          child: avatarImage,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: Colors.black),
        ),
      ],
    );
  }
}
