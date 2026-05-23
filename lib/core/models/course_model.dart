class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructorId;
  final String instructorName;
  final String? thumbnailUrl;
  final String category;
  final double price;
  final int totalLessons;
  final int totalDuration; // in minutes
  final List<String> enrolledStudents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  // Rating Fields
  final double rating;
  final int reviewCount;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorId,
    required this.instructorName,
    this.thumbnailUrl,
    required this.category,
    this.price = 0.0,
    this.totalLessons = 0,
    this.totalDuration = 0,
    this.enrolledStudents = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,

    // Initialize with defaults
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'price': price,
      'totalLessons': totalLessons,
      'totalDuration': totalDuration,
      'enrolledStudents': enrolledStudents,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublished': isPublished,

      //Save to Map
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructorId: map['instructorId'] ?? '',
      instructorName: map['instructorName'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      category: map['category'] ?? 'General',
      price: (map['price'] ?? 0.0).toDouble(),
      totalLessons: map['totalLessons'] ?? 0,
      totalDuration: map['totalDuration'] ?? 0,
      enrolledStudents: List<String>.from(map['enrolledStudents'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      isPublished: map['isPublished'] ?? false,

      // Safely handle int/double conversion
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }

  CourseModel copyWith({
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    double? price,
    int? totalLessons,
    int? totalDuration,
    List<String>? enrolledStudents,
    bool? isPublished,
    double? rating,
    int? reviewCount,
  }) {
    return CourseModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructorId: instructorId,
      instructorName: instructorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      price: price ?? this.price,
      totalLessons: totalLessons ?? this.totalLessons,
      totalDuration: totalDuration ?? this.totalDuration,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPublished: isPublished ?? this.isPublished,

      //Update in CopyWith
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
