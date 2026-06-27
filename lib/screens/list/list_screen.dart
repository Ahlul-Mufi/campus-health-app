import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/category.dart';
import '../../models/place.dart';
import '../../services/api_service.dart';
import '../../utils/distance.dart';
import '../../widgets/place_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../detail/detail_screen.dart';

class ListScreen extends StatefulWidget {
  final Category? category;
  final bool showAll;

  const ListScreen({super.key, this.category, this.showAll = false});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final ApiService _api = ApiService();
  late Future<List<Place>> _places;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _places = widget.showAll
        ? _api.getPlaces()
        : _api.getPlaces(category: widget.category!.name.toLowerCase());
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {}
  }

  double? _distanceTo(Place place) {
    if (_currentPosition == null ||
        place.latitude == null ||
        place.longitude == null) {
      return null;
    }
    return haversine(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.latitude!,
      place.longitude!,
    );
  }

  void _pushDetail(Place place) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => DetailScreen(place: place),
        transitionsBuilder: (context, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F1),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D631B),
          ),
          child: AppBar(
            title: Text(
              widget.showAll ? 'Semua Fasilitas' : widget.category!.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: FutureBuilder<List<Place>>(
        future: _places,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 5,
              itemBuilder: (ctx, i) => const ShimmerLoading(
                height: 88,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                borderRadius: 14,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 48, color: Color(0xFFBDEFBE)),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF40493D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final places = snapshot.data!;
          if (places.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 48, color: const Color(0xFFBFCABA)),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada tempat di kategori ini',
                    style: TextStyle(fontSize: 16, color: const Color(0xFF40493D)),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 350 + (index * 80)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: PlaceCard(
                  place: place,
                  distance: _distanceTo(place),
                  onTap: () => _pushDetail(place),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
