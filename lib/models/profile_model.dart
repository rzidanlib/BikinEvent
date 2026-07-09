class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
    );
  }

  bool get isOrganizer => role == 'organizer';
}
