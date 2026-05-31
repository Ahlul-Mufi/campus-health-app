import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/place.dart';
import '../../config.dart';

class DetailScreen extends StatefulWidget {
  final Place place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;
  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  bool _showRoute = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null ||
        widget.place.latitude == null ||
        widget.place.longitude == null) {
      return;
    }

    setState(() => _isLoadingRoute = true);

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?api_key=${Config.orsApiKey}'
      '&start=${_currentPosition!.longitude},${_currentPosition!.latitude}'
      '&end=${widget.place.longitude},${widget.place.latitude}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final feature = data['features'][0];
        final coords = feature['geometry']['coordinates'] as List;
        final points = coords.map((c) => LatLng(c[1], c[0])).toList();
        final segment = feature['properties']['segments'][0];

        setState(() {
          _routePoints = points;
          _routeDistance = (segment['distance'] as num).toDouble();
          _routeDuration = (segment['duration'] as num).toDouble();
          _showRoute = true;
          _isLoadingRoute = false;
        });

        _fitBounds();
      } else {
        throw Exception('ORS error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat rute: $e')),
        );
      }
    }
  }

  void _fitBounds() {
    final latlngs = <LatLng>[];
    if (_currentPosition != null) {
      latlngs.add(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    }
    if (widget.place.latitude != null && widget.place.longitude != null) {
      latlngs.add(LatLng(widget.place.latitude!, widget.place.longitude!));
    }
    if (latlngs.length < 2) return;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(latlngs),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(double seconds) {
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).round();
    if (h > 0) return '$h jam $m menit';
    return '$m menit';
  }

  @override
  Widget build(BuildContext context) {
    final hasCoord =
        widget.place.latitude != null && widget.place.longitude != null;

    final markers = <Marker>[];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.green, size: 22),
          ),
        ),
      );
    }
    if (hasCoord) {
      markers.add(
        Marker(
          point: LatLng(widget.place.latitude!, widget.place.longitude!),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.red, size: 26),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF96B6C5), Color(0xFFADC4CE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text(
              widget.place.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 18, overflow: TextOverflow.ellipsis),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: hasCoord
                          ? LatLng(
                              widget.place.latitude!, widget.place.longitude!)
                          : const LatLng(-6.2088, 106.8456),
                      initialZoom: 13,
                      onMapReady: () {
                        if (_currentPosition != null) _fitBounds();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.campus.health',
                      ),
                      MarkerLayer(markers: markers),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: const Color(0xFF96B6C5),
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'location',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (_currentPosition != null) {
                              _mapController.move(
                                LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                                15,
                              );
                            }
                          },
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'route',
                          backgroundColor: const Color(0xFF96B6C5),
                          onPressed: _isLoadingRoute ? null : _getRoute,
                          child: _isLoadingRoute
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.route, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingLocation)
                    const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF96B6C5)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.place.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      if (widget.place.rating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                widget.place.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF222222),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (widget.place.categoryName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFADC4CE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.place.categoryName!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                  if (_routeDistance != null && _routeDuration != null) ...[
                    const SizedBox(height: 20),
                    _animatedInfo(),
                  ],
                  const SizedBox(height: 20),
                  if (widget.place.address != null)
                    _infoTile(Icons.location_on, 'Alamat', widget.place.address!),
                  if (widget.place.phone != null)
                    _infoTile(Icons.phone, 'Telepon', widget.place.phone!),
                  if (widget.place.description != null &&
                      widget.place.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.place.description!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _currentPosition != null && hasCoord && !_isLoadingRoute
                              ? _getRoute
                              : null,
                      icon: _isLoadingRoute
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.route),
                      label: Text(
                        _isLoadingRoute
                            ? 'Memuat Rute...'
                            : _showRoute
                                ? 'Perbarui Rute'
                                : 'Lihat Rute',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF96B6C5),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFADC4CE),
                        disabledForegroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animatedInfo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          _routeInfoChip(Icons.route, _formatDistance(_routeDistance!)),
          const SizedBox(width: 12),
          _routeInfoChip(Icons.access_time, _formatDuration(_routeDuration!)),
        ],
      ),
    );
  }

  Widget _routeInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF96B6C5).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF96B6C5)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF96B6C5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF96B6C5), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
