import 'package:flutter/material.dart';
import '../../models/favorites_notifier.dart';
import '../../models/place.dart';
import '../../utils/app_theme.dart';
import '../detail/detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
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

  Color _colorFor(String? name) {
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

  void _removeWithUndo(Place place) {
    favoritesNotifier.remove(place);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${place.name} dihapus dari favorit'),
        action: SnackBarAction(
          label: 'Batalkan',
          onPressed: () => favoritesNotifier.toggleFavorite(place),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = favoritesNotifier.favorites;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.outlineVariant.withValues(alpha:0.4),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Healthy UNAIR',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Icon(Icons.person,
                  color: AppColors.onSurfaceVariant, size: 20),
            ),
          ),
        ],
      ),
      body: favorites.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tersimpan',
                          style: AppTextStyles.headlineMediumMobile
                              .copyWith(color: AppColors.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favorites.length} fasilitas tersimpan',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final place = favorites[i];
                      return _buildFavoriteItem(place, i);
                    },
                    childCount: favorites.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildFavoriteItem(Place place, int index) {
    final color = _colorFor(place.categoryName);
    return Dismissible(
      key: ValueKey(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error, size: 28),
      ),
      onDismissed: (_) => _removeWithUndo(place),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 280 + index * 60),
        curve: Curves.easeOut,
        builder: (ctx, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)), child: child),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.outlineVariant.withValues(alpha:0.5)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
            ),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image/icon area
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_iconFor(place.categoryName),
                        color: color, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.name,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            if (place.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  place.categoryName!.split(' ').first,
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: color),
                                ),
                              ),
                          ],
                        ),
                        if (place.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            place.address!,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (place.rating != null) ...[
                              const Icon(Icons.star_rounded,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                place.rating!.toStringAsFixed(1),
                                style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.onSurfaceVariant),
                              ),
                              const SizedBox(width: 10),
                            ],
                            // Directions button
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DetailScreen(place: place)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.directions,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Arah',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _removeWithUndo(place),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.outline, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_outline,
                  size: 52, color: AppColors.outline),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada favorit',
              style: AppTextStyles.headlineMediumMobile.copyWith(
                  color: AppColors.onSurface, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk ikon ♡ pada fasilitas\nuntuk menyimpannya di sini.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}