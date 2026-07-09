import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarStack extends StatelessWidget {
  final int count;
  final String label;

  const AvatarStack({
    super.key,
    required this.count,
    this.label = 'Members joined',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 26,
          child: Stack(
            children: List.generate(3, (i) {
              return Positioned(
                left: i * 14.0,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.primaryLight2,
                    child: const Icon(
                      Icons.person,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            count > 0 ? '$count+ $label' : label,
            style: TextStyle(fontSize: 11, color: AppColors.softDarkish),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
