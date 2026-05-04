import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stored at: users/{uid}/profile/data
  DocumentReference<Map<String, dynamic>>? _profileDoc() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profile')
        .doc('data');
  }

  // LIVE stream of the user's profile (null if not yet set)
  Stream<UserProfile?> watchProfile() {
    final doc = _profileDoc();
    if (doc == null) return Stream.value(null);

    return doc.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null || data.isEmpty) return null;
      return UserProfile.fromMap(data);
    });
  }

  // One-shot fetch of the profile
  Future<UserProfile?> getProfile() async {
    final doc = _profileDoc();
    if (doc == null) return null;
    final snap = await doc.get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null || data.isEmpty) return null;
    return UserProfile.fromMap(data);
  }

  // Save/overwrite the profile
  Future<void> saveProfile(UserProfile profile) async {
    final doc = _profileDoc();
    if (doc == null) return;
    final dataToSave = UserProfile(
      degreeProgram: profile.degreeProgram,
      yearOfStudy: profile.yearOfStudy,
      customInterests: profile.customInterests,
      selectedInterests: profile.selectedInterests,
      preferredIndustry: profile.preferredIndustry,
      targetJobRole: profile.targetJobRole,
      existingSkills: profile.existingSkills,
      isUndergraduate: profile.isUndergraduate,
      updatedAt: DateTime.now(),
    );
    await doc.set(dataToSave.toMap());
  }
}
