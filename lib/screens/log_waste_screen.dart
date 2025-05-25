import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class LogWasteScreen extends StatefulWidget {
  @override
  _LogWasteScreenState createState() => _LogWasteScreenState();
}

class _LogWasteScreenState extends State<LogWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedLocation;
  String? _selectedWasteType;
  bool _isManualMode = true;
  MobileScannerController? _scannerController;
  bool _isSubmitting = false;
  bool _hasCameraPermission = false;
  List<Map<String, dynamic>> _dropOffLocations = [];

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'garden', 'label': 'Garden Waste'},
    {'value': 'paper', 'label': 'Paper Waste'},
    {'value': 'other', 'label': 'Other Organic Waste'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _fetchDropOffLocations();
  }

  Future<void> _initializeScanner() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCameraPermission = status.isGranted;
    });

    if (_hasCameraPermission) {
      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
        formats: [BarcodeFormat.qrCode],
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDropOffLocations() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dropoff_points')
          .where('isOpen', isEqualTo: true)
          .get();
      
      setState(() {
        _dropOffLocations = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'value': doc.id,
            'label': data['name'] as String? ?? 'Unknown Location',
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drop-off locations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance.collection('waste_logs').add({
        'userId': userId,
        'weight': double.parse(_weightController.text),
        'wasteType': _selectedWasteType,
        'dropOffPointId': _selectedLocation,
        'note': _noteController.text,
        'timestamp': _selectedDate,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Waste log submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _weightController.clear();
      _noteController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedLocation = null;
        _selectedWasteType = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting waste log: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log My Waste',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            'Record your waste contribution',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          
          // Toggle buttons for Manual/QR
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isManualMode = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isManualMode ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Manual Entry',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isManualMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (!_hasCameraPermission) {
                        final status = await Permission.camera.request();
                        setState(() {
                          _hasCameraPermission = status.isGranted;
                        });
                        if (!status.isGranted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Camera permission is required for QR scanning'),
                              action: SnackBarAction(
                                label: 'Settings',
                                onPressed: () => openAppSettings(),
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() => _isManualMode = false);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isManualMode ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Scan QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isManualMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          Expanded(
            child: _isManualMode ? _buildManualForm() : _buildQRScanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            decoration: InputDecoration(
              labelText: 'Drop-off Location',
              border: OutlineInputBorder(),
            ),
            items: _dropOffLocations.map((location) {
              return DropdownMenuItem(
                value: location['value'] as String,
                child: Text(location['label'] as String),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLocation = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a drop-off location';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the weight';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedWasteType,
            decoration: InputDecoration(
              labelText: 'Waste Type',
              border: OutlineInputBorder(),
            ),
            items: _wasteTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedWasteType = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a waste type';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    if (!_hasCameraPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Camera permission is required',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final status = await Permission.camera.request();
                setState(() {
                  _hasCameraPermission = status.isGranted;
                });
              },
              child: Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: MobileScanner(
        controller: _scannerController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            // Handle QR code data
            debugPrint('Barcode found! ${barcode.rawValue}');
          }
        },
      ),
    );
  }
}
