class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String role;
  final String? avatarUrl; // baru

  Profile({
    required this.id,
    required this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
    );
  }

  bool get isOrganizer => role == 'organizer';
}
