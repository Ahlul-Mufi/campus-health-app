import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _routeSteps = [];
  double? _routeDistance;
  double? _routeDuration;
  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  bool _showRoute = false;
  bool _isNavigating = false;
  int _currentStepIndex = 0;
  double _distToNextTurn = 0;
  String? _lastSpokenInstruction;
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
    _tts.setLanguage('id-ID');
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
          if (!mounted) return;
          setState(() => _currentPosition = pos);
          if (_isNavigating) {
            _updateNavigationStep(pos);
            final zoom = _autoZoom(pos.speed);
            _mapController.move(
              LatLng(pos.latitude, pos.longitude), zoom,
            );
          }
        });
  }

  double _autoZoom(double speedMps) {
    final speedKmh = speedMps * 3.6;
    if (speedKmh < 3) return 18;
    if (speedKmh < 10) return 17;
    if (speedKmh < 20) return 16;
    if (speedKmh < 40) return 15;
    return 14;
  }

  void _updateNavigationStep(Position pos) {
    if (_routePoints.isEmpty || _routeSteps.isEmpty) return;
    final current = LatLng(pos.latitude, pos.longitude);

    int closest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < _routePoints.length; i++) {
      final d = _distanceBetween(current, _routePoints[i]);
      if (d < minDist) {
        minDist = d;
        closest = i;
      }
    }

    int newStep = 0;
    for (int i = 0; i < _routeSteps.length; i++) {
      final wp = _routeSteps[i]['way_points'] as List<int>;
      if (wp.isNotEmpty && closest >= wp[0]) {
        newStep = i;
      }
    }

    final nextStep = newStep + 1 < _routeSteps.length
        ? _routeSteps[newStep + 1]
        : null;
    if (nextStep != null) {
      final wp = nextStep['way_points'] as List<int>;
      if (wp.length >= 2) {
        final idx = wp[0].clamp(0, _routePoints.length - 1);
        _distToNextTurn = _distanceBetween(current, _routePoints[idx]);
      }
    } else {
      _distToNextTurn = _distanceBetween(
        current,
        LatLng(widget.place.latitude!, widget.place.longitude!),
      );
    }

    if (newStep != _currentStepIndex) {
      setState(() => _currentStepIndex = newStep);
      _speakStep(_routeSteps[newStep]);
    }
  }

  Future<void> _speakStep(Map<String, dynamic> step) async {
    final instruction = step['instruction'] as String? ?? '';
    if (instruction.isEmpty || instruction == _lastSpokenInstruction) return;
    _lastSpokenInstruction = instruction;
    try {
      await _tts.speak(instruction);
    } catch (_) {}
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const r = 6371000;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLon = math.sin(dLon / 2);
    final x = sinDLat * sinDLat +
        math.cos(a.latitude * math.pi / 180) *
        math.cos(b.latitude * math.pi / 180) *
        sinDLon * sinDLon;
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tts.stop();
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

        final steps = (segment['steps'] as List?)?.map((s) => {
          'instruction': s['instruction'] as String? ?? '',
          'distance': (s['distance'] as num?)?.toDouble() ?? 0.0,
          'duration': (s['duration'] as num?)?.toDouble() ?? 0.0,
          'name': s['name'] as String? ?? '',
          'type': s['type'] as int? ?? 0,
          'way_points': List<int>.from(s['way_points'] as List? ?? []),
        }).toList() ?? [];

        setState(() {
          _routePoints = points;
          _routeSteps = steps;
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
      _routeSteps = [];
      _routeDistance = null;
      _routeDuration = null;
      _isNavigating = false;
    });
    _getRoute();
  }

  void _openNavigation() {
    if (_routeSteps.isEmpty) return;
    _lastSpokenInstruction = null;
    _tts.stop();
    setState(() {
      _isNavigating = true;
      _showRoute = true;
      _currentStepIndex = 0;
      _distToNextTurn = 0;
    });
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        17,
      );
    }
    if (_routeSteps.isNotEmpty) {
      _speakStep(_routeSteps[0]);
    }
  }

  void _showAllSteps() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F1),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12 * _scale),
                width: 40 * _scale,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * _scale),
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: const Color(0xFF0D631B), size: 24 * _scale),
                    SizedBox(width: 10 * _scale),
                    Text(
                      'Panduan Rute',
                      style: TextStyle(
                        fontSize: 18 * _scale,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B1C17),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_routeSteps.length} langkah',
                      style: TextStyle(
                        fontSize: 13 * _scale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8 * _scale),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * _scale,
                    vertical: 12 * _scale,
                  ),
                  itemCount: _routeSteps.length,
                  itemBuilder: (_, i) {
                    final step = _routeSteps[i];
                    final isLast = i == _routeSteps.length - 1;
                    return _buildStepItem(step, i, isLast);
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20 * _scale, 8 * _scale, 20 * _scale, 12 * _scale,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        'Tutup',
                        style: TextStyle(fontSize: 14 * _scale, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D631B),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 13 * _scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(Map<String, dynamic> step, int index, bool isLast) {
    final icon = _stepIcon(step['type'] as int);
    final instruction = step['instruction'] as String;
    final distance = _formatDistance(step['distance'] as double);
    final name = step['name'] as String;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32 * _scale,
            child: Column(
              children: [
                Container(
                  width: 28 * _scale,
                  height: 28 * _scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D631B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16 * _scale, color: const Color(0xFF0D631B)),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFF0D631B).withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12 * _scale),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20 * _scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 14 * _scale,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B1C17),
                    ),
                  ),
                  SizedBox(height: 4 * _scale),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 14 * _scale, color: Colors.grey[500]),
                      SizedBox(width: 4 * _scale),
                      Text(
                        distance,
                        style: TextStyle(fontSize: 12 * _scale, color: Colors.grey[600]),
                      ),
                      if (name.isNotEmpty) ...[
                        SizedBox(width: 12 * _scale),
                        Icon(Icons.signpost, size: 14 * _scale, color: Colors.grey[500]),
                        SizedBox(width: 4 * _scale),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(fontSize: 12 * _scale, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _stepIcon(int type) {
    switch (type) {
      case 0:
      case 1:
        return Icons.turn_right;
      case 2:
        return Icons.turn_left;
      case 3:
        return Icons.arrow_right_alt;
      case 4:
        return Icons.turn_right;
      case 5:
        return Icons.u_turn_left;
      case 6:
        return Icons.arrow_right_alt;
      case 7:
        return Icons.arrow_right_alt;
      case 8:
        return Icons.arrow_right_alt;
      case 9:
        return Icons.trip_origin;
      case 10:
        return Icons.flag;
      case 11:
        return Icons.arrow_upward;
      case 12:
        return Icons.arrow_downward;
      case 13:
        return Icons.circle;
      case 14:
        return Icons.arrow_right_alt;
      default:
        return Icons.navigation;
    }
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

  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _scale => (_screenWidth / 375).clamp(0.8, 1.4);

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
            width: _isNavigating ? 36 * _scale : 32 * _scale,
            height: _isNavigating ? 36 * _scale : 32 * _scale,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0D631B),
                width: _isNavigating ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.navigation,
              color: const Color(0xFF0D631B),
              size: _isNavigating ? 20 * _scale : 16 * _scale,
            ),
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
            child: const Icon(Icons.location_on, color: Color(0xFF0D631B), size: 26),
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
                color: const Color(0xFF0D631B),
                strokeWidth: 5,
              ),
            ],
          ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F1),
      appBar: _showRoute
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D631B),
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
            height: 260 * _scale.clamp(0.85, 1.25),
            child: Stack(
              children: [
                mapWidget,
                Positioned(
                  right: 16 * _scale.clamp(1.0, 1.0),
                  bottom: 16 * _scale.clamp(1.0, 1.0),
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
                        child: Icon(Icons.my_location, size: 20 * _scale),
                      ),
                      SizedBox(height: 8 * _scale),
                      FloatingActionButton.small(
                        heroTag: 'route',
                        backgroundColor: const Color(0xFF0D631B),
                        onPressed: _isLoadingRoute ? null : _getRoute,
                        child: _isLoadingRoute
                            ? SizedBox(
                                width: 20 * _scale,
                                height: 20 * _scale,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2 * _scale.clamp(1.0, 1.0),
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.route, color: Colors.white, size: 20 * _scale),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D631B)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20 * _scale.clamp(1.0, 1.0),
              20 * _scale,
              20 * _scale.clamp(1.0, 1.0),
              32 * _scale,
            ),
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
                          color: Color(0xFF1B1C17),
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
                                color: Color(0xFF1B1C17),
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
                      color: const Color(0xFFBDEFBE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.place.categoryName!,
                      style: const TextStyle(
                        color: Color(0xFF426E47),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openNavigation,
                      icon: Icon(Icons.navigation, size: 18 * _scale),
                      label: Text(
                        'Mulai Rute',
                        style: TextStyle(fontSize: 14 * _scale, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D631B),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 13 * _scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * _scale.clamp(1.0, 1.0)),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
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
                      color: Color(0xFF1B1C17),
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
                        color: const Color(0xFF40493D),
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
                        ? SizedBox(
                            width: 20 * _scale,
                            height: 20 * _scale,
                            child: CircularProgressIndicator(
                              strokeWidth: 2 * _scale.clamp(1.0, 1.0),
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.route, size: 20 * _scale),
                    label: Text(
                      _isLoadingRoute ? 'Memuat Rute...' : 'Lihat Rute',
                      style: TextStyle(fontSize: 15 * _scale),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D631B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFBDEFBE),
                      disabledForegroundColor: const Color(0xFF426E47),
                      padding: EdgeInsets.symmetric(vertical: 15 * _scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * _scale.clamp(1.0, 1.0)),
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
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8 * _scale),
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
                    icon: Icon(Icons.arrow_back, size: 22 * _scale),
                    onPressed: () => setState(() {
                      _showRoute = false;
                      _isNavigating = false;
                    }),
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
                                style: TextStyle(fontSize: 12 * _scale),
                              ),
                              selected: selected,
                              selectedColor: const Color(0xFF0D631B),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              onSelected: (_) => _onTransportChanged(label),
                              padding: EdgeInsets.symmetric(
                                horizontal: 4 * _scale,
                                vertical: 2 * _scale,
                              ),
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
              child: _isNavigating
                  ? _buildNavigationCard()
                  : Container(
                      margin: EdgeInsets.all(16 * _scale.clamp(1.0, 1.0)),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * _scale,
                        vertical: 14 * _scale,
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
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _routeInfoChip(
                                Icons.route,
                                _formatDistance(_routeDistance!),
                              ),
                              const SizedBox(width: 12),
                              _routeInfoChip(
                                Icons.access_time,
                                _formatDuration(_routeDuration!),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 36 * _scale.clamp(1.0, 1.2),
                                child: ElevatedButton.icon(
                                  onPressed: _openNavigation,
                                  icon: Icon(Icons.navigation, size: 16 * _scale),
                                  label: FittedBox(
                                    child: Text(
                                      'Mulai Rute',
                                      style: TextStyle(fontSize: 12 * _scale, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D631B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 12 * _scale),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D631B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.close, color: const Color(0xFF0D631B), size: 20 * _scale),
                                  constraints: BoxConstraints(
                                    minWidth: 36 * _scale.clamp(1.0, 1.2),
                                    minHeight: 36 * _scale.clamp(1.0, 1.2),
                                  ),
                                  padding: EdgeInsets.all(8 * _scale),
                                  onPressed: () => setState(() {
                                    _showRoute = false;
                                    _isNavigating = false;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        Positioned(
          right: 16 * _scale.clamp(1.0, 1.0),
          bottom: (_routeDistance != null
              ? (_isNavigating ? 260 : 180)
              : 40) * _scale.clamp(1.0, 1.0),
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                onPressed: _zoomIn,
                child: Icon(Icons.add, size: 20 * _scale),
              ),
              SizedBox(height: 8 * _scale),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                onPressed: _zoomOut,
                child: Icon(Icons.remove, size: 20 * _scale),
              ),
              SizedBox(height: 8 * _scale),
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
                child: Icon(Icons.my_location, size: 20 * _scale),
              ),
            ],
          ),
        ),
        if (_isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF0D631B)),
          ),
      ],
    );
  }

  Widget _buildNavigationCard() {
    final currentStep = _currentStepIndex < _routeSteps.length
        ? _routeSteps[_currentStepIndex]
        : null;
    final nextStep = _currentStepIndex + 1 < _routeSteps.length
        ? _routeSteps[_currentStepIndex + 1]
        : null;
    final instruction = currentStep?['instruction'] as String? ?? 'Sampai tujuan';
    final nextName = nextStep?['name'] as String? ?? '';
    final stepDistance = currentStep?['distance'] as double? ?? 0;
    final remainingTime = _formatDuration(_routeDuration ?? 0);
    final stepDist = _formatDistance(stepDistance);
    final turnDist = _formatDistance(_distToNextTurn);

    final now = DateTime.now();
    final etaSeconds = (_routeDuration ?? 0) - (_routeDuration ?? 0) * 0;
    final eta = DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + (etaSeconds * 1000).toInt(),
    );
    final etaStr =
        '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';

    final progress = _routeDistance != null && _routeDistance! > 0
        ? (1 - (_routeDuration! / _routeDistance!)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.all(12 * _scale.clamp(1.0, 1.0)),
      padding: EdgeInsets.symmetric(
        horizontal: 16 * _scale,
        vertical: 14 * _scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8 * _scale),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D631B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _stepIcon(currentStep?['type'] as int? ?? 0),
                  color: Colors.white,
                  size: 22 * _scale,
                ),
              ),
              SizedBox(width: 12 * _scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction,
                      style: TextStyle(
                        fontSize: 16 * _scale,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C17),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nextName.isNotEmpty) ...[
                      SizedBox(height: 2 * _scale),
                      Text(
                        nextName,
                        style: TextStyle(
                          fontSize: 13 * _scale,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    etaStr,
                    style: TextStyle(
                      fontSize: 20 * _scale,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1C17),
                    ),
                  ),
                  Text(
                    'Sampai',
                    style: TextStyle(
                      fontSize: 11 * _scale,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12 * _scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE8E5DC),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D631B)),
              minHeight: 5,
            ),
          ),
          SizedBox(height: 10 * _scale),
          Row(
            children: [
              Icon(Icons.turn_slight_right, size: 14 * _scale, color: Colors.grey[600]),
              SizedBox(width: 4 * _scale),
              Text(
                'Belok $turnDist lagi',
                style: TextStyle(fontSize: 12 * _scale, color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 14 * _scale, color: Colors.grey[600]),
              SizedBox(width: 4 * _scale),
              Text(
                remainingTime,
                style: TextStyle(fontSize: 12 * _scale, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12 * _scale),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36 * _scale.clamp(1.0, 1.2),
                  child: OutlinedButton.icon(
                    onPressed: _showAllSteps,
                    icon: Icon(Icons.list, size: 16 * _scale),
                    label: FittedBox(
                      child: Text(
                        '$stepDist (${_routeSteps.length} langkah)',
                        style: TextStyle(fontSize: 11 * _scale, fontWeight: FontWeight.w600),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D631B),
                      side: const BorderSide(color: Color(0xFF0D631B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8 * _scale),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * _scale),
              Expanded(
                child: SizedBox(
                  height: 36 * _scale.clamp(1.0, 1.2),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _tts.stop();
                      setState(() {
                        _isNavigating = false;
                        _showRoute = false;
                      });
                    },
                    icon: Icon(Icons.stop_circle_outlined, size: 16 * _scale),
                    label: FittedBox(
                      child: Text(
                        'Berhenti',
                        style: TextStyle(fontSize: 12 * _scale, fontWeight: FontWeight.w600),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12 * _scale),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openingHoursWidget() {
    final hours = widget.place.openingHours!;
    final is24h = hours.trim() == '24 Jam';
    final lines = hours.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: 12 * _scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * _scale),
            decoration: BoxDecoration(
              color: const Color(0xFF0D631B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.access_time, color: const Color(0xFF0D631B), size: 20 * _scale),
          ),
          SizedBox(width: 14 * _scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jam Buka',
                  style: TextStyle(
                    fontSize: 12 * _scale,
                    color: const Color(0xFF40493D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6 * _scale),
                if (is24h)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * _scale, vertical: 4 * _scale),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D631B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14 * _scale, color: const Color(0xFF0D631B)),
                        SizedBox(width: 4 * _scale),
                        Text(
                          'Buka 24 Jam',
                          style: TextStyle(
                            fontSize: 14 * _scale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0D631B),
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
                      padding: EdgeInsets.only(bottom: 3 * _scale),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80 * _scale,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14 * _scale,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? const Color(0xFF1B1C17)
                                    : const Color(0xFF40493D),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 14 * _scale,
                                color: isToday
                                    ? const Color(0xFF1B1C17)
                                    : const Color(0xFF40493D),
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
      padding: EdgeInsets.symmetric(horizontal: 12 * _scale, vertical: 7 * _scale),
      decoration: BoxDecoration(
        color: const Color(0xFF0D631B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16 * _scale, color: const Color(0xFF0D631B)),
          SizedBox(width: 6 * _scale),
          Text(
            text,
            style: TextStyle(
              fontSize: 13 * _scale,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B1C17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * _scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * _scale),
            decoration: BoxDecoration(
              color: const Color(0xFF0D631B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0D631B), size: 20 * _scale),
          ),
          SizedBox(width: 14 * _scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12 * _scale,
                    color: const Color(0xFF40493D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2 * _scale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15 * _scale,
                    color: const Color(0xFF1B1C17),
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
