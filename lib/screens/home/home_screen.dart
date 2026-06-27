import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/category.dart';
import '../../models/place.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/distance.dart';
import '../../widgets/facility_card.dart';
import '../../widgets/place_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../list/list_screen.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Place>> _allPlacesFuture;
  Position? _position;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _api.getCategories();
    _allPlacesFuture = _api.getPlaces();
    _getLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _position = pos);
    } catch (_) {}
  }

  double? _distanceTo(Place p) {
    if (_position == null || p.latitude == null || p.longitude == null) {
      return null;
    }
    return haversine(_position!.latitude, _position!.longitude,
        p.latitude!, p.longitude!);
  }

  IconData _iconFor(String name) {
    switch (name.toLowerCase()) {
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

  Color _colorFor(String name) {
    switch (name.toLowerCase()) {
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

  void _pushDetail(Place p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DetailScreen(place: p)));
  }

  void _pushList(Category cat) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ListScreen(category: cat)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: AppColors.outlineVariant.withValues(alpha: 0.5),
            toolbarHeight: 64,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ─────────────────────────────────
                  Text('Halo, Mahasiswa! 👋',
                      style: AppTextStyles.headlineMediumMobile
                          .copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan fasilitas kesehatan terdekat.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // ── Search Bar ───────────────────────────────
                  SearchBar(
                    controller: _searchController,
                    hintText: 'Cari fasilitas, dokter...',
                    leading: const Icon(Icons.search,
                        color: AppColors.onSurfaceVariant),
                    backgroundColor:
                        WidgetStateProperty.all(AppColors.surfaceContainerLow),
                    shadowColor: WidgetStateProperty.all(Colors.transparent),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                    padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16)),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── If searching ────────────────────────────────────
          if (_searchQuery.isNotEmpty)
            _buildSearchResults()
          else ...[
            // ── Categories ───────────────────────────────────
            _buildSectionHeader('Kategori'),
            _buildCategories(),

            // ── Nearby ──────────────────────────────────────
            _buildSectionHeader('Fasilitas Terdekat'),
            _buildNearbyHorizontal(),

            // ── Recommended ─────────────────────────────────
            _buildSectionHeader('Rekomendasi untuk Kamu'),
            _buildRecommended(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Text(title,
            style: AppTextStyles.titleLarge
                .copyWith(color: AppColors.onSurface, fontSize: 18)),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) =>
                    const ShimmerLoading(width: 90, height: 90, borderRadius: 20),
              ),
            );
          }
          final cats = snap.data ?? [];
          return SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final cat = cats[i];
                final color = _colorFor(cat.name);
                return GestureDetector(
                  onTap: () => _pushList(cat),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconFor(cat.name), color: color, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          cat.name.split(' ').first,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: color, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyHorizontal() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Place>>(
        future: _allPlacesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 185,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) =>
                    const ShimmerLoading(width: 220, height: 185, borderRadius: 20),
              ),
            );
          }
          final places = snap.data ?? [];
          List<Place> sorted = [...places];
          if (_position != null) {
            sorted.sort((a, b) {
              final da = _distanceTo(a) ?? 999;
              final db = _distanceTo(b) ?? 999;
              return da.compareTo(db);
            });
          }
          final nearby = sorted.take(5).toList();
          return SizedBox(
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: nearby.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => FacilityCard(
                place: nearby[i],
                distance: _distanceTo(nearby[i]),
                onTap: () => _pushDetail(nearby[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommended() {
    return FutureBuilder<List<Place>>(
      future: _allPlacesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const ShimmerLoading(
                height: 88,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                borderRadius: 20,
              ),
              childCount: 3,
            ),
          );
        }
        final places = (snap.data ?? [])
            .where((p) => p.rating != null && p.rating! >= 4.0)
            .take(5)
            .toList();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + i * 80),
              curve: Curves.easeOut,
              builder: (ctx, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)), child: child),
              ),
              child: PlaceCard(
                place: places[i],
                distance: _distanceTo(places[i]),
                onTap: () => _pushDetail(places[i]),
              ),
            ),
            childCount: places.length,
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Place>>(
      future: _allPlacesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const ShimmerLoading(
                height: 88,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                borderRadius: 20,
              ),
              childCount: 4,
            ),
          );
        }
        final q = _searchQuery.toLowerCase();
        final results = (snap.data ?? []).where((p) {
          return p.name.toLowerCase().contains(q) ||
              (p.address?.toLowerCase().contains(q) ?? false) ||
              (p.categoryName?.toLowerCase().contains(q) ?? false);
        }).toList();

        if (results.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: AppColors.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Tidak ditemukan',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Coba kata kunci lain',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.outline)),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => PlaceCard(
              place: results[i],
              distance: _distanceTo(results[i]),
              onTap: () => _pushDetail(results[i]),
            ),
            childCount: results.length,
          ),
        );
      },
    );
  }
}