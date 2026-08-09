class AdminProfile {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;

  /// Null if the password has never been changed since the account was
  /// seeded -- shown as "Never changed" rather than a fake date.
  final DateTime? lastPasswordChange;
  final String status;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.lastPasswordChange,
    required this.status,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) {
    return AdminProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastPasswordChange: json['lastPasswordChange'] != null
          ? DateTime.parse(json['lastPasswordChange'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
    );
  }

  AdminProfile copyWith({String? name, String? email, String? avatarUrl}) {
    return AdminProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastPasswordChange: lastPasswordChange,
      status: status,
    );
  }
}
