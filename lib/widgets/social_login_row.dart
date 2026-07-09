import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.grey2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or continue with',
                style: TextStyle(color: AppColors.softDarkish, fontSize: 13),
              ),
            ),
            Expanded(child: Divider(color: AppColors.grey2)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(Icons.facebook, AppColors.blue),
            const SizedBox(width: 16),
            _socialButton(Icons.g_mobiledata, AppColors.error),
            const SizedBox(width: 16),
            _socialButton(Icons.apple, AppColors.textBlack),
          ],
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey2),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
