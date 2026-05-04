import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/course_data.dart';
import '../models/course.dart';
import '../models/course_review.dart';
import '../models/saved_course.dart';
import '../models/user_profile.dart';
import '../services/course_review_service.dart';
import '../services/saved_courses_service.dart';
import '../services/url_launcher_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'profile_input_screen.dart';
import 'recommendations_screen.dart';
import 'feedback_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _savedService = SavedCoursesService();
  final _reviewService = CourseReviewService();
  final _profileService = UserProfileService();

  String _filter = 'all';

  // Per-course expansion state for the reviews section
  final Set<String> _expandedReviews = {};

  // Cache the current user's profile so we can attribute reviews
  UserProfile? _myProfile;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _myProfile = p;
      _profileLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppHeader(
        currentTab: 'dashboard',
        onTabSelected: (tab) => _navigate(context, tab),
      ),
      body: StreamBuilder<List<SavedCourse>>(
        stream: _savedService.watchSavedCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.ibmBlue),
            );
          }

          final saved = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(saved),
                      const SizedBox(height: 20),
                      if (saved.isNotEmpty) _buildProgressHero(saved),
                      if (saved.isNotEmpty) const SizedBox(height: 20),
                      _buildStatsGrid(saved, isMobile),
                      const SizedBox(height: 28),
                      if (saved.isEmpty)
                        _buildEmptyState(context)
                      else ...[
                        _buildFilterPills(saved),
                        const SizedBox(height: 16),
                        ..._getFilteredCourses(saved).map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCourseCard(entry.$1, entry.$2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- WELCOME HEADER ----------
  Widget _buildWelcomeHeader(List<SavedCourse> saved) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'there';
    final firstName = name.split(' ').first;

    final inProgress = saved
        .where((s) => s.progress == CourseProgress.inProgress)
        .length;
    final completed = saved
        .where((s) => s.progress == CourseProgress.completed)
        .length;

    String subtitle;
    if (saved.isEmpty) {
      subtitle = 'Start by saving courses from your recommendations';
    } else if (completed > 0) {
      subtitle =
          '$inProgress active • $completed completed • Keep up the momentum';
    } else {
      subtitle =
          '$inProgress active course${inProgress == 1 ? '' : 's'} • Time to start learning';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK, ${firstName.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.ibmGray,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your learning journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ibmBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.ibmGray),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.ibmBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.ibmBlue.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.ibmBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Live',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.ibmBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- GRADIENT HERO PROGRESS CARD ----------
  Widget _buildProgressHero(List<SavedCourse> saved) {
    final total = saved.length;
    final completed = saved
        .where((s) => s.progress == CourseProgress.completed)
        .length;
    final inProgress = saved
        .where((s) => s.progress == CourseProgress.inProgress)
        .length;

    double weightedProgress = 0;
    if (total > 0) {
      final weighted = (completed * 1.0) + (inProgress * 0.5);
      weightedProgress = (weighted / total) * 100;
    }
    final percent = weightedProgress.round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.ibmBlue, AppTheme.ibmDarkBlue],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ibmBlue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OVERALL PROGRESS',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completed of $total completed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: weightedProgress / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- STATS GRID ----------
  Widget _buildStatsGrid(List<SavedCourse> saved, bool isMobile) {
    final totalSaved = saved.length;
    final inProgress = saved
        .where((s) => s.progress == CourseProgress.inProgress)
        .length;
    final completed = saved
        .where((s) => s.progress == CourseProgress.completed)
        .length;

    int totalHours = 0;
    int badgesAvailable = 0;
    for (final s in saved) {
      final course = _getCourseById(s.courseId);
      if (course != null) {
        totalHours += course.durationHours;
        if (course.hasBadge) badgesAvailable++;
      }
    }

    final stats = [
      _StatData(
        label: 'SAVED',
        value: '$totalSaved',
        indicatorColor: AppTheme.ibmBlue,
        footer: totalSaved > 0 ? 'Courses in plan' : 'None yet',
        footerColor: AppTheme.ibmBlue,
      ),
      _StatData(
        label: 'ACTIVE',
        value: '$inProgress',
        indicatorColor: const Color(0xFFF1C21B),
        footer: inProgress > 0 ? 'In progress' : 'Ready to start',
        footerColor: AppTheme.ibmGray,
      ),
      _StatData(
        label: 'DONE',
        value: '$completed',
        indicatorColor: AppTheme.ibmGreen,
        footer: completed > 0 ? 'Great work!' : 'Not yet',
        footerColor: completed > 0 ? AppTheme.ibmGreen : AppTheme.ibmGray,
      ),
      _StatData(
        label: 'HOURS',
        value: '$totalHours',
        indicatorColor: AppTheme.ibmPurple,
        footer: 'Total planned',
        footerColor: AppTheme.ibmGray,
      ),
      _StatData(
        label: 'BADGES',
        value: '$badgesAvailable',
        indicatorColor: const Color(0xFF009D9A),
        footer: 'Available',
        footerColor: AppTheme.ibmGray,
      ),
    ];

    final crossAxisCount = isMobile ? 2 : 5;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isMobile ? 1.9 : 1.3,
      children: stats.map((s) => _buildStatCard(s)).toList(),
    );
  }

  Widget _buildStatCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: data.indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.ibmGray,
                ),
              ),
            ],
          ),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
              height: 1,
            ),
          ),
          Text(
            data.footer,
            style: TextStyle(
              fontSize: 10,
              color: data.footerColor,
              fontWeight: data.footerColor == AppTheme.ibmGray
                  ? FontWeight.normal
                  : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------- FILTER PILLS ----------
  Widget _buildFilterPills(List<SavedCourse> saved) {
    final counts = {
      'all': saved.length,
      'in_progress': saved
          .where((s) => s.progress == CourseProgress.inProgress)
          .length,
      'completed': saved
          .where((s) => s.progress == CourseProgress.completed)
          .length,
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Row(
        children: [
          _buildPillTab('All', 'all', counts['all']!),
          _buildPillTab('In Progress', 'in_progress', counts['in_progress']!),
          _buildPillTab('Completed', 'completed', counts['completed']!),
        ],
      ),
    );
  }

  Widget _buildPillTab(String label, String value, int count) {
    final isActive = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.ibmBlack : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.ibmWhite : AppTheme.ibmGray,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $count',
                style: TextStyle(
                  fontSize: 12,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.ibmGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<(SavedCourse, Course)> _getFilteredCourses(List<SavedCourse> saved) {
    final filtered = saved.where((s) {
      if (_filter == 'all') return true;
      if (_filter == 'in_progress') {
        return s.progress == CourseProgress.inProgress;
      }
      if (_filter == 'completed') {
        return s.progress == CourseProgress.completed;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int order(CourseProgress p) {
        switch (p) {
          case CourseProgress.inProgress:
            return 0;
          case CourseProgress.notStarted:
            return 1;
          case CourseProgress.completed:
            return 2;
        }
      }

      return order(a.progress).compareTo(order(b.progress));
    });

    final result = <(SavedCourse, Course)>[];
    for (final s in filtered) {
      final course = _getCourseById(s.courseId);
      if (course != null) result.add((s, course));
    }
    return result;
  }

  Course? _getCourseById(String id) {
    try {
      return CourseData.allCourses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------- COURSE CARD ----------
  Widget _buildCourseCard(SavedCourse saved, Course course) {
    final statusColor = _statusColor(saved.progress);
    final isExpanded = _expandedReviews.contains(course.id);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildProgressBadge(saved.progress),
                        if (saved.progress == CourseProgress.inProgress) ...[
                          const SizedBox(width: 10),
                          const Text(
                            '50% complete',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.ibmGray,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (course.hasBadge)
                          _buildMiniTag('BADGE', AppTheme.ibmPurple),
                        if (course.hasCertificate) ...[
                          const SizedBox(width: 6),
                          _buildMiniTag('CERT', AppTheme.ibmGreen),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ibmBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'IBM SkillsBuild',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.ibmBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _buildDotSeparator(),
                        Text(
                          course.durationLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.ibmGray,
                          ),
                        ),
                        _buildDotSeparator(),
                        Flexible(
                          child: Text(
                            'Saved ${_formatDate(saved.savedAt)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.ibmGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (saved.progress == CourseProgress.inProgress) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 4,
                          backgroundColor: AppTheme.ibmLightGray,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildActionButtons(saved, course),

                    // ---- Community Reviews section (NEW) ----
                    const SizedBox(height: 14),
                    _buildReviewsToggle(course.id, isExpanded),
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      _buildReviewsSection(course),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- REVIEWS TOGGLE BAR ----------
  Widget _buildReviewsToggle(String courseId, bool isExpanded) {
    return StreamBuilder<CourseReviewStats>(
      stream: _reviewService.watchStats(courseId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? CourseReviewStats.empty;

        return InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedReviews.remove(courseId);
              } else {
                _expandedReviews.add(courseId);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.ibmLightGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ibmDivider),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: 16,
                  color: AppTheme.ibmBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Community Reviews',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ibmBlack,
                  ),
                ),
                const SizedBox(width: 8),
                if (stats.reviewCount > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFF1C21B),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    stats.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ibmBlack,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${stats.reviewCount} review${stats.reviewCount == 1 ? '' : 's'})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.ibmGray,
                    ),
                  ),
                ] else
                  const Text(
                    'Be the first to review',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.ibmGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppTheme.ibmGray,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- REVIEWS EXPANDED PANEL ----------
  Widget _buildReviewsSection(Course course) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Submit-your-own form
          _MyReviewForm(
            course: course,
            myProfile: _myProfile,
            profileLoaded: _profileLoaded,
            reviewService: _reviewService,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.ibmDivider),
          const SizedBox(height: 14),
          const Text(
            'Reviews from other students',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.ibmBlack,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          // Reviews list
          StreamBuilder<List<CourseReview>>(
            stream: _reviewService.watchReviewsForCourse(course.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppTheme.ibmBlue,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];
              final myUid = FirebaseAuth.instance.currentUser?.uid;
              // Hide my own review from the public list (it shows in the form area instead)
              final othersReviews = reviews
                  .where((r) => r.userId != myUid)
                  .toList();

              if (othersReviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No reviews yet from other students. Be one of the first!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.ibmGray,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return Column(
                children: othersReviews
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildReviewCard(r),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(CourseReview review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: review.isAnonymous
                    ? AppTheme.ibmGray.withValues(alpha: 0.2)
                    : AppTheme.ibmBlue.withValues(alpha: 0.15),
                child: Icon(
                  review.isAnonymous ? Icons.person_outline : Icons.person,
                  size: 14,
                  color: review.isAnonymous
                      ? AppTheme.ibmGray
                      : AppTheme.ibmBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      review.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ibmBlack,
                      ),
                    ),
                    if (review.displayContext.isNotEmpty)
                      Text(
                        review.displayContext,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.ibmGray,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.starRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: i < review.starRating
                        ? const Color(0xFFF1C21B)
                        : AppTheme.ibmBorderGray,
                  );
                }),
              ),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.ibmBlack,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            _formatDate(review.submittedAt),
            style: const TextStyle(fontSize: 10, color: AppTheme.ibmGray),
          ),
        ],
      ),
    );
  }

  // ---------- PROGRESS BADGES, ACTIONS, TAGS ----------
  Widget _buildProgressBadge(CourseProgress progress) {
    Color color;
    IconData icon;
    String label;
    switch (progress) {
      case CourseProgress.notStarted:
        color = AppTheme.ibmBlue;
        icon = Icons.bookmark;
        label = 'SAVED';
        break;
      case CourseProgress.inProgress:
        color = const Color(0xFFF1C21B);
        icon = Icons.trending_up;
        label = 'IN PROGRESS';
        break;
      case CourseProgress.completed:
        color = AppTheme.ibmGreen;
        icon = Icons.check_circle;
        label = 'COMPLETED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDotSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: AppTheme.ibmBorderGray,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _statusColor(CourseProgress progress) {
    switch (progress) {
      case CourseProgress.notStarted:
        return AppTheme.ibmBlue;
      case CourseProgress.inProgress:
        return const Color(0xFFF1C21B);
      case CourseProgress.completed:
        return AppTheme.ibmGreen;
    }
  }

  Widget _buildActionButtons(SavedCourse saved, Course course) {
    return Row(
      children: [
        if (saved.progress == CourseProgress.notStarted)
          _primaryButton(
            label: 'Start Course',
            icon: Icons.play_arrow,
            color: AppTheme.ibmBlue,
            onTap: () async {
              await UrlLauncherService.openCourseUrl(context, course.courseUrl);
              await _updateProgress(course.id, CourseProgress.inProgress);
            },
          )
        else if (saved.progress == CourseProgress.inProgress)
          _primaryButton(
            label: 'Mark Complete',
            icon: Icons.check,
            color: AppTheme.ibmGreen,
            onTap: () => _updateProgress(course.id, CourseProgress.completed),
          )
        else
          _primaryButton(
            label: 'Retake',
            icon: Icons.refresh,
            color: AppTheme.ibmBlue,
            onTap: () async {
              await UrlLauncherService.openCourseUrl(context, course.courseUrl);
              await _updateProgress(course.id, CourseProgress.inProgress);
            },
          ),
        const SizedBox(width: 8),
        _secondaryButton(
          label: 'Open on SkillsBuild',
          icon: Icons.open_in_new,
          onTap: () {
            UrlLauncherService.openCourseUrl(context, course.courseUrl);
          },
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Remove',
          onPressed: () => _confirmRemove(course),
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppTheme.ibmBorderGray,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.ibmDivider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.ibmGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.ibmGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProgress(String courseId, CourseProgress p) async {
    await _savedService.updateProgress(courseId, p);
    if (mounted) {
      String msg;
      switch (p) {
        case CourseProgress.inProgress:
          msg = 'Course started. Good luck!';
          break;
        case CourseProgress.completed:
          msg = '🎉 Great job! Course marked complete.';
          break;
        case CourseProgress.notStarted:
          msg = 'Progress reset.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.ibmGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmRemove(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove course?'),
        content: Text('Remove "${course.title}" from your saved courses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _savedService.removeSavedCourse(course.id);
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.ibmBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_outline,
              size: 42,
              color: AppTheme.ibmBlue,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No saved courses yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Browse your recommendations and save courses\nto build your personalized learning pathway.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.ibmGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecommendationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Go to Recommendations'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _navigate(BuildContext context, String tab) {
    if (tab == 'dashboard') return;
    Widget screen;
    switch (tab) {
      case 'profile':
        screen = const ProfileInputScreen();
        break;
      case 'recommendations':
        screen = const RecommendationsScreen();
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

class _StatData {
  final String label;
  final String value;
  final Color indicatorColor;
  final String footer;
  final Color footerColor;

  _StatData({
    required this.label,
    required this.value,
    required this.indicatorColor,
    required this.footer,
    required this.footerColor,
  });
}

// ===================================================================
// MY REVIEW FORM (separate StatefulWidget so each course's form
// has its own private input state)
// ===================================================================
class _MyReviewForm extends StatefulWidget {
  final Course course;
  final UserProfile? myProfile;
  final bool profileLoaded;
  final CourseReviewService reviewService;

  const _MyReviewForm({
    required this.course,
    required this.myProfile,
    required this.profileLoaded,
    required this.reviewService,
  });

  @override
  State<_MyReviewForm> createState() => _MyReviewFormState();
}

class _MyReviewFormState extends State<_MyReviewForm> {
  final _textController = TextEditingController();
  int _rating = 0;
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  CourseReview? _existingReview;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final r = await widget.reviewService.getMyReview(widget.course.id);
    if (!mounted) return;
    setState(() {
      _existingReview = r;
      _loadedExisting = true;
      if (r != null) {
        _rating = r.starRating;
        _textController.text = r.reviewText;
        _isAnonymous = r.isAnonymous;
      }
    });
  }

  String _buildContext() {
    final p = widget.myProfile;
    if (p == null) return '';
    final parts = <String>[];
    if (p.yearOfStudy != null && p.yearOfStudy!.isNotEmpty) {
      parts.add(p.yearOfStudy!);
    }
    if (p.degreeProgram != null && p.degreeProgram!.isNotEmpty) {
      parts.add(p.degreeProgram!);
    }
    return parts.join(' · ');
  }

  String _buildName() {
    final user = FirebaseAuth.instance.currentUser;
    final raw = user?.displayName ?? user?.email?.split('@').first ?? 'Student';
    return raw.split(' ').first;
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.reviewService.submitReview(
        courseId: widget.course.id,
        starRating: _rating,
        reviewText: _textController.text,
        isAnonymous: _isAnonymous,
        userName: _buildName(),
        userContext: _buildContext(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingReview != null
                ? 'Review updated. Thanks!'
                : '🙏 Thanks for your review!',
          ),
          backgroundColor: AppTheme.ibmGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      // Refresh existing-state so the form switches to "Edit" mode
      await _loadExisting();
      setState(() => _isSubmitting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your review?'),
        content: const Text(
          'Other students will no longer see your review for this course.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    await widget.reviewService.deleteMyReview(widget.course.id);
    if (!mounted) return;
    setState(() {
      _existingReview = null;
      _rating = 0;
      _textController.clear();
      _isAnonymous = false;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Profile gate — disable submission if user has no profile
    if (widget.profileLoaded && widget.myProfile == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF1C21B)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A6D00)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Complete your profile (year + programme) to leave a review.',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A6D00)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileInputScreen()),
                );
              },
              child: const Text('Update', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (!_loadedExisting) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: AppTheme.ibmBlue,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final isEditing = _existingReview != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Your review' : 'Leave a review',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.ibmBlack,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),

        // Star rating
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;
            final filled = star <= _rating;
            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: InkWell(
                onTap: () => setState(() => _rating = star),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 26,
                    color: filled
                        ? const Color(0xFFF1C21B)
                        : AppTheme.ibmBorderGray,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),

        // Review text
        TextField(
          controller: _textController,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Share your experience with this course (optional)…',
            hintStyle: const TextStyle(fontSize: 12, color: AppTheme.ibmGray),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.ibmDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.ibmDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.ibmBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Anonymous toggle
        Row(
          children: [
            Transform.scale(
              scale: 0.85,
              child: Checkbox(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                activeColor: AppTheme.ibmBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Text(
              'Post as Bristol student (hide my name & programme)',
              style: TextStyle(fontSize: 11, color: AppTheme.ibmGray),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Live preview of how your review will appear
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.ibmLightGray,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                size: 12,
                color: AppTheme.ibmGray,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isAnonymous
                      ? 'Will appear as: Bristol student'
                      : 'Will appear as: ${_buildName()} · ${_buildContext().isEmpty ? "(complete profile)" : _buildContext()}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.ibmGray),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Action row
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isEditing ? Icons.edit : Icons.send_outlined,
                      size: 14,
                    ),
              label: Text(
                isEditing
                    ? (_isSubmitting ? 'Updating...' : 'Update review')
                    : (_isSubmitting ? 'Submitting...' : 'Submit review'),
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _delete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
