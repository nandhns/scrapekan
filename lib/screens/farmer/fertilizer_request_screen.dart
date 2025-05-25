import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class FertilizerRequestScreen extends StatefulWidget {
  @override
  _FertilizerRequestScreenState createState() => _FertilizerRequestScreenState();
}

class _FertilizerRequestScreenState extends State<FertilizerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _instructionsController = TextEditingController();
  String? _selectedLocation;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // Predefined farm locations
  final List<Map<String, String>> _farmLocations = [
    {'id': 'loc1', 'name': 'Kampung Sungai Soi'},
    {'id': 'loc2', 'name': 'Kampung Ubai'},
    {'id': 'loc3', 'name': 'Kampung Tanjung Lumpur'},
    {'id': 'loc4', 'name': 'Taman Guru'},
    {'id': 'loc5', 'name': 'Bandar Indera Mahkota'},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      helpText: 'Select Preferred Delivery Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request Fertilizer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Submit your request for compost fertilizer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                
                // Request Form
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Farm Location Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: InputDecoration(
                              labelText: 'Farm Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            items: _farmLocations.map((location) {
                              return DropdownMenuItem(
                                value: location['id'],
                                child: Text(location['name']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a farm location';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Quantity
                          TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity Needed (kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                              suffixText: 'kg',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (int.parse(value) <= 0) {
                                return 'Quantity must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),

                          // Delivery Date
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: IgnorePointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Preferred Delivery Date',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  suffixIcon: Icon(Icons.arrow_drop_down),
                                ),
                                controller: TextEditingController(
                                  text: _selectedDate != null
                                      ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                      : '',
                                ),
                                validator: (value) {
                                  if (_selectedDate == null) {
                                    return 'Please select a delivery date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Special Instructions
                          TextFormField(
                            controller: _instructionsController,
                            decoration: InputDecoration(
                              labelText: 'Special Instructions (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                              hintText: 'Enter any special instructions or notes',
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 24),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text('Submit Request'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                
                // Previous Requests
                Text(
                  'Previous Requests',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _getRequestsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data?.docs ?? [];
                    
                    if (requests.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No previous requests'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index].data() as Map<String, dynamic>;
                        final timestamp = (request['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text('General Purpose Compost'),
                            subtitle: Text('${request['quantity']}kg • ${_timeAgo(timestamp)}'),
                            trailing: _buildStatusChip(request['status'] as String? ?? 'pending'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text = status.toUpperCase();
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getRequestsStream() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('fertilizer_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to submit a request')),
        );
        return;
      }

      final userData = await authService.getUserData(user.uid);
      
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data')),
        );
        return;
      }

      // Get the farm location name
      final farmLocation = _farmLocations.firstWhere(
        (loc) => loc['id'] == _selectedLocation,
        orElse: () => {'id': '', 'name': 'Unknown Location'},
      );

      await FirebaseFirestore.instance.collection('fertilizer_requests').add({
        'userId': user.uid,
        'farmerName': userData.name,
        'farmLocationId': _selectedLocation,
        'farmLocationName': farmLocation['name'],
        'quantity': int.parse(_quantityController.text),
        'deliveryDate': Timestamp.fromDate(_selectedDate!),
        'specialInstructions': _instructionsController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request submitted successfully')),
      );

      // Reset form
      _quantityController.clear();
      _instructionsController.clear();
      setState(() {
        _selectedLocation = null;
        _selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
} 