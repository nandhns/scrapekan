import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';
import '../models/compost_models.dart';

class CompostService extends FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new compost batch
  Future<void> createCompostBatch(CompostBatch batch) async {
    final batchWrite = FirebaseFirestore.instance.batch();
    
    // Create compost batch
    final batchRef = compostBatchesRef.doc();
    batchWrite.set(batchRef, {
      ...batch.toMap(),
      'id': batchRef.id,
    });

    // Update waste logs status
    for (String logId in batch.wasteLogIds) {
      batchWrite.update(wasteLogsRef.doc(logId), {
        'status': 'in_composting',
      });
    }

    // Update farmer's total compost input
    batchWrite.update(usersRef.doc(batch.farmerId), {
      'totalCompost': FieldValue.increment(batch.inputWeight),
    });

    await batchWrite.commit();

    // Notify municipal workers
    final wasteLogs = await wasteLogsRef
        .where(FieldPath.documentId, whereIn: batch.wasteLogIds)
        .get();
    
    final dropOffPointIds = wasteLogs.docs
        .map((doc) => doc['dropOffPointId'] as String)
        .toSet();

    final dropOffPoints = await dropoffPointsRef
        .where(FieldPath.documentId, whereIn: dropOffPointIds.toList())
        .get();

    for (var point in dropOffPoints.docs) {
      await notificationsRef.add(NotificationModel(
        id: '',
        recipientId: point['managedBy'],
        title: 'New Compost Batch',
        message: 'Farmer started composting waste from your drop-off point',
        type: 'compost_started',
        read: false,
        timestamp: DateTime.now(),
        data: {
          'batchId': batchRef.id,
          'dropOffPointId': point.id,
        },
      ).toMap());
    }
  }

  // Get farmer's active batches
  Stream<List<CompostBatch>> getFarmerActiveBatches(String farmerId) {
    return compostBatchesRef
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'active')
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompostBatch(
                  id: doc.id,
                  farmerId: doc['farmerId'],
                  inputWeight: doc['inputWeight'],
                  outputWeight: doc['outputWeight'],
                  startDate: (doc['startDate'] as Timestamp).toDate(),
                  endDate: doc['endDate'] != null
                      ? (doc['endDate'] as Timestamp).toDate()
                      : null,
                  status: doc['status'],
                  wasteLogIds: List<String>.from(doc['wasteLogIds']),
                  location: doc['location'],
                  imageUrl: doc['imageUrl'],
                ))
            .toList());
  }

  // Complete compost batch
  Future<void> completeCompostBatch(
    String batchId,
    double outputWeight,
    String? imageUrl,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Update batch status
    batch.update(compostBatchesRef.doc(batchId), {
      'status': 'completed',
      'endDate': DateTime.now(),
      'outputWeight': outputWeight,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });

    final batchDoc = await compostBatchesRef.doc(batchId).get();
    final batchData = batchDoc.data() as Map<String, dynamic>;

    // Update waste logs status
    for (String logId in List<String>.from(batchData['wasteLogIds'])) {
      batch.update(wasteLogsRef.doc(logId), {
        'status': 'composted',
      });
    }

    await batch.commit();

    // Create notifications
    final wasteLogs = await wasteLogsRef
        .where(FieldPath.documentId, whereIn: batchData['wasteLogIds'])
        .get();

    final userIds = wasteLogs.docs
        .map((doc) => doc['userId'] as String)
        .toSet();

    for (String userId in userIds) {
      await notificationsRef.add(NotificationModel(
        id: '',
        recipientId: userId,
        title: 'Compost Batch Completed',
        message: 'Your waste has been successfully composted',
        type: 'compost_completed',
        read: false,
        timestamp: DateTime.now(),
        data: {'batchId': batchId},
      ).toMap());
    }
  }

  // Get compost statistics
  Future<Map<String, dynamic>> getCompostStatistics(String farmerId) async {
    final completedBatches = await compostBatchesRef
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'completed')
        .get();

    double totalInput = 0;
    double totalOutput = 0;
    int batchCount = completedBatches.size;

    for (var doc in completedBatches.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalInput += data['inputWeight'] as double;
      totalOutput += (data['outputWeight'] as double?) ?? 0;
    }

    return {
      'totalInput': totalInput,
      'totalOutput': totalOutput,
      'batchCount': batchCount,
      'averageEfficiency': batchCount > 0 ? (totalOutput / totalInput) * 100 : 0,
    };
  }

  // Citizen Functions
  Future<void> addCompostEntry(CompostEntry entry) async {
    await _firestore.collection('compost_entries').doc(entry.id).set(entry.toMap());
    
    // Update inventory
    await _updateInventory(entry.compostCreated);
  }

  Future<void> _updateInventory(double newCompost) async {
    final inventoryRef = _firestore.collection('inventory').doc('compost');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inventoryRef);
      if (snapshot.exists) {
        final currentInventory = CompostInventory.fromMap(snapshot.data()!);
        final newTotal = currentInventory.totalAvailable + newCompost;
        
        transaction.update(inventoryRef, {
          'totalAvailable': newTotal,
          'lastUpdated': DateTime.now(),
        });
      } else {
        transaction.set(inventoryRef, {
          'totalAvailable': newCompost,
          'reserved': 0.0,
          'distributed': 0.0,
          'lastUpdated': DateTime.now(),
        });
      }
    });
  }

  // Farmer Functions
  Future<void> submitFarmerRequest(FarmerRequest request) async {
    await _firestore.collection('farmer_requests').doc(request.id).set(request.toMap());
  }

  Future<void> processFarmerRequest(String requestId, bool approved, {String? rejectionReason}) async {
    final requestRef = _firestore.collection('farmer_requests').doc(requestId);
    final inventoryRef = _firestore.collection('inventory').doc('compost');

    await _firestore.runTransaction((transaction) async {
      final requestDoc = await transaction.get(requestRef);
      final inventoryDoc = await transaction.get(inventoryRef);

      if (!requestDoc.exists || !inventoryDoc.exists) {
        throw Exception('Request or inventory not found');
      }

      final request = FarmerRequest.fromMap(requestDoc.data()!);
      final inventory = CompostInventory.fromMap(inventoryDoc.data()!);

      if (approved) {
        if (inventory.totalAvailable < request.requestedAmount) {
          throw Exception('Insufficient compost available');
        }

        // Update request status
        transaction.update(requestRef, {
          'status': 'approved',
        });

        // Update inventory
        transaction.update(inventoryRef, {
          'totalAvailable': inventory.totalAvailable - request.requestedAmount,
          'reserved': inventory.reserved + request.requestedAmount,
          'lastUpdated': DateTime.now(),
        });

        // Create delivery entry
        final deliveryRef = _firestore.collection('deliveries').doc();
        final delivery = DeliveryManagement(
          id: deliveryRef.id,
          requestId: requestId,
          farmerId: request.farmerId,
          amount: request.requestedAmount,
          status: 'pending',
          scheduledDate: DateTime.now(),
        );
        transaction.set(deliveryRef, delivery.toMap());
      } else {
        transaction.update(requestRef, {
          'status': 'rejected',
          'rejectionReason': rejectionReason,
        });
      }
    });
  }

  // Admin Functions
  Stream<CompostInventory> getInventoryStream() {
    return _firestore
        .collection('inventory')
        .doc('compost')
        .snapshots()
        .map((doc) => CompostInventory.fromMap(doc.data()!));
  }

  Stream<List<FarmerRequest>> getPendingRequestsStream() {
    return _firestore
        .collection('farmer_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => FarmerRequest.fromMap(doc.data())).toList());
  }

  Stream<List<DeliveryManagement>> getPendingDeliveriesStream() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => DeliveryManagement.fromMap(doc.data())).toList());
  }

  // Delivery Management
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    final deliveryRef = _firestore.collection('deliveries').doc(deliveryId);
    final inventoryRef = _firestore.collection('inventory').doc('compost');

    await _firestore.runTransaction((transaction) async {
      final deliveryDoc = await transaction.get(deliveryRef);
      final inventoryDoc = await transaction.get(inventoryRef);

      if (!deliveryDoc.exists || !inventoryDoc.exists) {
        throw Exception('Delivery or inventory not found');
      }

      final delivery = DeliveryManagement.fromMap(deliveryDoc.data()!);
      final inventory = CompostInventory.fromMap(inventoryDoc.data()!);

      if (status == 'completed') {
        transaction.update(inventoryRef, {
          'reserved': inventory.reserved - delivery.amount,
          'distributed': inventory.distributed + delivery.amount,
          'lastUpdated': DateTime.now(),
        });
      }

      transaction.update(deliveryRef, {
        'status': status,
        'completedDate': status == 'completed' ? DateTime.now() : null,
      });
    });
  }
} 