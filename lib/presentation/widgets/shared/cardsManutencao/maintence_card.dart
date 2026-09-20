import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class MaintenanceCard extends StatelessWidget {
  final String asset;
  final String date;
  final String type;

  final VoidCallback? onTap;

  const MaintenanceCard({
    super.key,
    required this.asset,
    required this.date,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(8),

      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: AppColors.backgroundCards,

          borderRadius: BorderRadius.circular(8),

          border: Border.all(color: AppColors.borderColor),
        ),

        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: AppColors.mainColorLight,

                borderRadius: BorderRadius.circular(7),
              ),

              child: const Icon(
                Icons.build_outlined,

                color: AppColors.mainColor,

                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    asset,

                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    type,

                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              date,

              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
