import '../models/course.dart';
import '../models/user_profile.dart';
import '../data/course_data.dart';

class ScoredCourse {
  final Course course;
  final int score;
  final List<String> matchReasons; // for showing "Why this was recommended"

  ScoredCourse({
    required this.course,
    required this.score,
    required this.matchReasons,
  });
}

class RecommendationEngine {
  /// Returns the top N courses ranked by match score for the given user profile.
  static List<ScoredCourse> getRecommendations(
    UserProfile profile, {
    int topN = 10,
  }) {
    final List<ScoredCourse> scoredCourses = [];

    for (final course in CourseData.allCourses) {
      int score = 0;
      final List<String> reasons = [];

      // 1. Job role match (strongest weight: +10)
      if (profile.targetJobRole != null &&
          course.relatedJobRoles.contains(profile.targetJobRole)) {
        score += 10;
        reasons.add('Matches your target role: ${profile.targetJobRole}');
      }

      // 2. Industry match (+5)
      if (profile.preferredIndustry != null &&
          course.relatedIndustries.contains(profile.preferredIndustry)) {
        score += 5;
        reasons.add('Relevant to ${profile.preferredIndustry}');
      }

      // 3. Interest match (+7 per matched interest)
      final userInterests = profile.allInterests
          .map((s) => s.toLowerCase())
          .toList();
      int interestMatches = 0;
      for (final courseInterest in course.relatedInterests) {
        if (userInterests.any(
          (ui) =>
              ui.contains(courseInterest.toLowerCase()) ||
              courseInterest.toLowerCase().contains(ui),
        )) {
          interestMatches++;
        }
      }
      if (interestMatches > 0) {
        score += interestMatches * 7;
        reasons.add('Matches $interestMatches of your interests');
      }

      // 4. Skill gap bonus: teaches skills user doesn't have (+3 each)
      int newSkillsCount = 0;
      for (final skill in course.skillsTaught) {
        if (!profile.existingSkills.contains(skill)) {
          newSkillsCount++;
        }
      }
      if (newSkillsCount > 0) {
        score += newSkillsCount * 3;
        reasons.add('Teaches $newSkillsCount new skills');
      }

      // 5. Skill overlap penalty (-1 per skill already known)
      int overlapCount = 0;
      for (final skill in course.skillsTaught) {
        if (profile.existingSkills.contains(skill)) {
          overlapCount++;
        }
      }
      score -= overlapCount;

      // 6. Level boost for early-year students (+3 for beginner courses)
      if (profile.isEarlyYear && course.level == CourseLevel.beginner) {
        score += 3;
        reasons.add('Great starting point');
      }

      // Only include courses with some match
      if (score > 0) {
        scoredCourses.add(
          ScoredCourse(course: course, score: score, matchReasons: reasons),
        );
      }
    }

    // Sort by score (highest first) and return top N
    scoredCourses.sort((a, b) => b.score.compareTo(a.score));
    return scoredCourses.take(topN).toList();
  }

  /// Groups recommended courses by category (for pathway-style display)
  static Map<CourseCategory, List<ScoredCourse>> groupByCategory(
    List<ScoredCourse> scoredCourses,
  ) {
    final Map<CourseCategory, List<ScoredCourse>> grouped = {};
    for (final scored in scoredCourses) {
      grouped.putIfAbsent(scored.course.category, () => []).add(scored);
    }
    return grouped;
  }
}
