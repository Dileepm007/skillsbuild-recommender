import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_course.dart';

class SavedCoursesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore path: users/{userId}/saved_courses/{courseId}
  CollectionReference<Map<String, dynamic>>? _userCoursesCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_courses');
  }

  // LIVE stream of saved courses - UI auto-updates when data changes
  Stream<List<SavedCourse>> watchSavedCourses() {
    final collection = _userCoursesCollection();
    if (collection == null) return Stream.value([]);

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SavedCourse.fromMap(doc.data());
      }).toList();
    });
  }

  // Save a course (or update if already saved)
  Future<void> saveCourse(String courseId) async {
    final collection = _userCoursesCollection();
    if (collection == null) return;

    final savedCourse = SavedCourse(
      courseId: courseId,
      savedAt: DateTime.now(),
      progress: CourseProgress.notStarted,
    );

    await collection.doc(courseId).set(savedCourse.toMap());
  }

  // Remove a saved course
  Future<void> removeSavedCourse(String courseId) async {
    final collection = _userCoursesCollection();
    if (collection == null) return;

    await collection.doc(courseId).delete();
  }

  // Update the progress of a saved course
  Future<void> updateProgress(String courseId, CourseProgress progress) async {
    final collection = _userCoursesCollection();
    if (collection == null) return;

    final data = {
      'progress': progress.name,
      'completedAt': progress == CourseProgress.completed
          ? DateTime.now().toIso8601String()
          : null,
    };

    await collection.doc(courseId).update(data);
  }

  // Check if a specific course is already saved
  Future<bool> isCourseSaved(String courseId) async {
    final collection = _userCoursesCollection();
    if (collection == null) return false;

    final doc = await collection.doc(courseId).get();
    return doc.exists;
  }
}
