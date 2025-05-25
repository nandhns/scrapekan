import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faker/faker.dart';
import '../models/firestore_schema.dart';

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();
  final _faker = Faker();

  // Seed all data
  Future<void> seedAllData() async {
    try {
      // First create users of different roles
      final users = await _seedUsers();
      print('✓ Users created');

      // Create drop-off points
      final dropOffPoints = await _seedDropOffPoints(
        users.where((u) => u['role'] == 'municipal')
            .map((u) => u['id'].toString())
            .toList(),
      );
      print('✓ Drop-off points created');

      // Create waste logs
      final wasteLogs = await _seedWasteLogs(
        users.where((u) => u['role'] == 'citizen')
            .map((u) => u['id'].toString())
            .toList(),
        dropOffPoints.map((d) => d['id'].toString()).toList(),
        users.where((u) => u['role'] == 'municipal')
            .map((u) => u['id'].toString())
            .toList(),
      );
      print('✓ Waste logs created');

      // Create compost batches
      await _seedCompostBatches(
        users.where((u) => u['role'] == 'farmer')
            .map((u) => u['id'].toString())
            .toList(),
        wasteLogs.map((w) => w['id'].toString()).toList(),
      );
      print('✓ Compost batches created');

      // Create fertilizer requests
      await _seedFertilizerRequests(
        users.where((u) => u['role'] == 'farmer')
            .map((u) => u['id'].toString())
            .toList(),
      );
      print('✓ Fertilizer requests created');

      print('✓ All data seeded successfully!');
    } catch (e) {
      print('Error seeding data: $e');
      rethrow;
    }
  }

  // Seed users
  Future<List<Map<String, dynamic>>> _seedUsers() async {
    final users = <Map<String, dynamic>>[];
    final roles = ['citizen', 'farmer', 'municipal', 'admin'];
    final usersPerRole = {'citizen': 10, 'farmer': 5, 'municipal': 3, 'admin': 1};

    for (final role in roles) {
      for (var i = 0; i < usersPerRole[role]!; i++) {
        final docRef = _firestore.collection('users').doc();
        final userData = {
          'id': docRef.id,
          'name': _faker.person.name(),
          'email': _faker.internet.email(),
          'role': role,
          'totalWaste': role == 'citizen' ? _random.nextDouble() * 100 : 0,
          'totalCompost': role == 'farmer' ? _random.nextDouble() * 200 : 0,
          'rewardPoints': role == 'citizen' ? _random.nextInt(1000) : 0,
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: _random.nextInt(90)))),
          'profileImageUrl': 'https://i.pravatar.cc/150?img=${_random.nextInt(70)}',
        };

        await docRef.set(userData);
        users.add(userData);
      }
    }

    return users;
  }

  // Seed drop-off points
  Future<List<Map<String, dynamic>>> _seedDropOffPoints(List<String> municipalWorkerIds) async {
    final locations = [
      {'name': 'Taman Melati', 'area': 'Wangsa Maju'},
      {'name': 'Taman Setiawangsa', 'area': 'Setiawangsa'},
      {'name': 'Taman Keramat', 'area': 'Keramat'},
      {'name': 'Taman Permata', 'area': 'Gombak'},
    ];

    final dropOffPoints = <Map<String, dynamic>>[];

    for (final location in locations) {
      final docRef = _firestore.collection('dropoff_points').doc();
      final pointData = {
        'id': docRef.id,
        'name': location['name'],
        'area': location['area'],
        'address': _faker.address.streetAddress(),
        'latitude': 3.1579 + _random.nextDouble() * 0.1,
        'longitude': 101.7097 + _random.nextDouble() * 0.1,
        'isOpen': _random.nextBool(),
        'capacity': 1000.0,
        'currentCapacity': _random.nextDouble() * 1000,
        'managedBy': municipalWorkerIds[_random.nextInt(municipalWorkerIds.length)],
        'operatingHours': '8:00 AM - 6:00 PM',
        'lastUpdated': Timestamp.now(),
      };

      await docRef.set(pointData);
      dropOffPoints.add(pointData);
    }

    return dropOffPoints;
  }

  // Seed waste logs
  Future<List<Map<String, dynamic>>> _seedWasteLogs(
    List<String> citizenIds,
    List<String> dropOffPointIds,
    List<String> municipalWorkerIds,
  ) async {
    final wasteLogs = <Map<String, dynamic>>[];
    final wasteTypes = ['organic', 'garden', 'food'];
    final now = DateTime.now();

    // Create logs over the past 90 days
    for (var i = 0; i < 90; i++) {
      final logsPerDay = _random.nextInt(5) + 1; // 1-5 logs per day
      
      for (var j = 0; j < logsPerDay; j++) {
        final logDate = now.subtract(Duration(days: i, hours: _random.nextInt(24)));
        final status = _random.nextBool() ? 'processed' : 'pending';
        
        final docRef = _firestore.collection('waste_logs').doc();
        final logData = {
          'id': docRef.id,
          'userId': citizenIds[_random.nextInt(citizenIds.length)],
          'dropOffPointId': dropOffPointIds[_random.nextInt(dropOffPointIds.length)],
          'weight': 5 + _random.nextDouble() * 20, // 5-25kg
          'wasteType': wasteTypes[_random.nextInt(wasteTypes.length)],
          'timestamp': Timestamp.fromDate(logDate),
          'imageUrl': 'https://picsum.photos/200/300?random=${_random.nextInt(100)}',
          'status': status,
          'verifiedBy': status == 'processed' ? municipalWorkerIds[_random.nextInt(municipalWorkerIds.length)] : null,
        };

        await docRef.set(logData);
        wasteLogs.add(logData);
      }
    }

    return wasteLogs;
  }

  // Seed compost batches
  Future<void> _seedCompostBatches(List<String> farmerIds, List<String> wasteLogIds) async {
    final now = DateTime.now();
    final batchesCount = _random.nextInt(10) + 10; // 10-20 batches

    for (var i = 0; i < batchesCount; i++) {
      final startDate = now.subtract(Duration(days: _random.nextInt(60)));
      final isCompleted = _random.nextBool();
      final inputWeight = 50 + _random.nextDouble() * 150; // 50-200kg input
      
      final docRef = _firestore.collection('compost_batches').doc();
      final batchData = {
        'id': docRef.id,
        'farmerId': farmerIds[_random.nextInt(farmerIds.length)],
        'inputWeight': inputWeight,
        'outputWeight': isCompleted ? inputWeight * 0.3 : 0, // 30% conversion rate
        'startDate': Timestamp.fromDate(startDate),
        'endDate': isCompleted ? Timestamp.fromDate(startDate.add(Duration(days: 30 + _random.nextInt(15)))) : null,
        'status': isCompleted ? 'completed' : 'in_progress',
        'wasteLogIds': wasteLogIds.sublist(0, _random.nextInt(5) + 1), // 1-5 waste logs per batch
        'location': _faker.address.city(),
        'imageUrl': 'https://picsum.photos/200/300?random=${_random.nextInt(100)}',
      };

      await docRef.set(batchData);
    }
  }

  // Seed fertilizer requests
  Future<void> _seedFertilizerRequests(List<String> farmerIds) async {
    final now = DateTime.now();
    final requestsCount = _random.nextInt(20) + 20; // 20-40 requests
    final statuses = ['pending', 'confirmed', 'in_transit', 'delivered'];
    final locations = [
      {'id': 'loc1', 'name': 'North Farm'},
      {'id': 'loc2', 'name': 'South Valley'},
      {'id': 'loc3', 'name': 'East Fields'},
      {'id': 'loc4', 'name': 'West Gardens'},
    ];

    for (var i = 0; i < requestsCount; i++) {
      final requestDate = now.subtract(Duration(days: _random.nextInt(30)));
      final location = locations[_random.nextInt(locations.length)];
      final status = statuses[_random.nextInt(statuses.length)];
      
      final docRef = _firestore.collection('fertilizer_requests').doc();
      final requestData = {
        'id': docRef.id,
        'userId': farmerIds[_random.nextInt(farmerIds.length)],
        'farmerName': _faker.person.name(),
        'farmLocationId': location['id'],
        'farmLocationName': location['name'],
        'quantity': 20 + _random.nextInt(81), // 20-100kg
        'deliveryDate': Timestamp.fromDate(requestDate.add(Duration(days: 7 + _random.nextInt(14)))),
        'specialInstructions': _random.nextBool() ? _faker.lorem.sentence() : '',
        'status': status,
        'timestamp': Timestamp.fromDate(requestDate),
      };

      await docRef.set(requestData);
    }
  }
} 