import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  final double lat;
  final double lng;
  final bool liveMode;
  final String? deviceSerial;

  const MapScreen({
    super.key,
    required this.lat,
    required this.lng,
    this.liveMode = false,
    this.deviceSerial,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng _position = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _position = LatLng(widget.lat, widget.lng);
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
    if (widget.liveMode && widget.deviceSerial != null) {
      return Scaffold(
        backgroundColor: AppTheme.kDarkSlate,
        appBar: AppBar(
          title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_location, color: AppTheme.kPrimaryCyan),
              onPressed: _shareLiveLocation,
            ),
          ],
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('devices/${widget.deviceSerial}/status').onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
              final lat = double.tryParse(data['lat']?.toString() ?? '') ?? _position.latitude;
              final lng = double.tryParse(data['lng']?.toString() ?? '') ?? _position.longitude;
              _position = LatLng(lat, lng);
              mapController?.animateCamera(CameraUpdate.newLatLng(_position));
            }
            return _buildMap();
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.kDarkSlate,
      appBar: AppBar(
        title: const Text('Satellite Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildMap(),
    );
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
