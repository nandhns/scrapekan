import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';

class WasteService extends FirebaseService {
  // Log new waste
  Future<void> logWaste(WasteLog wasteLog) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Add waste log
    final wasteLogRef = wasteLogsRef.doc();
    batch.set(wasteLogRef, {
      ...wasteLog.toMap(),
      'id': wasteLogRef.id,
    });

    // Update user's total waste
    batch.update(usersRef.doc(wasteLog.userId), {
      'totalWaste': FieldValue.increment(wasteLog.weight),
      'rewardPoints': FieldValue.increment((wasteLog.weight * 10).round()), // 10 points per kg
    });

    // Update drop-off point capacity
    batch.update(dropoffPointsRef.doc(wasteLog.dropOffPointId), {
      'currentCapacity': FieldValue.increment(wasteLog.weight),
      'lastUpdated': DateTime.now(),
    });

    await batch.commit();

    // Create notification for municipal worker
    final dropoffPoint = await dropoffPointsRef.doc(wasteLog.dropOffPointId).get();
    final managedBy = (dropoffPoint.data() as Map<String, dynamic>)['managedBy'];

    await notificationsRef.add(NotificationModel(
      id: '',
      recipientId: managedBy,
      title: 'New Waste Drop-off',
      message: 'New waste drop-off of ${wasteLog.weight}kg',
      type: 'waste_dropoff',
      read: false,
      timestamp: DateTime.now(),
      data: {'wasteLogId': wasteLogRef.id},
    ).toMap());
  }

  // Get user's waste history
  Stream<List<WasteLog>> getUserWasteHistory(String userId) {
    print('Getting waste history for user: $userId');
    try {
      return wasteLogsRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            print('Received ${snapshot.docs.length} waste logs');
            return snapshot.docs.map((doc) {
              Map<String, dynamic> data;
              try {
                data = doc.data() as Map<String, dynamic>;
                print('Processing waste log: ${doc.id}');
              } catch (e) {
                print('Error processing document ${doc.id}: $e');
                return null;
              }
              
              try {
                return WasteLog(
                  id: doc.id,
                  userId: data['userId'] as String? ?? '',
                  dropOffPointId: data['dropOffPointId'] as String? ?? '',
                  weight: ((data['weight'] as num?) ?? 0).toDouble(),
                  wasteType: data['wasteType'] as String? ?? 'unknown',
                  timestamp: ((data['timestamp'] as Timestamp?) ?? Timestamp.now()).toDate(),
                  imageUrl: data['imageUrl'] as String? ?? '',
                  status: 'composted', // Always set as composted for citizens
                  verifiedBy: null,
                );
              } catch (e) {
                print('Error creating WasteLog from data: $e');
                return null;
              }
            })
            .where((log) => log != null)
            .cast<WasteLog>()
            .toList();
          });
    } catch (e) {
      print('Error in getUserWasteHistory: $e');
      rethrow;
    }
  }

  // Get drop-off point waste logs
  Stream<List<WasteLog>> getDropOffPointWasteLogs(String dropOffPointId) {
    return wasteLogsRef
        .where('dropOffPointId', isEqualTo: dropOffPointId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return WasteLog(
                id: doc.id,
                userId: data['userId'] as String? ?? '',
                dropOffPointId: data['dropOffPointId'] as String? ?? '',
                weight: ((data['weight'] as num?) ?? 0).toDouble(),
                wasteType: data['wasteType'] as String? ?? 'unknown',
                timestamp: ((data['timestamp'] as Timestamp?) ?? Timestamp.now()).toDate(),
                imageUrl: data['imageUrl'] as String? ?? '',
                status: data['status'] as String? ?? 'pending',
                verifiedBy: data['verifiedBy'] as String?,
              );
            })
            .toList());
  }

  // Verify waste log
  Future<void> verifyWasteLog(String wasteLogId, String municipalWorkerId) async {
    await wasteLogsRef.doc(wasteLogId).update({
      'status': 'verified',
      'verifiedBy': municipalWorkerId,
    });

    final wasteLog = await wasteLogsRef.doc(wasteLogId).get();
    final data = wasteLog.data() as Map<String, dynamic>;

    // Notify the user
    await notificationsRef.add(NotificationModel(
      id: '',
      recipientId: data['userId'],
      title: 'Waste Verified',
      message: 'Your waste drop-off has been verified',
      type: 'waste_verified',
      read: false,
      timestamp: DateTime.now(),
      data: {'wasteLogId': wasteLogId},
    ).toMap());
  }

  // Get available drop-off points
  Stream<List<DropoffPointModel>> getAvailableDropOffPoints() {
    return dropoffPointsRef
        .where('isOpen', isEqualTo: true)
        .orderBy('currentCapacity', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DropoffPointModel(
                  id: doc.id,
                  name: doc['name'],
                  address: doc['address'],
                  location: doc['location'],
                  type: doc['type'],
                  openingHours: doc['openingHours'],
                  isOpen: doc['isOpen'],
                  currentCapacity: doc['currentCapacity'],
                  maxCapacity: doc['maxCapacity'],
                  lastUpdated: (doc['lastUpdated'] as Timestamp).toDate(),
                  managedBy: doc['managedBy'],
                ))
            .toList());
  }
} 