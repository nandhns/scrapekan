import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CitizenLogWasteScreen extends StatefulWidget {
  @override
  _CitizenLogWasteScreenState createState() => _CitizenLogWasteScreenState();
}

class _CitizenLogWasteScreenState extends State<CitizenLogWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  String _selectedWasteType = 'organic';
  String? _selectedDropOffPoint;
  File? _imageFile;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DropdownMenuItem<String>> _dropOffPoints = [];

  @override
  void initState() {
    super.initState();
    _loadDropOffPoints();
  }

  Future<void> _loadDropOffPoints() async {
    final snapshot = await _firestore.collection('dropoff_points').get();
    setState(() {
      _dropOffPoints = snapshot.docs
          .map((doc) => DropdownMenuItem(
                value: doc.id,
                child: Text(doc.data()['name'] as String),
              ))
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitWasteLog() async {
    if (!_formKey.currentState!.validate() || _selectedDropOffPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('User not logged in');

      final weight = double.parse(_weightController.text);

      // Create waste log
      final wasteLogRef = _firestore.collection('waste_logs').doc();
      await wasteLogRef.set({
        'id': wasteLogRef.id,
        'userId': user.uid,
        'dropOffPointId': _selectedDropOffPoint,
        'weight': weight,
        'wasteType': _selectedWasteType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'imageUrl': null, // TODO: Implement image upload
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waste logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _weightController.clear();
        _imageFile = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging waste: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Your Waste',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        value: _selectedWasteType,
                        decoration: const InputDecoration(
                          labelText: 'Waste Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'organic',
                            child: Text('Organic Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'garden',
                            child: Text('Garden Waste'),
                          ),
                          DropdownMenuItem(
                            value: 'food',
                            child: Text('Food Waste'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedWasteType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
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
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDropOffPoint,
                        decoration: const InputDecoration(
                          labelText: 'Drop-off Point',
                          border: OutlineInputBorder(),
                        ),
                        items: _dropOffPoints,
                        onChanged: (value) {
                          setState(() => _selectedDropOffPoint = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a drop-off point';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      if (_imageFile != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Image.file(
                            _imageFile!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitWasteLog,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }
} 