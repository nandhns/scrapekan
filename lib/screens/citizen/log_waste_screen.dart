import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/auth_service.dart';

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
  late final MobileScannerController _scannerController;
  bool _isSubmitting = false;

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'garden', 'label': 'Garden Waste'},
    {'value': 'paper', 'label': 'Paper Waste'},
    {'value': 'other', 'label': 'Other Organic Waste'},
  ];

  final List<Map<String, String>> _dropOffLocations = [
    {'value': 'loc1', 'label': 'Pasar Tani Kekal Pekan'},
    {'value': 'loc2', 'label': 'Pasar Tani Kekal Gambang'},
    {'value': 'loc3', 'label': 'Taman Tas Collection Center'},
    {'value': 'loc4', 'label': 'Bandar Putra Collection Point'},
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _scannerController.dispose();
    super.dispose();
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
                        'Manual Form',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isManualMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isManualMode = false),
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
                          fontWeight: FontWeight.bold,
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            SizedBox(height: 16),

            // Drop-off Location
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Drop-off Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              value: _selectedLocation,
              items: _dropOffLocations.map((location) {
                return DropdownMenuItem(
                  value: location['value'],
                  child: Text(location['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLocation = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a drop-off location';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Waste Type
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Waste Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delete_outline),
              ),
              value: _selectedWasteType,
              items: _wasteTypes.map((type) {
                return DropdownMenuItem(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedWasteType = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a waste type';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Weight
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Approximate Weight (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the approximate weight';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWasteLog,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(_isSubmitting ? 'Submitting...' : 'Submit Waste Log'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Scan QR code at drop-off point',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  _handleQRCode(barcode.rawValue ?? '');
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Camera error: ${error.errorCode}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          ElevatedButton.icon(
            onPressed: () => _scannerController.toggleTorch(),
            icon: Icon(Icons.flash_on),
            label: Text('Toggle Flash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  void _handleQRCode(String code) {
    // TODO: Implement QR code handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR Code scanned: $code')),
    );
  }

  Future<void> _submitWasteLog() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user == null) {
          throw Exception('User not logged in');
        }

        await FirebaseFirestore.instance.collection('waste_logs').add({
          'userId': user.uid,
          'date': Timestamp.fromDate(_selectedDate),
          'location': _selectedLocation,
          'wasteType': _selectedWasteType,
          'weight': double.parse(_weightController.text),
          'note': _noteController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Reset form
        _weightController.clear();
        _noteController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedLocation = null;
          _selectedWasteType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waste log submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit waste log'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
