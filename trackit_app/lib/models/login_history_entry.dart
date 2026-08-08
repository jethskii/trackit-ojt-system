class LoginHistoryEntry {
  final int id;
  final DateTime loginAt;
  final DateTime? logoutAt;
  final String? userAgent;

  const LoginHistoryEntry({
    required this.id,
    required this.loginAt,
    this.logoutAt,
    this.userAgent,
  });

  bool get isActive => logoutAt == null;

  Duration get sessionDuration => (logoutAt ?? DateTime.now()).difference(loginAt);

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LoginHistoryEntry(
      id: json['id'] as int,
      loginAt: DateTime.parse(json['loginAt'] as String),
      logoutAt: json['logoutAt'] != null ? DateTime.parse(json['logoutAt'] as String) : null,
      userAgent: json['userAgent'] as String?,
    );
  }
}
