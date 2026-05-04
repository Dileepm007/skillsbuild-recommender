import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/feedback_models.dart';
import '../models/saved_course.dart';
import '../models/user_profile.dart';
import '../services/feedback_service.dart';
import '../services/recommendation_engine.dart';
import '../services/saved_courses_service.dart';
import '../services/url_launcher_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'profile_input_screen.dart';
import 'dashboard_screen.dart';
import 'feedback_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final UserProfile? profile;

  const RecommendationsScreen({super.key, this.profile});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _savedService = SavedCoursesService();
  final _feedbackService = FeedbackService();
  final _profileService = UserProfileService();

  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveProfile();
  }

  Future<void> _resolveProfile() async {
    if (widget.profile != null) {
      setState(() {
        _profile = widget.profile;
        _isLoading = false;
      });
      return;
    }
    final saved = await _profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = saved;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppHeader(
          currentTab: 'recommendations',
          onTabSelected: (tab) => _navigate(context, tab),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.ibmBlue),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppHeader(
          currentTab: 'recommendations',
          onTabSelected: (tab) => _navigate(context, tab),
        ),
        body: _buildEmptyState(context),
      );
    }

    final recommendations = RecommendationEngine.getRecommendations(
      _profile!,
      topN: 10,
    );

    return Scaffold(
      appBar: AppHeader(
        currentTab: 'recommendations',
        onTabSelected: (tab) => _navigate(context, tab),
      ),
      body: StreamBuilder<List<SavedCourse>>(
        stream: _savedService.watchSavedCourses(),
        builder: (context, savedSnapshot) {
          final savedCourseIds =
              savedSnapshot.data?.map((s) => s.courseId).toSet() ?? {};

          return StreamBuilder<Map<String, CourseFeedback>>(
            stream: _feedbackService.watchCourseFeedback(),
            builder: (context, feedbackSnapshot) {
              final feedbackMap = feedbackSnapshot.data ?? {};

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Personalized Learning Pathway',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ibmBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommendations.isEmpty
                                ? 'No strong matches found. Try adjusting your profile.'
                                : 'We found ${recommendations.length} IBM SkillsBuild courses tailored to your profile',
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.ibmGray,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_profile!.targetJobRole != null ||
                              _profile!.preferredIndustry != null)
                            _buildProfileSummary(),
                          const SizedBox(height: 24),
                          if (recommendations.isEmpty)
                            _buildNoResults(context)
                          else
                            ...recommendations.asMap().entries.map((entry) {
                              final index = entry.key;
                              final scored = entry.value;
                              final isSaved = savedCourseIds.contains(
                                scored.course.id,
                              );
                              final feedback = feedbackMap[scored.course.id];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCourseCard(
                                  scored,
                                  index + 1,
                                  isSaved,
                                  feedback,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleSave(String courseId, bool isSaved) async {
    try {
      if (isSaved) {
        await _savedService.removeSavedCourse(courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from saved courses'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _savedService.saveCourse(courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved! View it in your Dashboard.'),
              backgroundColor: AppTheme.ibmGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startCourse(Course course, bool alreadySaved) async {
    // Open the IBM SkillsBuild URL in a new tab/external browser
    await UrlLauncherService.openCourseUrl(context, course.courseUrl);

    // Auto-save the course if not already saved (better UX — user can find it later)
    if (!alreadySaved) {
      try {
        await _savedService.saveCourse(course.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Course opened on IBM SkillsBuild and saved to your Dashboard',
              ),
              backgroundColor: AppTheme.ibmGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (_) {
        // Silent fail on save — the URL launch already succeeded
      }
    }
  }

  Future<void> _submitFeedback(
    String courseId,
    FeedbackRating newRating,
    CourseFeedback? existing,
  ) async {
    try {
      if (existing != null && existing.rating == newRating) {
        await _feedbackService.removeCourseFeedback(courseId);
      } else {
        await _feedbackService.submitCourseFeedback(courseId, newRating);
        if (mounted) {
          final msg = newRating == FeedbackRating.up
              ? 'Thanks! Glad this was relevant.'
              : 'Thanks for the feedback. We\'ll improve recommendations.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppTheme.ibmBlue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProfileSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ibmLightGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20, color: AppTheme.ibmBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _buildSummaryText(),
              style: const TextStyle(fontSize: 14, color: AppTheme.ibmBlack),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSummaryText() {
    final parts = <String>[];
    if (_profile!.degreeProgram != null) {
      parts.add(_profile!.degreeProgram!);
    }
    if (_profile!.yearOfStudy != null) {
      parts.add(_profile!.yearOfStudy!);
    }
    if (_profile!.targetJobRole != null) {
      parts.add('aspiring ${_profile!.targetJobRole}');
    }
    if (_profile!.preferredIndustry != null) {
      parts.add('in ${_profile!.preferredIndustry}');
    }
    return parts.join(' • ');
  }

  Widget _buildCourseCard(
    ScoredCourse scored,
    int rank,
    bool isSaved,
    CourseFeedback? feedback,
  ) {
    final course = scored.course;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.ibmBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: AppTheme.ibmWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildTag(course.categoryLabel, AppTheme.ibmBlue),
              const SizedBox(width: 8),
              _buildTag(course.levelLabel, _levelColor(course.level)),
              const Spacer(),
              if (course.hasBadge)
                _buildIconTag(
                  Icons.workspace_premium,
                  'Badge',
                  AppTheme.ibmPurple,
                ),
              if (course.hasCertificate) ...[
                const SizedBox(width: 8),
                _buildIconTag(
                  Icons.verified_outlined,
                  'Certificate',
                  AppTheme.ibmGreen,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                course.provider,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.ibmBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: AppTheme.ibmGray),
              const SizedBox(width: 4),
              Text(
                course.durationLabel,
                style: const TextStyle(fontSize: 13, color: AppTheme.ibmGray),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            course.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.ibmBlack,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: course.skillsTaught
                .map((skill) => _buildSkillChip(skill))
                .toList(),
          ),
          const SizedBox(height: 14),
          if (scored.matchReasons.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.ibmBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.ibmBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppTheme.ibmBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why this? ${scored.matchReasons.join(" • ")}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.ibmBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _startCourse(course, isSaved),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Start Course'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _toggleSave(course.id, isSaved),
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  size: 16,
                ),
                label: Text(isSaved ? 'Saved' : 'Save'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isSaved
                      ? AppTheme.ibmGreen
                      : AppTheme.ibmBlue,
                  backgroundColor: isSaved
                      ? AppTheme.ibmGreen.withValues(alpha: 0.08)
                      : null,
                  side: BorderSide(
                    color: isSaved ? AppTheme.ibmGreen : AppTheme.ibmBlue,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Spacer(),
              _buildFeedbackButtons(course.id, feedback),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackButtons(String courseId, CourseFeedback? feedback) {
    final isUp = feedback?.rating == FeedbackRating.up;
    final isDown = feedback?.rating == FeedbackRating.down;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Was this relevant?',
          child: const Text(
            'Relevant?',
            style: TextStyle(fontSize: 12, color: AppTheme.ibmGray),
          ),
        ),
        const SizedBox(width: 8),
        _feedbackIconButton(
          icon: isUp ? Icons.thumb_up : Icons.thumb_up_outlined,
          active: isUp,
          activeColor: AppTheme.ibmGreen,
          onTap: () => _submitFeedback(courseId, FeedbackRating.up, feedback),
        ),
        const SizedBox(width: 6),
        _feedbackIconButton(
          icon: isDown ? Icons.thumb_down : Icons.thumb_down_outlined,
          active: isDown,
          activeColor: const Color(0xFFDA1E28),
          onTap: () => _submitFeedback(courseId, FeedbackRating.down, feedback),
        ),
      ],
    );
  }

  Widget _feedbackIconButton({
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? activeColor : AppTheme.ibmBorderGray,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? activeColor : AppTheme.ibmGray,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIconTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.ibmLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        skill,
        style: const TextStyle(fontSize: 11, color: AppTheme.ibmGray),
      ),
    );
  }

  Color _levelColor(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return AppTheme.ibmGreen;
      case CourseLevel.intermediate:
        return const Color(0xFFF1C21B);
      case CourseLevel.advanced:
        return const Color(0xFFDA1E28);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 64,
              color: AppTheme.ibmLightBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete your profile first',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.ibmBlack,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell us about yourself and we\'ll recommend\nIBM SkillsBuild courses tailored just for you.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.ibmGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileInputScreen()),
                );
              },
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Go to My Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.ibmLightGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppTheme.ibmGray),
          const SizedBox(height: 12),
          const Text(
            'No strong matches yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adding more interests or skills to your profile.',
            style: TextStyle(fontSize: 14, color: AppTheme.ibmGray),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileInputScreen()),
              );
            },
            child: const Text('Update Profile'),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String tab) {
    if (tab == 'recommendations') return;
    Widget screen;
    switch (tab) {
      case 'profile':
        screen = const ProfileInputScreen();
        break;
      case 'dashboard':
        screen = const DashboardScreen();
        break;
      case 'feedback':
        screen = const FeedbackScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
