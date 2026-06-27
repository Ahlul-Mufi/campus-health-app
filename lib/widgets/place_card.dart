import 'package:flutter/material.dart';
import '../models/place.dart';
import '../utils/app_theme.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  final double? distance;
  final bool compact;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.distance,
    this.compact = false,
  });

  Color _categoryColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'rumah sakit':
        return const Color(0xFF2E7D32);
      case 'klinik':
        return const Color(0xFF3C6842);
      case 'puskesmas':
        return const Color(0xFF4D5950);
      default:
        return AppColors.secondary;
    }
  }

  Widget _iconPlaceholder(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_categoryIcon(place.categoryName),
          color: catColor, size: 26),
    );
  }

  IconData _categoryIcon(String? name) {
    switch (name?.toLowerCase()) {
      case 'rumah sakit':
        return Icons.local_hospital;
      case 'klinik':
        return Icons.medical_services;
      case 'puskesmas':
        return Icons.health_and_safety;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(place.categoryName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: place.effectiveFotoUrl != null
                      ? Image.network(
                          place.effectiveFotoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _iconPlaceholder(catColor),
                          errorBuilder: (_, _, _) => _iconPlaceholder(catColor),
                        )
                      : _iconPlaceholder(catColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (place.address != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        place.address!,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (distance != null) ...[
                          const Icon(Icons.near_me,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            distance! < 1
                                ? '${(distance! * 1000).toStringAsFixed(0)} m'
                                : '${distance!.toStringAsFixed(1)} km',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (place.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        if (place.openingHours != null) ...[
                          if (place.rating != null)
                            const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.outline),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              place.openingHours!.trim() == '24 Jam'
                                  ? 'Buka 24 Jam'
                                  : place.openingHours!
                                      .split('\n')
                                      .first,
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.outline),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right,
                    color: AppColors.primary, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
