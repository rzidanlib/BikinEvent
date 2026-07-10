import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PillSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted; // baru
  final VoidCallback? onFilterTap;
  final bool dark;

  const PillSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = dark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.grey;
    final textColor = dark ? Colors.white : AppColors.textBlack;
    final hintColor = dark ? Colors.white54 : AppColors.softDarkish;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: hintColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Find amazing events',
                      hintStyle: TextStyle(color: hintColor),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.tune, color: textColor, size: 20),
          ),
        ),
      ],
    );
  }
}
