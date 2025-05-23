import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LogWasteScreen extends StatefulWidget {
  @override
  _LogWasteScreenState createState() => _LogWasteScreenState();
}

class _LogWasteScreenState extends State<LogWasteScreen> {
  final _weightController = TextEditingController();
  String? _selectedWasteType;
  bool _isScanning = false;
  late final MobileScannerController _scannerController;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'garden', 'label': 'Garden Waste'},
    {'value': 'paper', 'label': 'Paper Waste'},
    {'value': 'other', 'label': 'Other Organic Waste'},
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
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Your Waste',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 24),
          if (_isScanning) ...[
            Expanded(
              child: Column(
                children: [
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
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => setState(() => _isScanning = false),
                                  child: Text('Go Back'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isScanning = false);
                        },
                        icon: Icon(Icons.close),
                        label: Text('Cancel'),
                      ),
                      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                        ElevatedButton.icon(
                          onPressed: () => _scannerController.toggleTorch(),
                          icon: Icon(Icons.flash_on),
                          label: Text('Toggle Flash'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Log',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Waste Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
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
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleManualLog,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Submit'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Or scan QR code at collection point',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isScanning = true);
                },
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan QR Code'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleQRCode(String code) {
    setState(() => _isScanning = false);
    // TODO: Implement QR code handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('QR Code scanned: $code'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _handleManualLog() {
    if (_weightController.text.isEmpty || _selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement waste logging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logging waste: ${_weightController.text}kg of $_selectedWasteType'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
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
          'machineId': _selectedWasteType,
          'wasteType': _selectedWasteType,
          'weight': double.parse(_weightController.text),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Reset form
        _weightController.clear();
        setState(() {
          _isScanning = false;
          _selectedWasteType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Waste log submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit waste log')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
