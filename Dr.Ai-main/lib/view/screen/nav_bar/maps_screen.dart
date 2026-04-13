import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dr_ai/utils/constant/color.dart';
import 'package:dr_ai/utils/helper/extention.dart';
import 'package:dr_ai/utils/helper/location.dart';
import 'package:dr_ai/view/widget/button_loading_indicator.dart';
import 'package:dr_ai/view/widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_ai/utils/helper/scaffold_snakbar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Dio _dio = Dio();

  Position? _position;
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _hospitalList = [];
  bool _isLoading = false;
  bool _isMapReady = false;
  Map<String, dynamic>? _selectedHospital;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await LocationHelper.determineCurrentPosition(context);
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _position = position;
      _isMapReady = true;
    });
  }

  LatLng get _currentLatLng =>
      LatLng(_position!.latitude, _position!.longitude);

  Future<void> _findNearestHospitals() async {
    if (_position == null) return;
    setState(() => _isLoading = true);

    try {
      // Overpass API — completely free, no key needed
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:5000,${_position!.latitude},${_position!.longitude});
  way["amenity"="hospital"](around:5000,${_position!.latitude},${_position!.longitude});
  node["amenity"="clinic"](around:5000,${_position!.latitude},${_position!.longitude});
  node["amenity"="doctors"](around:5000,${_position!.latitude},${_position!.longitude});
);
out center;
''';

      final response = await _dio.post(
        'https://overpass-api.de/api/interpreter',
        data: query,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Accept': 'application/json'},
        ),
      );

      final elements = response.data['elements'] as List<dynamic>;
      _hospitalList = [];
      _markers = [];

      // Add current location marker
      _markers.add(_buildCurrentLocationMarker());

      for (var el in elements) {
        final lat = el['lat'] ?? el['center']?['lat'];
        final lng = el['lon'] ?? el['center']?['lon'];
        final tags = el['tags'] ?? {};
        final name = tags['name'] ?? tags['name:en'] ?? 'Hospital';
        final phone = tags['phone'] ??
            tags['contact:phone'] ??
            tags['contact:mobile'] ??
            '';

        if (lat == null || lng == null) continue;

        final double distance = Geolocator.distanceBetween(
          _position!.latitude,
          _position!.longitude,
          lat.toDouble(),
          lng.toDouble(),
        );

        final hospital = {
          'name': name,
          'lat': lat.toDouble(),
          'lng': lng.toDouble(),
          'phone': phone,
          'type': tags['amenity'] ?? 'hospital',
          'distance': distance,
          'emergency': tags['emergency'] ?? '',
          'opening_hours': tags['opening_hours'] ?? '',
        };
        _hospitalList.add(hospital);

        _markers.add(
          Marker(
            point: LatLng(lat.toDouble(), lng.toDouble()),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedHospital = hospital);
                _getRoute(LatLng(lat.toDouble(), lng.toDouble()));
                _scaffoldKey.currentState?.closeDrawer();
                _mapController.move(
                    LatLng(lat.toDouble(), lng.toDouble()), 15);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getTypeColor(tags['amenity']),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Icon(
                  _getTypeIcon(tags['amenity']),
                  color: ColorManager.white,
                  size: 20.r,
                ),
              ),
            ),
          ),
        );
      }

      // Sort by distance
      _hospitalList.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      setState(() => _isLoading = false);

      if (_hospitalList.isEmpty) {
        if (mounted) customSnackBar(context, 'No hospitals found nearby.');
      } else {
        if (mounted) _scaffoldKey.currentState?.openDrawer();
      }
    } catch (err) {
      log('Overpass error: $err');
      setState(() => _isLoading = false);
      if (mounted) {
        customSnackBar(context, 'Failed to find hospitals. Check connection.');
      }
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_position == null) return;
    try {
      // OSRM — free open source routing
      final url =
          'https://router.project-osrm.org/route/v1/driving/${_position!.longitude},${_position!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
      final response = await _dio.get(url);
      final coords = response.data['routes'][0]['geometry']['coordinates']
          as List<dynamic>;
      setState(() {
        _routePoints =
            coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
      });
    } catch (err) {
      log('Routing error: $err');
    }
  }

  Marker _buildCurrentLocationMarker() {
    return Marker(
      point: _currentLatLng,
      width: 48,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: ColorManager.green.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: ColorManager.green, width: 2),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: ColorManager.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'clinic':
        return ColorManager.darkBlue;
      case 'doctors':
        return ColorManager.orange;
      default:
        return ColorManager.error;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'clinic':
        return Icons.medical_services_rounded;
      case 'doctors':
        return Icons.person_rounded;
      default:
        return Icons.local_hospital_rounded;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Future<void> _callHospital(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _isMapReady ? _buildMap() : _buildLoadingIndicator(),
          if (_selectedHospital != null) _buildHospitalInfoCard(),
          _buildTopBar(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'hospitals',
            backgroundColor: ColorManager.green,
            onPressed: _isLoading ? null : _findNearestHospitals,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.local_hospital_rounded,
                    color: Colors.white),
          ),
          Gap(8.h),
          FloatingActionButton(
            heroTag: 'location',
            backgroundColor: ColorManager.green,
            onPressed: () {
              if (_position != null) {
                _mapController.move(_currentLatLng, 15);
              }
            },
            child: const Icon(Icons.my_location_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng,
        initialZoom: 15,
        onTap: (_, __) => setState(() => _selectedHospital = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dr_ai',
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: ColorManager.green,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: ColorManager.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Icon(Icons.menu_rounded,
                      color: ColorManager.green, size: 22.r),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: ColorManager.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: ColorManager.grey, size: 18.r),
                      Gap(8.w),
                      Text(
                        _hospitalList.isEmpty
                            ? 'Tap 🏥 to find nearby hospitals'
                            : '${_hospitalList.length} hospitals found',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: _hospitalList.isEmpty
                              ? ColorManager.grey
                              : ColorManager.green,
                          fontSize: 13.spMin,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalInfoCard() {
    final h = _selectedHospital!;
    return Positioned(
      bottom: 90.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: ColorManager.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_hospital_rounded,
                      color: ColorManager.green, size: 20.r),
                ),
                Gap(10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['name'],
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.spMin,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDistance(h['distance']),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: ColorManager.green,
                          fontSize: 12.spMin,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _selectedHospital = null;
                    _routePoints = [];
                  }),
                  icon: const Icon(Icons.close_rounded),
                  color: ColorManager.grey,
                ),
              ],
            ),
            if (h['phone'].toString().isNotEmpty) ...[
              Gap(10.h),
              GestureDetector(
                onTap: () => _callHospital(h['phone']),
                child: Row(
                  children: [
                    Icon(Icons.phone_rounded,
                        color: ColorManager.green, size: 16.r),
                    Gap(6.w),
                    Text(
                      h['phone'],
                      style: context.textTheme.bodySmall?.copyWith(
                        color: ColorManager.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.spMin,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_routePoints.isNotEmpty) ...[
              Gap(10.h),
              Row(
                children: [
                  Icon(Icons.directions_rounded,
                      color: ColorManager.darkBlue, size: 16.r),
                  Gap(6.w),
                  Text(
                    'Route shown on map',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: ColorManager.darkBlue,
                      fontSize: 12.spMin,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return SafeArea(
      child: Drawer(
        width: context.width * 0.78,
        backgroundColor: ColorManager.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
              color: ColorManager.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nearby Hospitals',
                    style: context.textTheme.displayLarge?.copyWith(
                      color: ColorManager.white,
                      fontSize: 16.spMin,
                    ),
                  ),
                  Text(
                    '${_hospitalList.length} found within 5km',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: ColorManager.white.withOpacity(0.85),
                      fontSize: 12.spMin,
                    ),
                  ),
                ],
              ),
            ),
            _hospitalList.isEmpty
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_hospital_rounded,
                            size: 60.r, color: ColorManager.grey),
                        Gap(12.h),
                        Text(
                          'No hospitals found yet',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: ColorManager.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _hospitalList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final h = _hospitalList[index];
                        final isNearest = index == 0;
                        return ListTile(
                          onTap: () {
                            final point =
                                LatLng(h['lat'], h['lng']);
                            setState(() => _selectedHospital = h);
                            _mapController.move(point, 15);
                            _getRoute(point);
                            _scaffoldKey.currentState?.closeDrawer();
                          },
                          leading: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: isNearest
                                  ? ColorManager.green.withOpacity(0.15)
                                  : ColorManager.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_hospital_rounded,
                              color: isNearest
                                  ? ColorManager.green
                                  : ColorManager.grey,
                              size: 20.r,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  h['name'],
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.spMin,
                                    color: ColorManager.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isNearest) ...[
                                Gap(4.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: ColorManager.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nearest',
                                    style: TextStyle(
                                      color: ColorManager.white,
                                      fontSize: 9.spMin,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.directions_walk_rounded,
                                  size: 12.r, color: ColorManager.grey),
                              Gap(4.w),
                              Text(
                                _formatDistance(h['distance']),
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: ColorManager.grey,
                                  fontSize: 11.spMin,
                                ),
                              ),
                              if (h['phone'].toString().isNotEmpty) ...[
                                Gap(8.w),
                                Icon(Icons.phone_rounded,
                                    size: 12.r, color: ColorManager.green),
                              ]
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: ColorManager.grey),
                        );
                      },
                    ),
                  ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: CustomButton(
                isDisabled: _isLoading,
                size: Size(double.infinity, 44.h),
                onPressed: _findNearestHospitals,
                title: 'Find Hospitals',
                widget: _isLoading ? const ButtonLoadingIndicator() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: const BoxDecoration(
          color: ColorManager.green,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              color: ColorManager.white,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}
