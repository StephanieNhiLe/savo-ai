import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationSharing extends StatefulWidget {
  @override
  _LocationSharingState createState() => _LocationSharingState();
}

class _LocationSharingState extends State<LocationSharing> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Sample family member data - In real app, this would come from your backend
  final List<Map<String, dynamic>> _familyMembers = [
    {
      'id': '1',
      'name': 'Mom',
      'avatar': 'assets/avatar1.png',
      'location': LatLng(37.4219999, -122.0840575),
      'lastUpdate': '2 min ago',
      'battery': 85,
    },
    {
      'id': '2',
      'name': 'Dad',
      'avatar': 'assets/avatar2.png',
      'location': LatLng(37.4219999, -122.0862222),
      'lastUpdate': '5 min ago',
      'battery': 45,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Request location permission
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateMarkers();
      } catch (e) {
        print('Error getting location: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};
    
    // Add current user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: InfoWindow(title: 'You', snippet: 'Current Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add family members markers
    for (var member in _familyMembers) {
      markers.add(
        Marker(
          markerId: MarkerId(member['id']),
          position: member['location'],
          infoWindow: InfoWindow(
            title: member['name'],
            snippet: 'Last seen: ${member['lastUpdate']}',
          ),
        ),
      );
    }

    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : LatLng(37.4219999, -122.0840575), // Default to Google HQ
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  compassEnabled: true,
                ),

                // Family Members List
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 0.7,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _familyMembers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Family Circle',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      // Add family member logic
                                    },
                                  ),
                                ],
                              ),
                            );
                          }

                          final member = _familyMembers[index - 1];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(member['avatar']),
                            ),
                            title: Text(member['name']),
                            subtitle: Text(member['lastUpdate']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.battery_full,
                                  color: member['battery'] > 20
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                Text('${member['battery']}%'),
                              ],
                            ),
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  member['location'],
                                  16.0,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),

                // Safety Button
                Positioned(
                  right: 16,
                  top: 16,
                  child: SafeArea(
                    child: FloatingActionButton(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.warning_amber_rounded),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Emergency Alert'),
                            content: Text('Do you want to send an emergency alert to your family circle?'),
                            actions: [
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: Text('Send Alert'),
                                onPressed: () {
                                  // Implement emergency alert logic
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}