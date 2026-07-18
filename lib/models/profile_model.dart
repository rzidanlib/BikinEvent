class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String statusType;
  final String? educationLevel; // baru
  final String? institutionId; // baru
  final String? institutionName; // baru, hasil join
  final String? studentNumber; // baru

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.statusType = 'umum',
    this.educationLevel,
    this.institutionId,
    this.institutionName,
    this.studentNumber,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      statusType: json['status_type'] as String? ?? 'umum',
      educationLevel: json['education_level'],
      institutionId: json['institution_id'],
      institutionName: json['institutions'] != null
          ? json['institutions']['name']
          : null,
      studentNumber: json['student_number'],
    );
  }

  bool get isOrganizer => role == 'organizer';
}
