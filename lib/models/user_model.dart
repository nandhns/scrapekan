import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final String name;
  final String? phoneNumber;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int points;
  final double totalWaste;
  final double totalCompost;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.phoneNumber,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.points,
    required this.totalWaste,
    required this.totalCompost,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'citizen',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      points: data['points'] ?? 0,
      totalWaste: (data['totalWaste'] ?? 0).toDouble(),
      totalCompost: (data['totalCompost'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'points': points,
      'totalWaste': totalWaste,
      'totalCompost': totalCompost,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? points,
    double? totalWaste,
    double? totalCompost,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      points: points ?? this.points,
      totalWaste: totalWaste ?? this.totalWaste,
      totalCompost: totalCompost ?? this.totalCompost,
    );
  }
} 