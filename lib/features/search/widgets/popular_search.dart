import 'package:flutter/material.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';

class PopularSearch extends StatelessWidget {
  final List<String> items;

  const PopularSearch({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Popular search in mart",
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Text(
            'No popular searches yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: items.map((item) => _buildPopularButton(item)).toList(),
          ),
      ],
    );
  }

  Widget _buildPopularButton(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
