import 'user_role.dart';

/// Активная сессия после входа.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.login,
    required this.role,
    required this.displayName,
  });

  final String userId;
  final String login;
  final UserRole role;
  final String displayName;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'login': login,
        'role': role.id,
        'displayName': displayName,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      login: json['login'] as String,
      role: UserRole.fromId(json['role'] as String?) ?? UserRole.worker,
      displayName: json['displayName'] as String? ?? json['login'] as String,
    );
  }
}
