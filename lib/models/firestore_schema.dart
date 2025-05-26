import 'package:cloud_firestore/cloud_firestore.dart';

// User Roles
enum UserRole {
  citizen,
  farmer,
  municipal,
  admin,
}

// User Model
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final double totalWaste;
  final double totalCompost;
  final int rewardPoints;
  final DateTime createdAt;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.totalWaste = 0,
    this.totalCompost = 0,
    this.rewardPoints = 0,
    required this.createdAt,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.toString(),
    'totalWaste': totalWaste,
    'totalCompost': totalCompost,
    'rewardPoints': rewardPoints,
    'createdAt': createdAt,
    'profileImageUrl': profileImageUrl,
  };
}

// Waste Log Model
class WasteLog {
  final String id;
  final String userId;
  final String dropOffPointId;
  final double weight;
  final String wasteType;
  final DateTime timestamp;
  final String imageUrl;
  final String? status;
  final String? verifiedBy;
  final Map<String, dynamic>? data;

  WasteLog({
    required this.id,
    required this.userId,
    required this.dropOffPointId,
    required this.weight,
    required this.wasteType,
    required this.timestamp,
    required this.imageUrl,
    this.status,
    this.verifiedBy,
    this.data,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'userId': userId,
      'dropOffPointId': dropOffPointId,
      'weight': weight,
      'wasteType': wasteType,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'status': status as String?,
      'verifiedBy': verifiedBy as String?,
    };
    
    map.removeWhere((key, value) => value == null);
    
    return map;
  }
}

// Drop-off Point Model
class DropoffPointModel {
  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final String type;
  final Map<String, String> openingHours;
  final bool isOpen;
  final double currentCapacity;
  final double maxCapacity;
  final DateTime lastUpdated;
  final String managedBy;

  DropoffPointModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.type,
    required this.openingHours,
    required this.isOpen,
    required this.currentCapacity,
    required this.maxCapacity,
    required this.lastUpdated,
    required this.managedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'type': type,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'currentCapacity': currentCapacity,
      'maxCapacity': maxCapacity,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'managedBy': managedBy,
    };
  }
}

// Compost Batch Model
class CompostBatch {
  final String id;
  final String farmerId;
  final double inputWeight;
  final double outputWeight;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final List<String> wasteLogIds;
  final String location;
  final String imageUrl;

  CompostBatch({
    required this.id,
    required this.farmerId,
    required this.inputWeight,
    required this.outputWeight,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.wasteLogIds,
    required this.location,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'inputWeight': inputWeight,
      'outputWeight': outputWeight,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'status': status,
      'wasteLogIds': wasteLogIds,
      'location': location,
      'imageUrl': imageUrl,
    };
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    required this.timestamp,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'read': read,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
    };
  }
}

// Reward Model
class RewardModel {
  final String id;
  final String userId;
  final int points;
  final String type;
  final String status; // available, redeemed
  final DateTime earnedAt;
  final DateTime? redeemedAt;
  final String? redeemedLocation;

  RewardModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.status,
    required this.earnedAt,
    this.redeemedAt,
    this.redeemedLocation,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'points': points,
    'type': type,
    'status': status,
    'earnedAt': earnedAt,
    'redeemedAt': redeemedAt,
    'redeemedLocation': redeemedLocation,
  };
} 