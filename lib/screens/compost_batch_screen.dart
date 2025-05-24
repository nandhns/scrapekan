import 'package:flutter/material.dart';
import '../services/waste_service.dart';
import '../services/compost_service.dart';
import '../providers/service_provider.dart';
import '../models/firestore_schema.dart';

class CompostBatchScreen extends StatefulWidget {
  @override
  _CompostBatchScreenState createState() => _CompostBatchScreenState();
}

class _CompostBatchScreenState extends State<CompostBatchScreen> {
  late final CompostService _compostService;
  late final WasteService _wasteService;
  bool _isCreatingBatch = false;
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  List<String> _selectedWasteLogs = [];
  double _totalWeight = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _compostService = ServiceProvider.of(context).compostService;
    _wasteService = ServiceProvider.of(context).wasteService;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compost Batches'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                _isCreatingBatch = true;
              });
            },
          ),
        ],
      ),
      body: _isCreatingBatch
          ? _buildCreateBatchForm()
          : _buildBatchList(),
    );
  }

  Widget _buildCreateBatchForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create New Compost Batch',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                hintText: 'Enter the location of this batch (e.g. Farm Name, Address)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Text(
              'Select Waste Logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            StreamBuilder<List<WasteLog>>(
              stream: _wasteService.getDropOffPointWasteLogs(_wasteService.currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final wasteLogs = snapshot.data!;

                if (wasteLogs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No available waste logs'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: wasteLogs.length,
                  itemBuilder: (context, index) {
                    final log = wasteLogs[index];
                    final isSelected = _selectedWasteLogs.contains(log.id);

                    return CheckboxListTile(
                      title: Text('${log.weight} kg'),
                      subtitle: Text(
                        'Dropped off on ${_formatDate(log.timestamp)}',
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedWasteLogs.add(log.id);
                            _totalWeight += log.weight;
                          } else {
                            _selectedWasteLogs.remove(log.id);
                            _totalWeight -= log.weight;
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Total Weight: ${_totalWeight.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isCreatingBatch = false;
                        _selectedWasteLogs.clear();
                        _totalWeight = 0;
                        _locationController.clear();
                      });
                    },
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createBatch,
                    child: Text('Create Batch'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchList() {
    return StreamBuilder<List<CompostBatch>>(
      stream: _compostService.getFarmerActiveBatches(_compostService.currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        final batches = snapshot.data!;

        if (batches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No active compost batches',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown[100],
                  child: Icon(Icons.eco, color: Colors.brown),
                ),
                title: Text('Batch #${batch.id.substring(0, 8)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location: ${batch.location}'),
                    Text('Input Weight: ${batch.inputWeight} kg'),
                    Text('Started: ${_formatDate(batch.startDate)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.check_circle_outline),
                  onPressed: () => _showCompleteBatchDialog(batch),
                ),
                onTap: () {
                  // Navigate to batch details screen
                },
              ),
            );
          },
        );
      },
    );
  }

  void _createBatch() async {
    if (!_formKey.currentState!.validate() || _selectedWasteLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final batch = CompostBatch(
      id: '',
      farmerId: _compostService.currentUserId!,
      inputWeight: _totalWeight,
      outputWeight: 0,
      startDate: DateTime.now(),
      endDate: null,
      status: 'active',
      wasteLogIds: _selectedWasteLogs,
      location: _locationController.text,
      imageUrl: '',
    );

    try {
      await _compostService.createCompostBatch(batch);
      setState(() {
        _isCreatingBatch = false;
        _selectedWasteLogs.clear();
        _totalWeight = 0;
        _locationController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Compost batch created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating batch: $e')),
      );
    }
  }

  void _showCompleteBatchDialog(CompostBatch batch) {
    final outputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Input Weight: ${batch.inputWeight} kg'),
            SizedBox(height: 16),
            TextFormField(
              controller: outputController,
              decoration: InputDecoration(
                labelText: 'Output Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final output = double.tryParse(outputController.text);
              if (output == null || output <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid output weight')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await _compostService.completeCompostBatch(batch.id, output, null);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Batch completed successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error completing batch: $e')),
                );
              }
            },
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 