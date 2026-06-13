import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/place.dart';
import '../../services/api_service.dart';
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<Category>> _categories;
  late Future<List<Place>> _allPlaces;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _categories = _api.getCategories();
    _allPlaces = _api.getPlaces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'rumah sakit':
        return Icons.local_hospital_rounded;
      case 'klinik':
        return Icons.medical_services_rounded;
      case 'puskesmas':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _bgForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'rumah sakit':
        return const Color(0xFF2E7D32);
      case 'klinik':
        return const Color(0xFFBDEFBE);
      case 'puskesmas':
        return const Color(0xFFD9E6DA);
      default:
        return const Color(0xFFBDEFBE);
    }
  }

  Color _fgForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'rumah sakit':
        return const Color(0xFFCBFFC2);
      case 'klinik':
        return const Color(0xFF426E47);
      case 'puskesmas':
        return const Color(0xFF3E4A41);
      default:
        return const Color(0xFF426E47);
    }
  }

  void _openDetail(Place place) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => DetailScreen(place: place),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F1),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xFFFBF9F1).withOpacity(0.95),
              elevation: 0,
              scrolledUnderElevation: 1,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDEFBE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFF0D631B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Healthy UNAIR',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D631B),
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE8E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBFCABA)),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF40493D),
                    size: 22,
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    const Text(
                      'Hello, Student!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1C17),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Find the nearest healthcare facility today.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF40493D),
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F4EB),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1B1C17),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search facilities, doctors...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF40493D),
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF40493D),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: Color(0xFF40493D), size: 20),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    FutureBuilder<List<Category>>(
                      future: _categories,
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return _CategorySkeletonRow();
                        }
                        if (snap.hasError || snap.data == null) {
                          return const SizedBox.shrink();
                        }
                        final cats = snap.data!;
                        return Row(
                          children: cats.map((cat) {
                            final bg = _bgForCategory(cat.name);
                            final fg = _fgForCategory(cat.name);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _CategoryChip(
                                  label: cat.name,
                                  icon: _iconForCategory(cat.name),
                                  bg: bg,
                                  fg: fg,
                                  onTap: () {},
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Nearby Facilities header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Facilities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B1C17),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF0D631B),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Horizontal Nearby Facilities
            SliverToBoxAdapter(
              child: FutureBuilder<List<Place>>(
                future: _allPlaces,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 240,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 3,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, __) => _FacilityCardSkeleton(),
                      ),
                    );
                  }
                  if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No facilities found'),
                    );
                  }
                  final places = snap.data!;
                  final filtered = _searchQuery.isEmpty
                      ? places
                      : places
                          .where((p) => p.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                  return SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _FacilityCard(
                        place: filtered[i],
                        onTap: () => _openDetail(filtered[i]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Recommended Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B1C17),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            FutureBuilder<List<Place>>(
              future: _allPlaces,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => const _RecommendedSkeleton(),
                      childCount: 3,
                    ),
                  );
                }
                if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final places = snap.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _RecommendedCard(
                        place: places[i],
                        onTap: () => _openDetail(places[i]),
                      ),
                    ),
                    childCount: places.length.clamp(0, 5),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Category chip ──────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Facility card (horizontal) ─────────────────────────────────────────────────

class _FacilityCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _FacilityCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFBDEFBE),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 56,
                      color: const Color(0xFF0D631B).withOpacity(0.3),
                    ),
                  ),
                  if (place.rating != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1C17),
                              ),
                            ),
                          ],
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
                    place.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B1C17),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 13, color: Color(0xFF40493D)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          place.address ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF40493D),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
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
}

// ── Recommended card ───────────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _RecommendedCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFBDEFBE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.local_hospital_rounded,
                    color: Color(0xFF0D631B), size: 36),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1C17),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.address != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: Color(0xFF40493D)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place.address!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF40493D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (place.rating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B1C17),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (place.openingHours != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 13, color: Color(0xFF0D631B)),
                        const SizedBox(width: 3),
                        Text(
                          place.openingHours!.trim() == '24 Jam'
                              ? 'Buka 24 Jam'
                              : place.openingHours!.split('\n').first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D631B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF0D631B), size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Skeletons ──────────────────────────────────────────────────────────────────

class _CategorySkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E3DA),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FacilityCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E3DA),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _RecommendedSkeleton extends StatelessWidget {
  const _RecommendedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E3DA),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}