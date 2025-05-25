// lib/pages/citizen/home_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../config/api_keys.dart';

class HomeMap extends StatefulWidget {
  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final Completer<GoogleMapController> _controller = Completer();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  DropoffPoint? _selectedLocation;
  bool _isMapCreated = false;

  // Center of Kuantan as default location
  static const LatLng _defaultLocation = LatLng(3.8168, 103.3317);

  final List<DropoffPoint> _dropoffPoints = [
    DropoffPoint(
      id: 'loc1',
      name: 'Pasar Tani Kekal Pekan',
      address: 'Jalan Sultan Abdullah, 26600 Pekan, Pahang',
      latLng: LatLng(3.4925, 103.3889),
      openingHours: '7:00 AM - 2:00 PM',
      isOpen: true,
      type: 'Market',
      capacity: '80%',
    ),
    DropoffPoint(
      id: 'loc2',
      name: 'Pasar Tani Kekal Gambang',
      address: 'Jalan Gambang Perdana 1, 26300 Gambang, Pahang',
      latLng: LatLng(3.7089, 103.1198),
      openingHours: '8:00 AM - 6:00 PM',
      isOpen: true,
      type: 'Market',
      capacity: '60%',
    ),
    DropoffPoint(
      id: 'loc3',
      name: 'Taman Tas Collection Center',
      address: 'Taman Tas, 25150 Kuantan, Pahang',
      latLng: LatLng(3.8168, 103.3317),
      openingHours: '24 hours',
      isOpen: true,
      type: 'Collection Center',
      capacity: '45%',
    ),
    DropoffPoint(
      id: 'loc4',
      name: 'Bandar Putra Collection Point',
      address: 'Bandar Putra, 26600 Pekan, Pahang',
      latLng: LatLng(3.4837, 103.3757),
      openingHours: '9:00 AM - 5:00 PM',
      isOpen: false,
      type: 'Collection Point',
      capacity: '90%',
    ),
  ];

  final CameraPosition _initialPosition = CameraPosition(
    target: _defaultLocation,
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeMarkers();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      if (_controller.isCompleted) {
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }
      _initializeMarkers();
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeMarkers() {
    if (!mounted) return;
    
    setState(() {
      _markers = _dropoffPoints.map((point) {
        return Marker(
          markerId: MarkerId(point.id),
          position: point.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            point.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: point.name,
            snippet: '${point.openingHours} • ${point.capacity} full',
          ),
          onTap: () => _onMarkerTapped(point),
        );
      }).toSet();

      if (_currentPosition != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('current_location'),
            position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );
      }
    });
  }

  void _onMarkerTapped(DropoffPoint point) {
    setState(() {
      _selectedLocation = point;
    });
  }

  Future<void> _showDirections(DropoffPoint point) async {
    if (_currentPosition == null) return;

    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _currentPosition!.latitude < point.latLng.latitude
                  ? _currentPosition!.latitude
                  : point.latLng.latitude,
              _currentPosition!.longitude < point.latLng.longitude
                  ? _currentPosition!.longitude
                  : point.latLng.longitude,
            ),
            northeast: LatLng(
              _currentPosition!.latitude > point.latLng.latitude
                  ? _currentPosition!.latitude
                  : point.latLng.latitude,
              _currentPosition!.longitude > point.latLng.longitude
                  ? _currentPosition!.longitude
                  : point.latLng.longitude,
            ),
          ),
          100,
        ),
      );
    }
  }

  String _getDistanceString(DropoffPoint point) {
    if (_currentPosition == null) return '';
    
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      point.latLng.latitude,
      point.latLng.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km away';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_isMapCreated) {
      _controller.complete(controller);
      _isMapCreated = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _openDirections(DropoffPoint point) async {
    if (_currentPosition == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&destination=${point.latLng.latitude},${point.latLng.longitude}'
      '&travelmode=driving'
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Drop-off Points',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find the nearest compost drop-off location',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: _currentPosition != null
                          ? CameraPosition(
                              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              zoom: 14,
                            )
                          : _initialPosition,
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      padding: EdgeInsets.only(bottom: 180),
                    ),
              if (_error != null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nearby Drop-off Points',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        ..._dropoffPoints
                            .where((point) => _getDistanceString(point).isNotEmpty)
                            .take(3)
                            .map((point) => Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _openDirections(point),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: point.isOpen
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.location_on,
                                              color: point.isOpen
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  point.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text(
                                                      _getDistanceString(point),
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[400],
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      point.isOpen ? 'Open now' : 'Closed',
                                                      style: TextStyle(
                                                        color: point.isOpen
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.directions,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DropoffPoint {
  final String id;
  final String name;
  final String address;
  final LatLng latLng;
  final String openingHours;
  final bool isOpen;
  final String type;
  final String capacity;

  DropoffPoint({
    required this.id,
    required this.name,
    required this.address,
    required this.latLng,
    required this.openingHours,
    required this.isOpen,
    required this.type,
    required this.capacity,
  });
}
