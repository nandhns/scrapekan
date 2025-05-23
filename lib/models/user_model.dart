import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'citizen', 'vendor', 'farmer', 'admin', 'municipal'
  final int points;
  final double totalWaste;
  final double co2Saved;
  final List<String> completedTasks;
  final List<String> achievements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.points,
    required this.totalWaste,
    required this.co2Saved,
    required this.completedTasks,
    required this.achievements,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      points: json['points'] as int? ?? 0,
      totalWaste: (json['totalWaste'] as num?)?.toDouble() ?? 0.0,
      co2Saved: (json['co2Saved'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (json['completedTasks'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      achievements: (json['achievements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> doc) {
    return UserModel(
      id: doc['id'] as String,
      email: doc['email'] as String,
      name: doc['name'] as String,
      role: doc['role'] as String,
      points: doc['points'] as int? ?? 0,
      totalWaste: (doc['totalWaste'] as num?)?.toDouble() ?? 0.0,
      co2Saved: (doc['co2Saved'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (doc['completedTasks'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      achievements: (doc['achievements'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: doc['createdAt'] != null ? (doc['createdAt'] as Timestamp).toDate() : null,
      updatedAt: doc['updatedAt'] != null ? (doc['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'points': points,
      'totalWaste': totalWaste,
      'co2Saved': co2Saved,
      'completedTasks': completedTasks,
      'achievements': achievements,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'points': points,
      'totalWaste': totalWaste,
      'co2Saved': co2Saved,
      'completedTasks': completedTasks,
      'achievements': achievements,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    int? points,
    double? totalWaste,
    double? co2Saved,
    List<String>? completedTasks,
    List<String>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      points: points ?? this.points,
      totalWaste: totalWaste ?? this.totalWaste,
      co2Saved: co2Saved ?? this.co2Saved,
      completedTasks: completedTasks ?? this.completedTasks,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 