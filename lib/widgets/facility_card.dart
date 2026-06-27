import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/favorites_notifier.dart';
import '../utils/app_theme.dart';

class FacilityCard extends StatefulWidget {
  final Place place;
  final double? distance;
  final VoidCallback onTap;

  const FacilityCard({
    super.key,
    required this.place,
    this.distance,
    required this.onTap,
  });

  @override
  State<FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<FacilityCard> {
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

  @override
  Widget build(BuildContext context) {
    final isFav = favoritesNotifier.isFavorite(widget.place.id);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder / header
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _iconFor(widget.place.categoryName),
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  // Rating badge
                  if (widget.place.rating != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 13, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              widget.place.rating!.toStringAsFixed(1),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    left: 10,
                    child: GestureDetector(
                      onTap: () =>
                          favoritesNotifier.toggleFavorite(widget.place),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_outline,
                          size: 15,
                          color: isFav ? AppColors.error : AppColors.outline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.distance != null
                              ? '${widget.distance! < 1 ? '${(widget.distance! * 1000).toStringAsFixed(0)} m' : '${widget.distance!.toStringAsFixed(1)} km'} • ${widget.place.categoryName ?? ''}'
                              : widget.place.categoryName ?? '',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String? name) {
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
}