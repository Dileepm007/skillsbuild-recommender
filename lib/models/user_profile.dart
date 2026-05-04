class UserProfile {
  final String? degreeProgram;
  final String? yearOfStudy;
  final String customInterests;
  final Set<String> selectedInterests;
  final String? preferredIndustry;
  final String? targetJobRole;
  final Set<String> existingSkills;
  final bool isUndergraduate;
  final DateTime? updatedAt;

  const UserProfile({
    this.degreeProgram,
    this.yearOfStudy,
    this.customInterests = '',
    this.selectedInterests = const {},
    this.preferredIndustry,
    this.targetJobRole,
    this.existingSkills = const {},
    this.isUndergraduate = true,
    this.updatedAt,
  });

  bool get isEarlyYear {
    return yearOfStudy == '1st Year' || yearOfStudy == '2nd Year';
  }

  List<String> get allInterests {
    final custom = customInterests
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return [...selectedInterests, ...custom];
  }

  // Quick check if the user has filled out enough to get recommendations
  bool get isComplete {
    return degreeProgram != null &&
        yearOfStudy != null &&
        existingSkills.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'degreeProgram': degreeProgram,
      'yearOfStudy': yearOfStudy,
      'customInterests': customInterests,
      'selectedInterests': selectedInterests.toList(),
      'preferredIndustry': preferredIndustry,
      'targetJobRole': targetJobRole,
      'existingSkills': existingSkills.toList(),
      'isUndergraduate': isUndergraduate,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      degreeProgram: map['degreeProgram'] as String?,
      yearOfStudy: map['yearOfStudy'] as String?,
      customInterests: (map['customInterests'] as String?) ?? '',
      selectedInterests: ((map['selectedInterests'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet(),
      preferredIndustry: map['preferredIndustry'] as String?,
      targetJobRole: map['targetJobRole'] as String?,
      existingSkills: ((map['existingSkills'] as List?) ?? [])
          .map((e) => e.toString())
          .toSet(),
      isUndergraduate: (map['isUndergraduate'] as bool?) ?? true,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
