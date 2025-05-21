// lib/pages/citizen/home_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  void _onTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose Location')),
      body: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: const CameraPosition(
          target: LatLng(3.1390, 101.6869), // Kuala Lumpur
          zoom: 12,
        ),
        onTap: _onTap,
        markers: _selectedLocation != null
            ? {
                Marker(markerId: MarkerId("selected"), position: _selectedLocation!)
              }
            : {},
      ),
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // You can store the coordinates or pass to another page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Selected: $_selectedLocation")),
                );
              },
              label: Text("Confirm Location"),
              icon: Icon(Icons.check),
            )
          : null,
    );
  }
}
