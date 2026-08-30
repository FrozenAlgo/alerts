import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../config/demo_config.dart';
import '../services/app_database.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/ui.dart';

class MapScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final bool liveMode;
  final String? deviceSerial;
  final String? userId;

  const MapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.liveMode = false,
    this.deviceSerial,
    this.userId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _position = const LatLng(0, 0);
  double? _phoneLat;
  double? _phoneLng;

  @override
  void initState() {
    super.initState();
    final coords = DemoConfig.resolveMapCoordinates(widget.lat, widget.lng);
    _position = LatLng(coords.lat, coords.lng);
    _refreshPhoneGps();
  }

  Future<void> _refreshPhoneGps() async {
    final phone = await LocationService.getPhoneLocation();
    if (!mounted || phone == null) return;
    setState(() {
      _phoneLat = phone.lat;
      _phoneLng = phone.lng;
    });
  }

  void _applyCoordinates({
    required double deviceLat,
    required double deviceLng,
    required double hardwareLat,
    required double hardwareLng,
  }) {
    final resolved = LocationService.resolveDisplayCoordinates(
      deviceLat: deviceLat,
      deviceLng: deviceLng,
      hardwareLat: hardwareLat,
      hardwareLng: hardwareLng,
      phoneLat: _phoneLat,
      phoneLng: _phoneLng,
    );
    final next = LatLng(resolved.lat, resolved.lng);
    if (_position.latitude != next.latitude || _position.longitude != next.longitude) {
      setState(() => _position = next);
      mapController?.animateCamera(CameraUpdate.newLatLng(_position));
    }
  }

  Future<void> _shareLiveLocation() async {
    final shareId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance.collection('location_shares').doc(shareId).set({
      'lat': _position.latitude,
      'lng': _position.longitude,
      'serial': widget.deviceSerial,
      'expiresAt': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_position.latitude},${_position.longitude}';
    await Share.share('Live OnAlert location (1hr): $url');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.liveMode) {
      return Scaffold(
        backgroundColor: AppTheme.kBackground,
        appBar: AppBrandedAppBar(
          title: 'Live Tracking',
          actions: [
            IconButton(
              icon: const Icon(Icons.share_location, color: AppTheme.kCyan),
              onPressed: _shareLiveLocation,
            ),
          ],
        ),
        body: _buildLiveTrackingBody(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: const AppBrandedAppBar(title: 'Satellite Tracking'),
      body: _buildMap(),
    );
  }

  Widget _buildLiveTrackingBody() {
    if (widget.deviceSerial != null) {
      return StreamBuilder<DatabaseEvent>(
        stream: AppDatabase.rtdb.ref('devices/${widget.deviceSerial}/status').onValue,
        builder: (context, snapshot) {
          double deviceLat = 0;
          double deviceLng = 0;
          double hardwareLat = 0;
          double hardwareLng = 0;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            deviceLat = double.tryParse(data['lat']?.toString() ?? '') ?? 0;
            deviceLng = double.tryParse(data['lng']?.toString() ?? '') ?? 0;
          }

          _applyCoordinates(
            deviceLat: deviceLat,
            deviceLng: deviceLng,
            hardwareLat: hardwareLat,
            hardwareLng: hardwareLng,
          );
          return _buildMap();
        },
      );
    }

    if (widget.userId != null) {
      return StreamBuilder<DatabaseEvent>(
        stream: AppDatabase.rtdb.ref('users/${widget.userId}/hardware').onValue,
        builder: (context, snapshot) {
          double hardwareLat = 0;
          double hardwareLng = 0;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
            hardwareLat = double.tryParse(data['lat']?.toString() ?? '') ?? 0;
            hardwareLng = double.tryParse(data['lng']?.toString() ?? '') ?? 0;
          }

          _applyCoordinates(
            deviceLat: 0,
            deviceLng: 0,
            hardwareLat: hardwareLat,
            hardwareLng: hardwareLng,
          );
          return _buildMap();
        },
      );
    }

    return _buildMap();
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (c) => mapController = c,
      initialCameraPosition: CameraPosition(target: _position, zoom: 17),
      markers: {
        Marker(
          markerId: const MarkerId('location'),
          position: _position,
          infoWindow: InfoWindow(
            title: widget.liveMode ? 'Live Device' : 'Alert Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
      mapType: MapType.hybrid,
      myLocationEnabled: true,
    );
  }
}
