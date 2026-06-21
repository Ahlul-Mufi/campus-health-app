import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class HealthyUnairAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final List<Widget>? actions;

  const HealthyUnairAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.outlineVariant.withValues(alpha: 0.5),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          if (!showBack) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            title ?? 'Healthy UNAIR',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: showBack ? 18 : 20,
            ),
          ),
        ],
      ),
      actions: actions ??
          [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: const Icon(
                  Icons.person,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ],
    );
  }
}