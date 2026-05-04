enum CourseProgress { notStarted, inProgress, completed }

class SavedCourse {
  final String courseId; // matches Course.id from course_data.dart
  final DateTime savedAt;
  final CourseProgress progress;
  final DateTime? completedAt;

  SavedCourse({
    required this.courseId,
    required this.savedAt,
    this.progress = CourseProgress.notStarted,
    this.completedAt,
  });

  // Convert to a Map for storing in Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'savedAt': savedAt.toIso8601String(),
      'progress': progress.name,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Convert from Firestore data
  factory SavedCourse.fromMap(Map<String, dynamic> map) {
    return SavedCourse(
      courseId: map['courseId'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      progress: CourseProgress.values.firstWhere(
        (p) => p.name == map['progress'],
        orElse: () => CourseProgress.notStarted,
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  // Create a copy with updated fields (for progress updates)
  SavedCourse copyWith({CourseProgress? progress, DateTime? completedAt}) {
    return SavedCourse(
      courseId: courseId,
      savedAt: savedAt,
      progress: progress ?? this.progress,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  String get progressLabel {
    switch (progress) {
      case CourseProgress.notStarted:
        return 'Saved';
      case CourseProgress.inProgress:
        return 'In Progress';
      case CourseProgress.completed:
        return 'Completed';
    }
  }
}
