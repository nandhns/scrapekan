import 'package:flutter/material.dart';

class LogWasteScreen extends StatefulWidget {
  const LogWasteScreen({super.key});

  @override
  State<LogWasteScreen> createState() => _LogWasteScreenState();
}

class _LogWasteScreenState extends State<LogWasteScreen> {
  bool isManualForm = true;

  final _formKey = GlobalKey<FormState>();

  String? _selectedLocation;
  String? _selectedWasteType;
  final List<String> _locations = ['Point A', 'Point B', 'Point C'];
  final List<String> _wasteTypes = ['Food', 'Garden', 'Paper'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log My Waste")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Log My Waste",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text("Record your waste contribution."),
            const SizedBox(height: 16),

            // Toggle buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => isManualForm = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isManualForm ? Colors.amber : Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Manual Form"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => setState(() => isManualForm = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isManualForm ? Colors.amber : Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Scan QR"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Conditional content
            isManualForm ? _buildManualForm() : _buildQRScannerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          TextFormField(
            decoration: const InputDecoration(labelText: "Date (DD/MM/YYYY)"),
            validator: (value) => value!.isEmpty ? "Please enter a date" : null,
          ),
          const SizedBox(height: 10),

          // Drop-off location
          DropdownButtonFormField<String>(
            value: _selectedLocation,
            items: _locations
                .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                .toList(),
            onChanged: (val) => setState(() => _selectedLocation = val),
            decoration: const InputDecoration(labelText: "Drop-off Location"),
          ),
          const SizedBox(height: 10),

          // Waste type
          DropdownButtonFormField<String>(
            value: _selectedWasteType,
            items: _wasteTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (val) => setState(() => _selectedWasteType = val),
            decoration: const InputDecoration(labelText: "Waste Type"),
          ),
          const SizedBox(height: 10),

          // Approximate weight
          TextFormField(
            decoration: const InputDecoration(labelText: "Approximate Weight (kg)"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),

          // Notes
          TextFormField(
            decoration: const InputDecoration(labelText: "Notes (Optional)"),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Submit button
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // submit logic here
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScannerSection() {
    return Column(
      children: [
        const Text("Scan a QR code to log your waste."),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // future camera integration
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text("Open Camera"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }
}
