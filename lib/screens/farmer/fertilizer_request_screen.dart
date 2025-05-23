import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class FertilizerRequestScreen extends StatefulWidget {
  @override
  _FertilizerRequestScreenState createState() => _FertilizerRequestScreenState();
}

class _FertilizerRequestScreenState extends State<FertilizerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String _selectedType = 'organic';
  bool _isSubmitting = false;

  final List<Map<String, String>> _fertilizerTypes = [
    {'value': 'organic', 'label': 'Organic Fertilizer'},
    {'value': 'compost', 'label': 'Compost'},
    {'value': 'vermicompost', 'label': 'Vermicompost'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Request Fertilizer')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Fertilizer Type',
                  border: OutlineInputBorder(),
                ),
                items: _fertilizerTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the quantity';
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
                      onPressed: _submitRequest,
                      child: Text('Submit Request'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user == null) {
          throw Exception('User not logged in');
        }

        await FirebaseFirestore.instance.collection('fertilizer_requests').add({
          'userId': user.uid,
          'fertilizerType': _selectedType,
          'quantity': double.parse(_quantityController.text),
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        _quantityController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
} 