enum UserRole {
  worker('worker', 'Рабочий'),
  manager('manager', 'Руководитель');

  const UserRole(this.id, this.label);
  final String id;
  final String label;

  static UserRole? fromId(String? id) {
    if (id == null) return null;
    for (final r in UserRole.values) {
      if (r.id == id) return r;
    }
    return null;
  }
}
