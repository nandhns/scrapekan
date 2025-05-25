import 'package:cloud_firestore/cloud_firestore.dart';

class FertilizerRequestSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Regions in Kuantan and surrounding areas
  final List<Map<String, dynamic>> _regions = [
    {
      'name': 'Taman Tas',
      'baseAmount': 150.0,
      'growthRate': 1.2,
    },
    {
      'name': 'Bandar Indera Mahkota',
      'baseAmount': 200.0,
      'growthRate': 1.5,
    },
    {
      'name': 'Gambang',
      'baseAmount': 100.0,
      'growthRate': 1.8,
    },
    {
      'name': 'Pekan',
      'baseAmount': 120.0,
      'growthRate': 1.3,
    },
    {
      'name': 'Beserah',
      'baseAmount': 80.0,
      'growthRate': 1.6,
    },
  ];

  Future<void> seedData() async {
    // Clear existing data
    await _clearExistingData();

    // Generate data for the last 60 days
    final now = DateTime.now();
    for (int i = 60; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      for (var region in _regions) {
        // Calculate growing demand over time
        final daysFactor = (60 - i) / 60; // Factor increases as we get closer to today
        final growthMultiplier = 1 + (daysFactor * (region['growthRate'] - 1));
        
        // Add some randomness to the amounts
        final baseAmount = region['baseAmount'] as double;
        final randomFactor = 0.8 + (DateTime.now().millisecondsSinceEpoch % 40) / 100; // Random between 0.8 and 1.2
        final amount = baseAmount * growthMultiplier * randomFactor;

        // Create request document
        await _firestore.collection('fertilizer_requests').add({
          'region': region['name'],
          'amount': amount,
          'timestamp': Timestamp.fromDate(date),
          'status': _getRandomStatus(),
          'farmerId': 'farmer_${region['name'].toLowerCase().replaceAll(' ', '_')}_${i % 3 + 1}',
          'requestType': _getRandomRequestType(),
          'notes': 'Sample request for ${region['name']}',
        });
      }
    }
  }

  Future<void> _clearExistingData() async {
    final snapshot = await _firestore.collection('fertilizer_requests').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String _getRandomStatus() {
    final statuses = ['pending', 'approved', 'completed', 'cancelled'];
    return statuses[DateTime.now().millisecondsSinceEpoch % statuses.length];
  }

  String _getRandomRequestType() {
    final types = ['general', 'enriched', 'specialized'];
    return types[DateTime.now().millisecondsSinceEpoch % types.length];
  }
}

// Usage example:
// final seeder = FertilizerRequestSeeder();
// await seeder.seedData(); 