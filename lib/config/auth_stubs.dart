import '../models/user_role.dart';

/// Демо-учётки для заглушки авторизации (локально, без сервера).
class AuthStubs {
  AuthStubs._();

  static const workerLogin = 'worker';
  static const workerPassword = 'worker123';
  static const managerLogin = 'manager';
  static const managerPassword = 'manager123';

  static const workerDisplayName = 'Иванов Алексей Петрович';
  static const managerDisplayName = 'Руководитель (демо)';

  static List<({String login, String password, UserRole role, String name})>
      get seedAccounts => [
            (
              login: workerLogin,
              password: workerPassword,
              role: UserRole.worker,
              name: workerDisplayName,
            ),
            (
              login: managerLogin,
              password: managerPassword,
              role: UserRole.manager,
              name: managerDisplayName,
            ),
          ];

  static String hintText() =>
      'Демо: $workerLogin / $workerPassword или $managerLogin / $managerPassword';
}
