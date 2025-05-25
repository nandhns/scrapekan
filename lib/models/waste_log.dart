import 'package:cloud_firestore/cloud_firestore.dart';

class WasteLog {
  final String id;
  final String userId;
  final String dropOffPointId;
  final double weight;
  final String wasteType;
  final DateTime timestamp;
  final String status;
  final String? imageUrl;

  WasteLog({
    required this.id,
    required this.userId,
    required this.dropOffPointId,
    required this.weight,
    required this.wasteType,
    required this.timestamp,
    required this.status,
    this.imageUrl,
  });

  factory WasteLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WasteLog(
      id: doc.id,
      userId: data['userId'] as String,
      dropOffPointId: data['dropOffPointId'] as String,
      weight: (data['weight'] as num).toDouble(),
      wasteType: data['wasteType'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] as String,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dropOffPointId': dropOffPointId,
      'weight': weight,
      'wasteType': wasteType,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'imageUrl': imageUrl,
    };
  }
} 