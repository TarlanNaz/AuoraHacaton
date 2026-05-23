import 'user_role.dart';

/// Локальная учётная запись (заглушка без реального бэкенда).
class StoredUser {
  const StoredUser({
    required this.id,
    required this.login,
    required this.password,
    required this.role,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String login;
  /// В заглушке хранится как есть; в проде — только хэш.
  final String password;
  final UserRole role;
  final String displayName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'login': login,
        'password': password,
        'role': role.id,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory StoredUser.fromJson(Map<String, dynamic> json) {
    return StoredUser(
      id: json['id'] as String,
      login: json['login'] as String,
      password: json['password'] as String,
      role: UserRole.fromId(json['role'] as String?) ?? UserRole.worker,
      displayName: json['displayName'] as String? ?? json['login'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
