// lib/core/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? profileImage;
  final DateTime createdAt;

  //NEW FIELDS ADDED
  final String? phone;
  final Map<String, dynamic>? socials;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.profileImage,
    required this.createdAt,
    this.phone,
    this.socials,
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
      // Serialize new fields
      'phone': phone,
      'socials': socials,
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
      // Deserialize new fields
      phone: map['phone'],
      // Safely convert Map<dynamic, dynamic> to Map<String, dynamic>
      socials: map['socials'] != null
          ? Map<String, dynamic>.from(map['socials'])
          : null,
    );
  }

  // Check role helpers
  bool get isStudent => role == 'student';
  bool get isInstructor => role == 'instructor';
}
