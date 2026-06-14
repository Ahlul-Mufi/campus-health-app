import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/place.dart';
import '../../services/api_service.dart';
import '../detail/detail_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  List<Place> _places = [];
  List<Place> _filtered = [];
  Place? _selected;
  String _activeFilter = 'All';
  Position? _myPosition;
  bool _loading = true;
  StreamSubscription<Position>? _posSub;

  final List<String> _filters = ['All', 'Rumah Sakit', 'Klinik', 'Puskesmas'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _getLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final places = await _api.getPlaces();
      if (mounted) {
        setState(() {
          _places = places;
          _filtered = places;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      final perm = await Geolocator.checkPermission().then((p) async {
        if (p == LocationPermission.denied) return Geolocator.requestPermission();
        return p;
      });
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _myPosition = pos);
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((p) {
        if (mounted) setState(() => _myPosition = p);
      });
    } catch (_) {}
  }

  void _applyFilter(String f) {
    setState(() {
      _activeFilter = f;
      _selected = null;
      if (f == 'All') {
        _filtered = _places;
      } else {
        _filtered = _places
            .where((p) =>
                (p.categoryName ?? '').toLowerCase() == f.toLowerCase())
            .toList();
      }
    });
  }

  void _goToMyLocation() {
    if (_myPosition != null) {
      _mapController.move(
        LatLng(_myPosition!.latitude, _myPosition!.longitude),
        15,
      );
    }
  }

  IconData _iconForCategory(String? name) {
    switch ((name ?? '').toLowerCase()) {
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

  Color _colorForCategory(String? name) {
    switch ((name ?? '').toLowerCase()) {
      case 'rumah sakit':
        return const Color(0xFF0D631B);
      case 'klinik':
        return const Color(0xFF3C6842);
      case 'puskesmas':
        return const Color(0xFF4D5950);
      default:
        return const Color(0xFF0D631B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // My location
      if (_myPosition != null)
        Marker(
          point: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0D631B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D631B).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      // Facility markers
      ..._filtered
          .where((p) => p.latitude != null && p.longitude != null)
          .map(
            (p) => Marker(
              point: LatLng(p.latitude!, p.longitude!),
              child: GestureDetector(
                onTap: () => setState(() => _selected = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selected?.id == p.id
                              ? _colorForCategory(p.categoryName)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorForCategory(p.categoryName),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForCategory(p.categoryName),
                          size: 18,
                          color: _selected?.id == p.id
                              ? Colors.white
                              : _colorForCategory(p.categoryName),
                        ),
                      ),
                      if (_selected?.id == p.id)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _colorForCategory(p.categoryName),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.2756, 112.7752), // Surabaya UNAIR
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, _) => setState(() => _selected = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.healthy.unair',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top bar + filter chips
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded,
                            color: Color(0xFF0D631B), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Healthy UNAIR',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D631B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE8E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 20, color: Color(0xFF40493D)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _filters[i];
                        final active = f == _activeFilter;
                        return GestureDetector(
                          onTap: () => _applyFilter(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF0D631B)
                                  : Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF0D631B)
                                    : const Color(0xFFBFCABA),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF40493D),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAB buttons
          Positioned(
            right: 16,
            bottom: _selected != null ? 220 : 32,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.my_location_rounded,
                  color: const Color(0xFF0D631B),
                  onTap: _goToMyLocation,
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: Icons.add_rounded,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, (zoom + 1).clamp(3, 19));
                  },
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(
                        _mapController.camera.center, (zoom - 1).clamp(3, 19));
                  },
                ),
              ],
            ),
          ),

          // Loading
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D631B)),
            ),

          // Bottom sheet — selected place
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _SelectedPlaceSheet(
                place: _selected!,
                onDirections: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(place: _selected!),
                  ),
                ),
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── FAB ────────────────────────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _MapFab({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color ?? const Color(0xFF40493D), size: 22),
      ),
    );
  }
}

// ── Selected place bottom sheet ────────────────────────────────────────────────

class _SelectedPlaceSheet extends StatelessWidget {
  final Place place;
  final VoidCallback onDirections;
  final VoidCallback onClose;

  const _SelectedPlaceSheet({
    required this.place,
    required this.onDirections,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBFCABA),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDEFBE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_hospital_rounded,
                        size: 40, color: Color(0xFF0D631B)),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B1C17),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (place.address != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 13, color: Color(0xFF40493D)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                place.address!,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF40493D)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (place.openingHours?.trim() == '24 Jam')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA3F69C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Open 24h',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF002204),
                                ),
                              ),
                            ),
                          if (place.rating != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star_rounded,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B1C17),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFF40493D)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDirections,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D631B),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBDEFBE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: Color(0xFF426E47), size: 22),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}