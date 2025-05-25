import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class HomeMapScreen extends StatefulWidget {
  @override
  _HomeMapScreenState createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoading = true;
  List<DocumentSnapshot> _dropOffPoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadDropOffPoints();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDropOffPoints() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dropoff_points')
          .get();

      setState(() {
        _dropOffPoints = snapshot.docs;
        _markers = snapshot.docs.map((doc) {
          final data = doc.data();
          final position = data['position'] as GeoPoint;
          return Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: data['name'] as String,
              snippet: data['address'] as String,
            ),
          );
        }).toSet();
      });
    } catch (e) {
      print('Error loading drop-off points: $e');
    }
  }

  Widget _buildDropOffPointsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 16),
              Text(
                'Available Drop-off Points',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dropOffPoints.length,
          itemBuilder: (context, index) {
            final data = _dropOffPoints[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['name'] as String),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['address'] as String),
                    if (data['operatingHours'] != null)
                      Text('Hours: ${data['operatingHours']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: () {
                    final position = data['position'] as GeoPoint;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        16,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(3.140853, 101.693207); // Default to KL

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 300, // Fixed height for the map
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Find nearby drop-off points for your waste',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          _buildDropOffPointsList(),
        ],
      ),
    );
  }
}