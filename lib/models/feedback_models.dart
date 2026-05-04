// Per-course feedback (thumbs up/down on recommendations)
enum FeedbackRating { up, down }

class CourseFeedback {
  final String courseId;
  final FeedbackRating rating;
  final DateTime submittedAt;

  CourseFeedback({
    required this.courseId,
    required this.rating,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'rating': rating.name,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory CourseFeedback.fromMap(Map<String, dynamic> map) {
    return CourseFeedback(
      courseId: map['courseId'] as String,
      rating: FeedbackRating.values.firstWhere(
        (r) => r.name == map['rating'],
        orElse: () => FeedbackRating.up,
      ),
      submittedAt: DateTime.parse(map['submittedAt'] as String),
    );
  }
}

// General feedback submission
class GeneralFeedback {
  final String id;
  final int starRating; // 1-5
  final String liked;
  final String improvements;
  final DateTime submittedAt;

  GeneralFeedback({
    required this.id,
    required this.starRating,
    required this.liked,
    required this.improvements,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'starRating': starRating,
      'liked': liked,
      'improvements': improvements,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory GeneralFeedback.fromMap(Map<String, dynamic> map) {
    return GeneralFeedback(
      id: map['id'] as String,
      starRating: (map['starRating'] as num).toInt(),
      liked: map['liked'] as String? ?? '',
      improvements: map['improvements'] as String? ?? '',
      submittedAt: DateTime.parse(map['submittedAt'] as String),
    );
  }
}
