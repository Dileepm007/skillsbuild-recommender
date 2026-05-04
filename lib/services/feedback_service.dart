import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback_models.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // users/{uid}/course_feedback/{courseId}
  CollectionReference<Map<String, dynamic>>? _courseFeedbackCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('course_feedback');
  }

  // users/{uid}/general_feedback/{autoId}
  CollectionReference<Map<String, dynamic>>? _generalFeedbackCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('general_feedback');
  }

  // PER-COURSE FEEDBACK

  Stream<Map<String, CourseFeedback>> watchCourseFeedback() {
    final collection = _courseFeedbackCollection();
    if (collection == null) return Stream.value({});

    return collection.snapshots().map((snapshot) {
      final map = <String, CourseFeedback>{};
      for (final doc in snapshot.docs) {
        final feedback = CourseFeedback.fromMap(doc.data());
        map[feedback.courseId] = feedback;
      }
      return map;
    });
  }

  Future<void> submitCourseFeedback(
    String courseId,
    FeedbackRating rating,
  ) async {
    final collection = _courseFeedbackCollection();
    if (collection == null) return;

    final feedback = CourseFeedback(
      courseId: courseId,
      rating: rating,
      submittedAt: DateTime.now(),
    );
    await collection.doc(courseId).set(feedback.toMap());
  }

  Future<void> removeCourseFeedback(String courseId) async {
    final collection = _courseFeedbackCollection();
    if (collection == null) return;
    await collection.doc(courseId).delete();
  }

  // GENERAL FEEDBACK

  Stream<List<GeneralFeedback>> watchGeneralFeedback() {
    final collection = _generalFeedbackCollection();
    if (collection == null) return Stream.value([]);

    return collection.orderBy('submittedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => GeneralFeedback.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> submitGeneralFeedback({
    required int starRating,
    required String liked,
    required String improvements,
  }) async {
    final collection = _generalFeedbackCollection();
    if (collection == null) return;

    final docRef = collection.doc();
    final feedback = GeneralFeedback(
      id: docRef.id,
      starRating: starRating,
      liked: liked.trim(),
      improvements: improvements.trim(),
      submittedAt: DateTime.now(),
    );
    await docRef.set(feedback.toMap());
  }
}
