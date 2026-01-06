// lib/core/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? profileImage;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.profileImage,
    required this.createdAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      name: map['name'],
      profileImage: map['profileImage'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Check role helpers
  bool get isStudent => role == 'student';
  bool get isInstructor => role == 'instructor';
}
