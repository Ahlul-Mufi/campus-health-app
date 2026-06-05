import 'dart:async';
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
  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  double? _routeDuration;
  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  bool _showRoute = false;
  String _selectedTransport = 'Jalan Kaki';

  static const Map<String, String> transportProfiles = {
    'Jalan Kaki': 'foot-walking',
    'Motor': 'driving-car',
    'Mobil': 'driving-car',
  };

  List<String> get _transportLabels => transportProfiles.keys.toList();

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
      _startPositionStream();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _startPositionStream() {
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) {
          if (mounted) setState(() => _currentPosition = pos);
        });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getRoute() async {
    if (_currentPosition == null ||
        widget.place.latitude == null ||
        widget.place.longitude == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _showRoute = true;
    });

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/${transportProfiles[_selectedTransport]}'
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
          _isLoadingRoute = false;
        });

        _fitBounds();
      } else {
        throw Exception('ORS error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat rute: $e')));
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds.fromPoints(latlngs);
      final center = bounds.center;
      final maxDelta = [
        (bounds.north - bounds.south).abs(),
        (bounds.east - bounds.west).abs(),
      ].reduce((a, b) => a > b ? a : b);

      double zoom;
      if (maxDelta > 0.5) {
        zoom = 10;
      } else if (maxDelta > 0.1) {
        zoom = 12;
      } else if (maxDelta > 0.05) {
        zoom = 13;
      } else if (maxDelta > 0.02) {
        zoom = 14;
      } else if (maxDelta > 0.01) {
        zoom = 15;
      } else {
        zoom = 16;
      }

      _mapController.move(center, zoom);
    });
  }

  void _zoomIn() {
    final zoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (zoom + 1).clamp(3, 19));
  }

  void _zoomOut() {
    final zoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (zoom - 1).clamp(3, 19));
  }

  void _onTransportChanged(String label) {
    if (_selectedTransport == label) return;
    setState(() {
      _selectedTransport = label;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });
    _getRoute();
  }

  bool _isToday(String day) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    if (todayIndex < 0 || todayIndex >= days.length) return false;
    return day.toLowerCase() == days[todayIndex].toLowerCase();
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
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
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
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.red, size: 26),
          ),
        ),
      );
    }

    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: hasCoord
            ? LatLng(widget.place.latitude!, widget.place.longitude!)
            : const LatLng(-6.2088, 106.8456),
        initialZoom: 13,
        minZoom: 3,
        maxZoom: 19,
        onMapReady: () {
          if (_currentPosition != null) _fitBounds();
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F0E8),
      appBar: _showRoute
          ? null
          : PreferredSize(
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
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
      body: _showRoute
          ? _buildFullscreenMap(mapWidget)
          : _buildDetailView(mapWidget, hasCoord),
    );
  }

  Widget _buildDetailView(Widget mapWidget, bool hasCoord) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                mapWidget,
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
                              LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.route, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF96B6C5)),
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
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
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFADC4CE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.place.categoryName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_routeDistance != null &&
                    _routeDuration != null &&
                    !_showRoute) ...[
                  const SizedBox(height: 20),
                  _animatedInfo(),
                ],
                const SizedBox(height: 20),
                if (widget.place.address != null)
                  _infoTile(Icons.location_on, 'Alamat', widget.place.address!),
                if (_currentPosition != null)
                  _infoTile(
                    Icons.map,
                    'Posisi Saya',
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  ),
                if (widget.place.phone != null)
                  _infoTile(Icons.phone, 'Telepon', widget.place.phone!),
                if (widget.place.openingHours != null)
                  _openingHoursWidget(),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.route),
                    label: Text(
                      _isLoadingRoute ? 'Memuat Rute...' : 'Lihat Rute',
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
    );
  }

  Widget _buildFullscreenMap(Widget mapWidget) {
    return Stack(
      children: [
        mapWidget,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showRoute = false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _transportLabels.map((label) {
                          final selected = label == _selectedTransport;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                label,
                                style: const TextStyle(fontSize: 13),
                              ),
                              selected: selected,
                              selectedColor: const Color(0xFF96B6C5),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) => _onTransportChanged(label),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_routeDistance != null && _routeDuration != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _routeInfoChip(
                      Icons.route,
                      _formatDistance(_routeDistance!),
                    ),
                    const SizedBox(width: 16),
                    _routeInfoChip(
                      Icons.access_time,
                      _formatDuration(_routeDuration!),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF96B6C5).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF96B6C5)),
                        onPressed: () => setState(() => _showRoute = false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: _routeDistance != null ? 120 : 40,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                onPressed: _zoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                onPressed: _zoomOut,
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'location_full',
                backgroundColor: Colors.white,
                onPressed: () {
                  if (_currentPosition != null) {
                    _mapController.move(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      15,
                    );
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        if (_isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF96B6C5)),
          ),
      ],
    );
  }

  Widget _openingHoursWidget() {
    final hours = widget.place.openingHours!;
    final is24h = hours.trim() == '24 Jam';
    final lines = hours.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

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
            child: const Icon(Icons.access_time, color: Color(0xFF96B6C5), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jam Buka',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                if (is24h)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Buka 24 Jam',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...lines.map((line) {
                    final parts = line.split(' ');
                    final day = parts.isNotEmpty ? parts[0] : '';
                    final time = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                    final isToday = _isToday(day);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? const Color(0xFF222222)
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 14,
                                color: isToday
                                    ? const Color(0xFF222222)
                                    : Colors.grey[600],
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
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
