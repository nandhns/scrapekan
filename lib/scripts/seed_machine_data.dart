import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class MachineDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Helper method to generate random value within range
  double _randomInRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  // Generate realistic temperature values based on time of day
  double _getRealisticTemperature(DateTime timestamp) {
    // Base temperature between 55-65°C for composting
    double baseTemp = _randomInRange(55, 65);
    
    // Add slight variation based on time of day
    int hour = timestamp.hour;
    if (hour >= 10 && hour <= 16) {
      // Higher temps during peak hours
      baseTemp += _randomInRange(2, 5);
    } else if (hour >= 0 && hour <= 5) {
      // Lower temps during night
      baseTemp -= _randomInRange(2, 5);
    }
    
    return baseTemp;
  }

  // Generate realistic moisture values
  double _getRealisticMoisture(DateTime timestamp) {
    // Base moisture between 40-50%
    return _randomInRange(40, 50);
  }

  Future<void> seedMachineData() async {
    try {
      // Define machines
      final machines = [
        {
          'id': 'machine_01',
          'name': 'Machine 01 - Pasar Tani Kekal Pekan',
          'location': 'Pasar Tani Kekal Pekan',
          'capacity': 200.0, // kg
          'installDate': DateTime(2023, 6, 1),
          'lastMaintenance': DateTime.now().subtract(Duration(days: 25)),
          'nextMaintenance': DateTime.now().add(Duration(days: 5)),
        },
        {
          'id': 'machine_02',
          'name': 'Machine 02 - Pasar Tani Kekal Pekan',
          'location': 'Pasar Tani Kekal Pekan',
          'capacity': 200.0, // kg
          'installDate': DateTime(2023, 8, 15),
          'lastMaintenance': DateTime.now().subtract(Duration(days: 45)),
          'nextMaintenance': DateTime.now(),
        },
      ];

      // Seed machine configurations
      for (var machine in machines) {
        await _firestore.collection('machines').doc(machine['id'] as String).set({
          'name': machine['name'],
          'location': machine['location'],
          'capacity': machine['capacity'],
          'installDate': Timestamp.fromDate(machine['installDate'] as DateTime),
          'lastMaintenance': Timestamp.fromDate(machine['lastMaintenance'] as DateTime),
          'nextMaintenance': Timestamp.fromDate(machine['nextMaintenance'] as DateTime),
        });
      }

      // Seed 7 days of monitoring data for each machine
      for (var machine in machines) {
        // Generate data points every hour for the past 7 days
        DateTime startTime = DateTime.now().subtract(Duration(days: 7));
        DateTime endTime = DateTime.now();
        
        for (DateTime time = startTime;
             time.isBefore(endTime);
             time = time.add(Duration(hours: 1))) {
          
          // Generate realistic sensor data
          double temperature = _getRealisticTemperature(time);
          double moisture = _getRealisticMoisture(time);
          double currentCapacity = _randomInRange(50, 180); // Current load in kg
          
          // Calculate processing status (0-100%)
          double processingStatus = _randomInRange(60, 95);
          
          // Simulate machine 2 issues in the last 2 hours
          if (machine['id'] == 'machine_02' && 
              time.isAfter(endTime.subtract(Duration(hours: 2)))) {
            temperature = 85.0; // Temperature issue
            moisture = 25.0; // Moisture issue
            processingStatus = 0.0; // Stopped
          }

          await _firestore
              .collection('machine_monitoring')
              .doc('${machine['id']}_${time.millisecondsSinceEpoch}')
              .set({
            'machineId': machine['id'],
            'timestamp': Timestamp.fromDate(time),
            'temperature': temperature,
            'moisture': moisture,
            'currentCapacity': currentCapacity,
            'processingStatus': processingStatus,
            'isOperating': machine['id'] == 'machine_02' && 
                          time.isAfter(endTime.subtract(Duration(hours: 2)))
                          ? false 
                          : true,
          });
        }

        // Add maintenance alerts for machine 2
        if (machine['id'] == 'machine_02') {
          await _firestore.collection('maintenance_alerts').add({
            'machineId': machine['id'],
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
            'type': 'CRITICAL',
            'message': 'Temperature sensor malfunction detected',
            'status': 'OPEN',
          });

          await _firestore.collection('maintenance_alerts').add({
            'machineId': machine['id'],
            'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 3))),
            'type': 'WARNING',
            'message': 'Moisture levels below normal range',
            'status': 'OPEN',
          });
        }
      }
    } catch (e) {
      print('Error seeding machine data: $e');
      rethrow;
    }
  }
} 