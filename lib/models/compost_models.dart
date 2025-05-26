import 'package:cloud_firestore/cloud_firestore.dart';

class CompostEntry {
  final String id;
  final String userId;
  final double wasteAmount;
  final double co2Saved;
  final double compostCreated;
  final DateTime timestamp;

  CompostEntry({
    required this.id,
    required this.userId,
    required this.wasteAmount,
    required this.co2Saved,
    required this.compostCreated,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'wasteAmount': wasteAmount,
      'co2Saved': co2Saved,
      'compostCreated': compostCreated,
      'timestamp': timestamp,
    };
  }

  static CompostEntry fromMap(Map<String, dynamic> map) {
    return CompostEntry(
      id: map['id'],
      userId: map['userId'],
      wasteAmount: map['wasteAmount'],
      co2Saved: map['co2Saved'],
      compostCreated: map['compostCreated'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class FarmerRequest {
  final String id;
  final String farmerId;
  final double requestedAmount;
  final String status; // pending, approved, rejected
  final DateTime requestDate;
  final String? rejectionReason;

  FarmerRequest({
    required this.id,
    required this.farmerId,
    required this.requestedAmount,
    required this.status,
    required this.requestDate,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'requestedAmount': requestedAmount,
      'status': status,
      'requestDate': requestDate,
      'rejectionReason': rejectionReason,
    };
  }

  static FarmerRequest fromMap(Map<String, dynamic> map) {
    return FarmerRequest(
      id: map['id'],
      farmerId: map['farmerId'],
      requestedAmount: map['requestedAmount'],
      status: map['status'],
      requestDate: (map['requestDate'] as Timestamp).toDate(),
      rejectionReason: map['rejectionReason'],
    );
  }
}

class CompostInventory {
  final double totalAvailable;
  final double reserved;
  final double distributed;
  final DateTime lastUpdated;

  CompostInventory({
    required this.totalAvailable,
    required this.reserved,
    required this.distributed,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalAvailable': totalAvailable,
      'reserved': reserved,
      'distributed': distributed,
      'lastUpdated': lastUpdated,
    };
  }

  static CompostInventory fromMap(Map<String, dynamic> map) {
    return CompostInventory(
      totalAvailable: map['totalAvailable'],
      reserved: map['reserved'],
      distributed: map['distributed'],
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

class DeliveryManagement {
  final String id;
  final String requestId;
  final String farmerId;
  final double amount;
  final String status; // pending, in_progress, completed
  final DateTime scheduledDate;
  final DateTime? completedDate;

  DeliveryManagement({
    required this.id,
    required this.requestId,
    required this.farmerId,
    required this.amount,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'farmerId': farmerId,
      'amount': amount,
      'status': status,
      'scheduledDate': scheduledDate,
      'completedDate': completedDate,
    };
  }

  static DeliveryManagement fromMap(Map<String, dynamic> map) {
    return DeliveryManagement(
      id: map['id'],
      requestId: map['requestId'],
      farmerId: map['farmerId'],
      amount: map['amount'],
      status: map['status'],
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      completedDate: map['completedDate'] != null 
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
    );
  }
} 