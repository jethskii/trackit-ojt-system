class TeacherProfile {
  final String name;
  final String email;
  final String position;
  final String? photoUrl;
  final List<String> programs;
  final List<String> sections;

  const TeacherProfile({
    required this.name,
    required this.email,
    required this.position,
    this.photoUrl,
    required this.programs,
    required this.sections,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      position: json['position'] as String,
      photoUrl: json['photoUrl'] as String?,
      programs: (json['programs'] as List<dynamic>).cast<String>(),
      sections: (json['sections'] as List<dynamic>).cast<String>(),
    );
  }

  TeacherProfile copyWith({String? photoUrl, String? email}) {
    return TeacherProfile(
      name: name,
      email: email ?? this.email,
      position: position,
      photoUrl: photoUrl ?? this.photoUrl,
      programs: programs,
      sections: sections,
    );
  }
}
