import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';
import 'package:rxdart/rxdart.dart';

class WasteService extends FirebaseService {
  // Stream controller for current user's waste logs
  final _userWasteLogsController = BehaviorSubject<List<WasteLog>>();
  
  // Stream getters
  Stream<List<WasteLog>> get userWasteLogs => _userWasteLogsController.stream;

  // Constructor
  WasteService() {
    print('Initializing WasteService');
    // Start listening to auth changes
    _initializeStreams();
  }

  void _initializeStreams() {
    print('Setting up auth state listener');
    // Listen to auth changes
    auth_.authStateChanges().listen(
      (user) {
        if (user != null) {
          print('User logged in: ${user.uid}');
          // User is logged in, start real-time updates
          _startUserWasteLogsStream(user.uid);
        } else {
          print('User logged out, clearing data');
          // User logged out, clear data
          _userWasteLogsController.add([]);
        }
      },
      onError: (error) {
        print('Error in auth state changes: $error');
        _userWasteLogsController.addError(error);
      },
    );
  }

  void _startUserWasteLogsStream(String userId) {
    print('Starting waste logs stream for user: $userId');
    try {
      final query = wasteLogsRef
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);
      
      print('Created query: ${query.parameters}');

      query.snapshots().listen(
        (snapshot) {
          print('Received snapshot with ${snapshot.docs.length} documents');
          try {
            final logs = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                print('Processing document ${doc.id}: ${data.toString()}');
                
                return WasteLog(
                  id: doc.id,
                  userId: data['userId'] as String? ?? '',
                  dropOffPointId: data['dropOffPointId'] as String? ?? '',
                  weight: ((data['weight'] as num?) ?? 0).toDouble(),
                  wasteType: data['wasteType'] as String? ?? 'unknown',
                  timestamp: ((data['timestamp'] as Timestamp?) ?? Timestamp.now()).toDate(),
                  imageUrl: data['imageUrl'] as String? ?? '',
                  status: data['status'] as String?,
                  verifiedBy: data['verifiedBy'] as String?,
                  data: data,  // Include the raw data
                );
              } catch (e) {
                print('Error processing waste log document: $e');
                return null;
              }
            })
            .where((log) => log != null)
            .cast<WasteLog>()
            .toList();

            print('Processed ${logs.length} valid waste logs');
            _userWasteLogsController.add(logs);
          } catch (e) {
            print('Error processing snapshot: $e');
            _userWasteLogsController.addError(e);
          }
        },
        onError: (e) {
          print('Error in waste logs stream: $e');
          _userWasteLogsController.addError(e);
        },
      );
    } catch (e) {
      print('Error setting up waste logs stream: $e');
      _userWasteLogsController.addError(e);
    }
  }

  // Log new waste
  Future<void> logWaste(WasteLog wasteLog) async {
    try {
      final batch = firestore_.batch();
      
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
      if (!dropoffPoint.exists) {
        throw Exception('Drop-off point not found');
      }
      
      final data = dropoffPoint.data();
      if (data == null) {
        throw Exception('Drop-off point data is null');
      }
      
      final managedBy = data['managedBy'] as String?;
      if (managedBy == null) {
        throw Exception('Drop-off point managedBy is null');
      }

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
    } catch (e) {
      print('Error in logWaste: $e');
      rethrow;
    }
  }

  // Get drop-off point waste logs
  Stream<List<WasteLog>> getDropOffPointWasteLogs(String dropOffPointId) {
    print('Getting waste logs for drop-off point: $dropOffPointId');
    try {
      final query = wasteLogsRef
          .where('dropOffPointId', isEqualTo: dropOffPointId)
          .orderBy('timestamp', descending: true);
      
      return query.snapshots().map((snapshot) {
        print('Received ${snapshot.docs.length} waste logs for drop-off point');
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return WasteLog(
              id: doc.id,
              userId: data['userId'] as String? ?? '',
              dropOffPointId: data['dropOffPointId'] as String? ?? '',
              weight: ((data['weight'] as num?) ?? 0).toDouble(),
              wasteType: data['wasteType'] as String? ?? 'unknown',
              timestamp: ((data['timestamp'] as Timestamp?) ?? Timestamp.now()).toDate(),
              imageUrl: data['imageUrl'] as String? ?? '',
              status: data['status'] as String?,
              verifiedBy: data['verifiedBy'] as String?,
              data: data,  // Include the raw data
            );
          } catch (e) {
            print('Error processing drop-off point waste log: $e');
            return null;
          }
        })
        .where((log) => log != null)
        .cast<WasteLog>()
        .toList();
      });
    } catch (e) {
      print('Error in getDropOffPointWasteLogs: $e');
      rethrow;
    }
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

  // Cleanup
  void dispose() {
    _userWasteLogsController.close();
  }
} 