/// A community course review visible to all users for a given course.
class CourseReview {
  final String id;
  final String courseId;
  final String userId;

  /// Display name shown next to the review (first name from Firebase Auth)
  final String userName;

  /// e.g. "2nd Year · Computer Science" or "Bristol student" if anonymous
  final String userContext;

  /// 1 to 5
  final int starRating;

  /// Free-text review body
  final String reviewText;

  /// True if user chose to post anonymously
  final bool isAnonymous;

  final DateTime submittedAt;

  const CourseReview({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.userName,
    required this.userContext,
    required this.starRating,
    required this.reviewText,
    required this.isAnonymous,
    required this.submittedAt,
  });

  /// What other users see — "Bristol student" if anonymous
  String get displayName => isAnonymous ? 'Bristol student' : userName;
  String get displayContext => isAnonymous ? '' : userContext;

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'userId': userId,
      'userName': userName,
      'userContext': userContext,
      'starRating': starRating,
      'reviewText': reviewText,
      'isAnonymous': isAnonymous,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory CourseReview.fromMap(String id, Map<String, dynamic> map) {
    return CourseReview(
      id: id,
      courseId: (map['courseId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? 'Anonymous',
      userContext: (map['userContext'] as String?) ?? '',
      starRating: (map['starRating'] as num?)?.toInt() ?? 0,
      reviewText: (map['reviewText'] as String?) ?? '',
      isAnonymous: (map['isAnonymous'] as bool?) ?? false,
      submittedAt: map['submittedAt'] != null
          ? DateTime.parse(map['submittedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Aggregate stats for a course based on all its reviews.
class CourseReviewStats {
  final int reviewCount;
  final double averageRating;

  const CourseReviewStats({
    required this.reviewCount,
    required this.averageRating,
  });

  static const empty = CourseReviewStats(reviewCount: 0, averageRating: 0);
}
