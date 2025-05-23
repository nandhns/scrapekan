import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LogWasteScreen extends StatefulWidget {
  @override
  _LogWasteScreenState createState() => _LogWasteScreenState();
}

class _LogWasteScreenState extends State<LogWasteScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedCode;
  bool isScanning = true;
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  String _selectedWasteType = 'food';
  bool _isSubmitting = false;

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'food', 'label': 'Food Waste'},
    {'value': 'garden', 'label': 'Garden Waste'},
    {'value': 'paper', 'label': 'Paper Waste'},
    {'value': 'other', 'label': 'Other Organic Waste'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Waste'),
        actions: [
          if (!isScanning)
            IconButton(
              icon: Icon(Icons.qr_code_scanner),
              onPressed: () => setState(() => isScanning = true),
            ),
        ],
      ),
      body: isScanning ? _buildQRScanner() : _buildWasteForm(),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              'Scan QR Code on Composting Machine',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWasteForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Machine ID: ${scannedCode ?? "Unknown"}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
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
                  _selectedWasteType = value!;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
            SizedBox(height: 24),
            _isSubmitting
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitWasteLog,
                    child: Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        setState(() {
          scannedCode = scanData.code;
          isScanning = false;
        });
        controller.dispose();
      }
    });
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
          'machineId': scannedCode,
          'wasteType': _selectedWasteType,
          'weight': double.parse(_weightController.text),
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Reset form
        _weightController.clear();
        setState(() {
          isScanning = true;
          scannedCode = null;
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

  @override
  void dispose() {
    controller?.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
