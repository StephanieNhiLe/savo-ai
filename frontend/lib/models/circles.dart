import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class CirclesScreen extends StatefulWidget {
  @override
  _CirclesScreenState createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng? _userLocation;
  final List<Color> markerColors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSOSActive = false; 

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 100.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _userLocation = LatLng(position.latitude, position.longitude);
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

  void _updateMarkers() async {
    Set<Marker> markers = {};
    int colorIndex = 0;

    if (_currentPosition != null) {
        markers.add(
        Marker(
            markerId: MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            infoWindow: InfoWindow(title: 'You', snippet: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
        );
    } else {
        print('Current position is null.'); 
    }

    try {
        final circles = await _firestore.collection('circles').get();
        for (var circle in circles.docs) {
            if (circle.data().containsKey('location')) {
                GeoPoint geoPoint = circle['location'];
                LatLng circleLocation = LatLng(geoPoint.latitude, geoPoint.longitude);

                try {
                    String colorHex = circle.data().containsKey('color') ? circle['color'] : '#FF0000'; 
                    Color circleColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF'))); 

                    double hue = HSLColor.fromColor(circleColor).hue;

                    markers.add(
                        Marker(
                            markerId: MarkerId('circle_${circle.id}'),
                            position: circleLocation,
                            infoWindow: InfoWindow(
                                title: circle['name'] ?? 'Unnamed Circle',
                                snippet: 'Circle Location',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                        ),
                    );
                } catch (e) {
                    print('Error processing circle ${circle.id}: $e');
                }
            } else {
                print('Circle document missing location: ${circle.id}');
            }

            final members = await circle.reference.collection('members').get();
            for (var member in members.docs) {
                final memberName = member['name'];
                final lastUpdate = member['lastUpdate'];
                final battery = member['battery'];

                if (member.data().containsKey('latitude') && member.data().containsKey('longitude')) {
                    final lastUpdateTime = (lastUpdate as Timestamp).toDate();
                    final timeAgo = _timeAgo(lastUpdateTime);

                    final memberMarker = BitmapDescriptor.fromBytes(
                        await _createMemberMarkerIcon(
                        memberName: memberName,
                        lastUpdate: timeAgo,
                        battery: battery,
                        ),
                    );

                    markers.add(
                        Marker(
                        markerId: MarkerId(member.id),
                        position: LatLng(member['latitude'], member['longitude']),
                        infoWindow: InfoWindow(
                            title: memberName,
                            snippet: 'Last seen: $timeAgo',
                        ),
                        icon: memberMarker,
                        ),
                    );
                } else {
                    print('Member document missing latitude or longitude: ${member.id}');
                }
            }
        }
    } catch (e) {
        print('Error fetching circles or members: $e'); 
    }

    setState(() {
        _markers = markers;
        if (markers.isEmpty) {
            print('No markers were added.'); 
        }
    });
  }

  Future<Uint8List> _createMemberMarkerIcon({
    required String memberName,
    required String lastUpdate,
    required int battery,
    }) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
    );

    canvas.drawRRect(
        RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 200, 100),
        const Radius.circular(10),
        ),
        Paint()..color = Colors.white,
    );

    textPainter.text = TextSpan(
        text: memberName,
        style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, 16));

    textPainter.text = TextSpan(
        text: 'Last seen: $lastUpdate\nBattery: $battery%',
        style: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
        ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(16, 44));

    final picture = await recorder.endRecording().toImage(200, 100);
    final bytes = await picture.toByteData(format: ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLocation ?? LatLng(37.7749, -122.4194),
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onCameraMove: (CameraPosition position) {
                  },
                  // Expanding circle
                  circles: _isSOSActive ? _createSOSCircle() : Set(),
                ),

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
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('circles').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData) {
                            return Center(child: Text('No circles available.'));
                          }

                          final circles = snapshot.data!.docs;

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: circles.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'My Circle',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          _showAddCircleDialog(context);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }

                              var circleData = circles[index - 1];
                              var circleName = circleData['name'] ?? 'Unnamed Circle';
                              var circleId = circleData.id;

                              GeoPoint geoPoint = circleData['location'];
                              LatLng circleLocation = LatLng(geoPoint.latitude, geoPoint.longitude);

                              Color circleColor = markerColors[index % markerColors.length];

                              return ExpansionTile(
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: circleColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(circleName, style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('Location: ${circleLocation.latitude}, ${circleLocation.longitude}'),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _checkIn(circleId); 
                                      },
                                      child: Text('Check In'),
                                    ),
                                    // SOS Button
                                    ElevatedButton(
                                      onPressed: () {
                                        _sendSOS(circleId);
                                      },
                                      child: Text('SOS'),
                                    ),
                                  ],
                                ),
                                children: [
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _firestore.collection('circles').doc(circleId).collection('members').snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                      if (!snapshot.hasData) {
                                        return Center(child: Text('No members available.'));
                                      }

                                      final members = snapshot.data!.docs;
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: members.length,
                                        itemBuilder: (context, index) {
                                          var memberData = members[index];
                                          var memberName = memberData['name'];
                                          var lastUpdate = memberData['lastUpdate'];
                                          var battery = memberData['battery'];

                                          DateTime lastUpdateTime = (lastUpdate as Timestamp).toDate();
                                          String timeAgo = _timeAgo(lastUpdateTime);

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: AssetImage('assets/default_avatar.jpg'), 
                                            ),
                                            title: Text(memberName),
                                            subtitle: Text('Last update: $timeAgo'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.battery_full,
                                                  color: battery > 20 ? Colors.green : Colors.red,
                                                ),
                                                Text('$battery%'),
                                              ],
                                            ),
                                            onTap: () {
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLngZoom(
                                                  LatLng(memberData['latitude'], memberData['longitude']),
                                                  16.0,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
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

  String _timeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Add Circle Form 
  void _showAddCircleDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? circleName;
    String? memberName;
    String? locationAddress;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Circle or Member'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Circle Name'),
                  onSaved: (value) {
                    circleName = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a circle name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Member Name'),
                  onSaved: (value) {
                    memberName = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a member name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Location Address'),
                  onSaved: (value) {
                    locationAddress = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _addCircleOrMember(circleName, memberName, locationAddress);
                  Navigator.of(context).pop(); 
                }
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _addCircleOrMember(String? circleName, String? memberName, String? locationAddress) {
    // handle backend w firestore
    if (circleName != null && memberName != null) {
      
    } else if (circleName != null) {

    }
  }

  void _checkIn(String circleId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('User checked in at circle $circleId'),
        duration: Duration(seconds: 3),  
      ),
    );
    print('User checked in at circle: $circleId');
  }
 
  void _sendSOS(String circleId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending SOS alert to other circles...'),
        duration: Duration(seconds: 3),  
      ),
    );

    _isSOSActive = true;
    _animationController.forward().then((_) {
      _animationController.reset();
      _isSOSActive = false;
      setState(() {}); 
    });

    // Send an SOS alert using Twilio
    print('SOS alert sent for circle: $circleId');
  }

  // SOS Signal Custom
  Set<Circle> _createSOSCircle() {
    return {
      Circle(
        circleId: CircleId('sos_circle'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: _animation.value,
        fillColor: Colors.red.withOpacity(0.5),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ),
    };
  }
}
