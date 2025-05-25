import 'package:firebase_core/firebase_core.dart';
import '../lib/scripts/seed_machine_data.dart';

void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    print('Starting to seed machine data...');
    
    // Create and run the seeder
    final seeder = MachineDataSeeder();
    await seeder.seedMachineData();
    
    print('Successfully seeded machine data!');
    
  } catch (e) {
    print('Error seeding data: $e');
  } finally {
    // Ensure the script exits
    print('Done.');
  }
} 