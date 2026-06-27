import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/favorites_notifier.dart';
import '../utils/app_theme.dart';

class PlaceCard extends StatefulWidget {
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

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  @override
  void initState() {
    super.initState();
    favoritesNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    favoritesNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

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

  @override
  Widget build(BuildContext context) {
    final isFav = favoritesNotifier.isFavorite(widget.place.id);
    final catColor = _categoryColor(widget.place.categoryName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_categoryIcon(widget.place.categoryName),
                    color: catColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.place.name,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (widget.place.address != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.place.address!,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (widget.distance != null) ...[
                          const Icon(Icons.near_me,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            widget.distance! < 1
                                ? '${(widget.distance! * 1000).toStringAsFixed(0)} m'
                                : '${widget.distance!.toStringAsFixed(1)} km',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (widget.place.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            widget.place.rating!.toStringAsFixed(1),
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        if (widget.place.openingHours != null) ...[
                          if (widget.place.rating != null)
                            const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.outline),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              widget.place.openingHours!.trim() == '24 Jam'
                                  ? 'Buka 24 Jam'
                                  : widget.place.openingHours!
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
              Column(
                children: [
                  GestureDetector(
                    onTap: () => favoritesNotifier.toggleFavorite(widget.place),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                        key: ValueKey(isFav),
                        color: isFav ? AppColors.error : AppColors.outline,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
            ],
          ),
        ),
      ),
    );
  }
}