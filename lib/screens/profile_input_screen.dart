import 'package:flutter/material.dart';
import '../data/bristol_programmes.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'recommendations_screen.dart';
import 'dashboard_screen.dart';
import 'feedback_screen.dart';

class ProfileInputScreen extends StatefulWidget {
  const ProfileInputScreen({super.key});

  @override
  State<ProfileInputScreen> createState() => _ProfileInputScreenState();
}

class _ProfileInputScreenState extends State<ProfileInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _interestTextController = TextEditingController();
  final _profileService = UserProfileService();

  bool _isUndergraduate = true;
  String? _selectedProgramme;
  String? _selectedYear;
  String? _selectedIndustry;
  String? _selectedJobRole;
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedSkills = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  final List<String> _interestOptions = [
    'Machine Learning',
    'Distributed Systems',
    'Data Visualization',
    'Cybersecurity',
    'Cloud Computing',
    'Blockchain',
    'IoT',
    'AI Ethics',
  ];

  final List<String> _industryOptions = [
    'Information Technology',
    'Finance & Banking',
    'Healthcare',
    'E-commerce',
    'Education',
    'Manufacturing',
    'Consulting',
    'Government',
  ];

  final List<String> _jobRoleOptions = [
    'Software Engineer',
    'Data Scientist',
    'Data Analyst',
    'Cybersecurity Analyst',
    'Cloud Engineer',
    'AI/ML Engineer',
    'Product Manager',
    'DevOps Engineer',
    'UI/UX Designer',
  ];

  final List<String> _skillOptions = [
    'Python',
    'JavaScript',
    'Java',
    'SQL',
    'Machine Learning',
    'Cloud (AWS/GCP/Azure)',
    'Linux',
    'Data Analysis',
    'Statistics',
    'Communication',
    'Project Management',
    'Problem Solving',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final existing = await _profileService.getProfile();
    if (!mounted) return;
    if (existing != null) {
      setState(() {
        _isUndergraduate = existing.isUndergraduate;
        _selectedProgramme = existing.degreeProgram;
        _selectedYear = existing.yearOfStudy;
        _selectedIndustry = existing.preferredIndustry;
        _selectedJobRole = existing.targetJobRole;
        _selectedInterests.addAll(existing.selectedInterests);
        _selectedSkills.addAll(existing.existingSkills);
        _interestTextController.text = existing.customInterests;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _interestTextController.dispose();
    super.dispose();
  }

  List<String> get _currentProgrammes => _isUndergraduate
      ? BristolProgrammes.undergraduate
      : BristolProgrammes.postgraduate;

  List<String> get _currentYearOptions =>
      BristolProgrammes.yearOptionsFor(_isUndergraduate);

  void _onLevelToggle(bool isUndergraduate) {
    if (isUndergraduate == _isUndergraduate) return;
    setState(() {
      _isUndergraduate = isUndergraduate;
      _selectedProgramme = null;
      _selectedYear = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProgramme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your programme'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final profile = UserProfile(
      degreeProgram: _selectedProgramme,
      yearOfStudy: _selectedYear,
      customInterests: _interestTextController.text,
      selectedInterests: _selectedInterests,
      preferredIndustry: _selectedIndustry,
      targetJobRole: _selectedJobRole,
      existingSkills: _selectedSkills,
      isUndergraduate: _isUndergraduate,
    );

    try {
      await _profileService.saveProfile(profile);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationsScreen(profile: profile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigate(String tab) {
    if (tab == 'profile') return;
    Widget screen;
    switch (tab) {
      case 'recommendations':
        screen = const RecommendationsScreen();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppHeader(currentTab: 'profile', onTabSelected: _navigate),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.ibmBlue),
        ),
      );
    }

    final hasExistingProfile = _selectedProgramme != null;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppHeader(currentTab: 'profile', onTabSelected: _navigate),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasExistingProfile) _buildEditNotice(),
                    _sectionLabel('ACADEMIC BACKGROUND'),
                    const SizedBox(height: 16),
                    _labeledField('Level of Study', _buildLevelToggle()),
                    const SizedBox(height: 20),
                    _buildResponsiveRow(
                      context,
                      leftChild: _labeledField(
                        'Programme / Course',
                        _buildSearchableProgramme(),
                      ),
                      rightChild: _labeledField(
                        'Year of Study',
                        _buildDropdown(
                          value: _selectedYear,
                          hint: 'Select year',
                          items: _currentYearOptions,
                          onChanged: (v) => setState(() => _selectedYear = v),
                        ),
                      ),
                      leftFlex: 2,
                    ),
                    const SizedBox(height: 20),
                    _labeledField(
                      'Areas of Academic Interest',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _interestTextController,
                            decoration: const InputDecoration(
                              hintText:
                                  'e.g. machine learning, distributed systems, data visualisation...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Or pick from suggestions:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.ibmGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildChipGroup(_interestOptions, _selectedInterests),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: AppTheme.ibmDivider, height: 1),
                    const SizedBox(height: 28),
                    _sectionLabel('CAREER ASPIRATIONS'),
                    const SizedBox(height: 16),
                    _buildResponsiveRow(
                      context,
                      leftChild: _labeledField(
                        'Preferred Industry',
                        _buildDropdown(
                          value: _selectedIndustry,
                          hint: 'Select industry',
                          items: _industryOptions,
                          onChanged: (v) =>
                              setState(() => _selectedIndustry = v),
                        ),
                      ),
                      rightChild: _labeledField(
                        'Target Job Role',
                        _buildDropdown(
                          value: _selectedJobRole,
                          hint: 'Select role',
                          items: _jobRoleOptions,
                          onChanged: (v) =>
                              setState(() => _selectedJobRole = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: AppTheme.ibmDivider, height: 1),
                    const SizedBox(height: 28),
                    _sectionLabel('EXISTING SKILLS — SELECT ALL THAT APPLY'),
                    const SizedBox(height: 16),
                    _buildChipGroup(_skillOptions, _selectedSkills),
                    const SizedBox(height: 32),
                    const Divider(color: AppTheme.ibmDivider, height: 1),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppTheme.ibmWhite,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 16),
                        label: Text(
                          _isSubmitting
                              ? 'Saving...'
                              : hasExistingProfile
                              ? 'Update & Refresh Recommendations'
                              : 'Get My Learning Pathways',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveRow(
    BuildContext context, {
    required Widget leftChild,
    required Widget rightChild,
    int leftFlex = 1,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [leftChild, const SizedBox(height: 16), rightChild],
      );
    }
    return Row(
      children: [
        Expanded(flex: leftFlex, child: leftChild),
        const SizedBox(width: 24),
        Expanded(child: rightChild),
      ],
    );
  }

  Widget _buildEditNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.ibmBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.ibmBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppTheme.ibmBlue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your profile is saved. Update any fields below and click submit to refresh recommendations.',
              style: TextStyle(fontSize: 13, color: AppTheme.ibmBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ibmLightGray,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _toggleOption('Undergraduate', true)),
          Expanded(child: _toggleOption('Postgraduate', false)),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool isUndergraduate) {
    final isActive = _isUndergraduate == isUndergraduate;
    return InkWell(
      onTap: () => _onLevelToggle(isUndergraduate),
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.ibmWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? AppTheme.ibmBorderGray : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? AppTheme.ibmBlue : AppTheme.ibmGray,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableProgramme() {
    return Autocomplete<String>(
      initialValue: _selectedProgramme != null
          ? TextEditingValue(text: _selectedProgramme!)
          : const TextEditingValue(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _currentProgrammes.take(30);
        }
        final query = textEditingValue.text.toLowerCase();
        return _currentProgrammes
            .where((p) => p.toLowerCase().contains(query))
            .take(30);
      },
      onSelected: (String selection) {
        setState(() {
          _selectedProgramme = selection;
        });
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: _isUndergraduate
                ? 'Search UG programmes (e.g. Computer Science)'
                : 'Search PG programmes (e.g. MSc Artificial Intelligence)',
            prefixIcon: const Icon(Icons.school_outlined, size: 18),
            suffixIcon: _selectedProgramme != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      textController.clear();
                      setState(() => _selectedProgramme = null);
                    },
                  )
                : null,
          ),
          validator: (_) {
            if (_selectedProgramme == null) return 'Required';
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 620),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.ibmDivider,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.ibmBlack,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppTheme.ibmGray,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.ibmBlack,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(hintText: hint),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildChipGroup(List<String> options, Set<String> selectedSet) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedSet.contains(option);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSet.remove(option);
              } else {
                selectedSet.add(option);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.ibmBlue.withValues(alpha: 0.1)
                  : AppTheme.ibmWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.ibmBlue : AppTheme.ibmBorderGray,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppTheme.ibmBlue : AppTheme.ibmBlack,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
