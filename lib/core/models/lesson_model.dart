// lib/core/models/lesson_model.dart

enum LessonType { video, document, quiz }

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final LessonType type;
  final String? videoUrl; // ✅ Can have video
  final String? documentUrl; // ✅ Can have document (both at same time!)
  final String? thumbnailUrl;
  final int duration;
  final int orderIndex;
  final bool isFree;
  final DateTime createdAt;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.type,
    this.videoUrl,
    this.documentUrl,
    this.thumbnailUrl,
    this.duration = 0,
    required this.orderIndex,
    this.isFree = false,
    required this.createdAt,
  });

  // ✅ Check what content the lesson has
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasDocument => documentUrl != null && documentUrl!.isNotEmpty;
  bool get hasBoth => hasVideo && hasDocument;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'type': type.name,
      'videoUrl': videoUrl,
      'documentUrl': documentUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'orderIndex': orderIndex,
      'isFree': isFree,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      type: LessonType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => LessonType.video,
      ),
      videoUrl: map['videoUrl'],
      documentUrl: map['documentUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      duration: map['duration'] ?? 0,
      orderIndex: map['orderIndex'] ?? 0,
      isFree: map['isFree'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
