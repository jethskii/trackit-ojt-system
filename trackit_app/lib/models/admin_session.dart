class AdminSession {
  final int id;
  final String device;
  final String? ipAddress;
  final DateTime loginAt;
  final DateTime? logoutAt;
  final DateTime? revokedAt;
  final bool active;

  /// The session this app instance is currently authenticated with --
  /// used to disable the "Terminate" action on your own live session
  /// (that's what Log Out is for) rather than letting you lock yourself
  /// out from inside the list.
  final bool current;

  const AdminSession({
    required this.id,
    required this.device,
    this.ipAddress,
    required this.loginAt,
    this.logoutAt,
    this.revokedAt,
    required this.active,
    required this.current,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] as int,
      device: json['device'] as String,
      ipAddress: json['ipAddress'] as String?,
      loginAt: DateTime.parse(json['loginAt'] as String),
      logoutAt: json['logoutAt'] != null ? DateTime.parse(json['logoutAt'] as String) : null,
      revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
      active: json['active'] as bool? ?? false,
      current: json['current'] as bool? ?? false,
    );
  }
}
