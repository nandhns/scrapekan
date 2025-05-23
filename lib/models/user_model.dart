class UserModel {
  final String id;
  final String email;
  final String name;
  final String role; // 'citizen', 'vendor', 'farmer', 'admin', 'municipal'
  final int points;
  final List<String> completedTasks;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.points = 0,
    this.completedTasks = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'citizen',
      points: json['points'] ?? 0,
      completedTasks: List<String>.from(json['completedTasks'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'points': points,
      'completedTasks': completedTasks,
    };
  }
} 