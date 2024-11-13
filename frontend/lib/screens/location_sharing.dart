import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; 

class LocationSharing extends StatefulWidget {
  @override
  _LocationSharingState createState() => _LocationSharingState();
}

class _LocationSharingState extends State<LocationSharing> {
  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  LatLng? _userLocation;
  late Position _currentPosition;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web: browser geolocation API
      _getWebLocation();
    } else {
      // Mobile: geolocator package
      _getCurrentLocation();
    }
  }

  // Mobile
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(_currentPosition.latitude, _currentPosition.longitude);
    });
  }

  Future<void> _getWebLocation() async {
    try {
      final geolocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(geolocation.latitude, geolocation.longitude);
      });
    } catch (e) {
      print("Error getting web location: $e");
    }
  }
 
  void _updateMarkers(List<QueryDocumentSnapshot> docs) {
    final markers = <String, Marker>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = doc.id;
      final LatLng position = LatLng(data['latitude'], data['longitude']);
      final String name = data['name'];
      final String status = data['status'];

      final marker = Marker(
        markerId: MarkerId(userId),
        position: position,
        infoWindow: InfoWindow(
          title: name,
          snippet: 'Status: $status',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          status == 'Safe' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );

      markers[userId] = marker;
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Circle Safety & Location Tracking'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('locations').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          // Update markers when new data arrives - not working yet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers(snapshot.data!.docs);
          });

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? LatLng(37.7749, -122.4194), // Default location
              zoom: 10,
            ),
            markers: _markers.values.toSet(),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onCameraMove: (CameraPosition position) {
              // Optionally, update camera position when moved
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userLocation != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_userLocation!, 14),
            );
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
