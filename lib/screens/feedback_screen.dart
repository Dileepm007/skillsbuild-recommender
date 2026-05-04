import 'package:flutter/material.dart';
import '../models/feedback_models.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'profile_input_screen.dart';
import 'recommendations_screen.dart';
import 'dashboard_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackService = FeedbackService();
  final _formKey = GlobalKey<FormState>();
  final _likedController = TextEditingController();
  final _improvementsController = TextEditingController();

  int _starRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _likedController.dispose();
    _improvementsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_starRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _feedbackService.submitGeneralFeedback(
        starRating: _starRating,
        liked: _likedController.text,
        improvements: _improvementsController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🙏 Thanks for your feedback!'),
          backgroundColor: AppTheme.ibmGreen,
          duration: Duration(seconds: 3),
        ),
      );

      setState(() {
        _starRating = 0;
        _likedController.clear();
        _improvementsController.clear();
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppHeader(
        currentTab: 'feedback',
        onTabSelected: (tab) => _navigate(context, tab),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share Your Feedback',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ibmBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your input helps us improve the recommendations for everyone.',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: AppTheme.ibmGray,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 32),

                  // Stack on mobile, side-by-side on desktop
                  if (isMobile) ...[
                    _buildFeedbackForm(isMobile),
                    const SizedBox(height: 16),
                    _buildFeedbackHistory(isMobile),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildFeedbackForm(isMobile)),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 2,
                          child: _buildFeedbackHistory(isMobile),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackForm(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submit new feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.ibmBlack,
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('How relevant were your recommendations?'),
            const SizedBox(height: 12),
            _buildStarRating(),
            const SizedBox(height: 8),
            if (_starRating > 0)
              Text(
                _getStarLabel(_starRating),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.ibmBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 28),

            _sectionLabel('What did you like?'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _likedController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. the match reasons were helpful, found courses I didn\'t know about...',
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('What could be improved?'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _improvementsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'e.g. more courses in specific areas, better filtering...',
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: AppTheme.ibmWhite,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _starRating;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => setState(() => _starRating = starIndex),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 34,
                color: isFilled
                    ? const Color(0xFFF1C21B)
                    : AppTheme.ibmBorderGray,
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getStarLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor — not relevant at all';
      case 2:
        return 'Below average — needs work';
      case 3:
        return 'Okay — some were relevant';
      case 4:
        return 'Good — mostly relevant';
      case 5:
        return 'Excellent — very relevant';
      default:
        return '';
    }
  }

  Widget _buildFeedbackHistory(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ibmWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmDivider),
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your past feedback',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ibmBlack,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<GeneralFeedback>>(
            stream: _feedbackService.watchGeneralFeedback(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.ibmBlue,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.ibmLightGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 40,
                        color: AppTheme.ibmLightBlue,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No feedback yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ibmBlack,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your submissions will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.ibmGray),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: history
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryCard(f),
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

  Widget _buildHistoryCard(GeneralFeedback feedback) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ibmLightGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < feedback.starRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < feedback.starRating
                        ? const Color(0xFFF1C21B)
                        : AppTheme.ibmBorderGray,
                  );
                }),
              ),
              const Spacer(),
              Text(
                _formatDate(feedback.submittedAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.ibmGray),
              ),
            ],
          ),
          if (feedback.liked.isNotEmpty) ...[
            const SizedBox(height: 10),
            _historyRow('Liked', feedback.liked, AppTheme.ibmGreen),
          ],
          if (feedback.improvements.isNotEmpty) ...[
            const SizedBox(height: 8),
            _historyRow(
              'Improvements',
              feedback.improvements,
              const Color(0xFFF1C21B),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyRow(String label, String content, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          content,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.ibmBlack,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.ibmBlack,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  void _navigate(BuildContext context, String tab) {
    if (tab == 'feedback') return;
    Widget screen;
    switch (tab) {
      case 'profile':
        screen = const ProfileInputScreen();
        break;
      case 'recommendations':
        screen = const RecommendationsScreen();
        break;
      case 'dashboard':
        screen = const DashboardScreen();
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
