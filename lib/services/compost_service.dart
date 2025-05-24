import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_schema.dart';
import 'firebase_service.dart';

class CompostService extends FirebaseService {
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
} 