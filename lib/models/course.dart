// Course difficulty levels
enum CourseLevel { beginner, intermediate, advanced }

// Course categories for organization
enum CourseCategory {
  ai, // Artificial Intelligence
  dataScience, // Data Science & Analytics
  cybersecurity, // Cybersecurity
  cloud, // Cloud Computing
  softwareDev, // Software Development
  businessSkills, // Business & Soft Skills
  sustainability, // Sustainability
  design, // Design & UX
}

class Course {
  final String id;
  final String title;
  final String provider; // e.g., "IBM SkillsBuild"
  final String description;
  final CourseCategory category;
  final CourseLevel level;
  final int durationHours; // total course duration in hours
  final List<String> skillsTaught; // skills the user will gain
  final List<String> relatedInterests; // matches user's academic interests
  final List<String> relatedIndustries; // matches user's preferred industries
  final List<String> relatedJobRoles; // matches user's target job roles
  final bool hasBadge; // offers IBM digital badge?
  final bool hasCertificate; // offers certificate?
  final String imageUrl; // thumbnail (we'll use placeholders for now)
  final String courseUrl; // link to actual IBM SkillsBuild course

  const Course({
    required this.id,
    required this.title,
    required this.provider,
    required this.description,
    required this.category,
    required this.level,
    required this.durationHours,
    required this.skillsTaught,
    required this.relatedInterests,
    required this.relatedIndustries,
    required this.relatedJobRoles,
    this.hasBadge = false,
    this.hasCertificate = false,
    this.imageUrl = '',
    this.courseUrl = 'https://skillsbuild.org',
  });

  // Helper to display level as a user-friendly string
  String get levelLabel {
    switch (level) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
    }
  }

  // Helper to display category as a user-friendly string
  String get categoryLabel {
    switch (category) {
      case CourseCategory.ai:
        return 'Artificial Intelligence';
      case CourseCategory.dataScience:
        return 'Data Science';
      case CourseCategory.cybersecurity:
        return 'Cybersecurity';
      case CourseCategory.cloud:
        return 'Cloud Computing';
      case CourseCategory.softwareDev:
        return 'Software Development';
      case CourseCategory.businessSkills:
        return 'Business Skills';
      case CourseCategory.sustainability:
        return 'Sustainability';
      case CourseCategory.design:
        return 'Design & UX';
    }
  }

  // Format duration nicely
  String get durationLabel {
    if (durationHours < 1) {
      return '< 1 hour';
    } else if (durationHours == 1) {
      return '1 hour';
    } else {
      return '$durationHours hours';
    }
  }
}
