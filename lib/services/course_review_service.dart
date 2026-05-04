import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_review.dart';

/// Service that manages community course reviews.
///
/// Reviews are stored at the top-level collection:
///   community_reviews/{courseId}/reviews/{reviewId}
/// so they are visible to ALL users (not nested under user profiles).
///
/// Each user can have only one review per course; the review ID is set to the userId.
class CourseReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _reviewsCollection(
    String courseId,
  ) {
    return _firestore
        .collection('community_reviews')
        .doc(courseId)
        .collection('reviews');
  }

  /// Stream all reviews for a given course, newest first.
  Stream<List<CourseReview>> watchReviewsForCourse(String courseId) {
    return _reviewsCollection(
      courseId,
    ).orderBy('submittedAt', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((doc) => CourseReview.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// One-shot fetch of aggregate stats (count + average rating) for a course.
  Future<CourseReviewStats> getStats(String courseId) async {
    final snap = await _reviewsCollection(courseId).get();
    if (snap.docs.isEmpty) return CourseReviewStats.empty;
    final ratings = snap.docs.map(
      (d) => (d.data()['starRating'] as num?)?.toInt() ?? 0,
    );
    final total = ratings.fold<int>(0, (a, b) => a + b);
    return CourseReviewStats(
      reviewCount: snap.docs.length,
      averageRating: total / snap.docs.length,
    );
  }

  /// Live stream of aggregate stats for a course (count + average).
  Stream<CourseReviewStats> watchStats(String courseId) {
    return _reviewsCollection(courseId).snapshots().map((snap) {
      if (snap.docs.isEmpty) return CourseReviewStats.empty;
      final ratings = snap.docs.map(
        (d) => (d.data()['starRating'] as num?)?.toInt() ?? 0,
      );
      final total = ratings.fold<int>(0, (a, b) => a + b);
      return CourseReviewStats(
        reviewCount: snap.docs.length,
        averageRating: total / snap.docs.length,
      );
    });
  }

  /// Get the current user's existing review for a course (if any).
  Future<CourseReview?> getMyReview(String courseId) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _reviewsCollection(courseId).doc(user.uid).get();
    if (!doc.exists) return null;
    return CourseReview.fromMap(doc.id, doc.data()!);
  }

  /// Submit or update a review. Each user has one review per course (keyed by uid).
  Future<void> submitReview({
    required String courseId,
    required int starRating,
    required String reviewText,
    required bool isAnonymous,
    required String userName,
    required String userContext,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to leave a review.');
    }

    final review = CourseReview(
      id: user.uid,
      courseId: courseId,
      userId: user.uid,
      userName: userName,
      userContext: userContext,
      starRating: starRating,
      reviewText: reviewText.trim(),
      isAnonymous: isAnonymous,
      submittedAt: DateTime.now(),
    );

    await _reviewsCollection(courseId).doc(user.uid).set(review.toMap());
  }

  /// Delete the current user's review for a course.
  Future<void> deleteMyReview(String courseId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _reviewsCollection(courseId).doc(user.uid).delete();
  }
}
