/// Профиль полевого сотрудника (локально, без бэкенда).
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    this.employerName,
    this.photoPath,
  });

  static const defaultName = 'Полевой сотрудник';
  static const defaultEmployer = 'не указано';

  final String id;
  final String fullName;
  /// Организация / подразделение, в котором работает сотрудник.
  final String? employerName;
  /// Имя файла в [ImageStorageService] (подкаталог report_images).
  final String? photoPath;

  String get displayEmployer =>
      (employerName ?? '').trim().isEmpty ? defaultEmployer : employerName!.trim();

  WorkerProfile copyWith({
    String? id,
    String? fullName,
    String? employerName,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      employerName: employerName ?? this.employerName,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        if (employerName != null) 'employerName': employerName,
        'photoPath': photoPath,
      };

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? defaultName,
      employerName: json['employerName'] as String?,
      photoPath: json['photoPath'] as String?,
    );
  }

  factory WorkerProfile.initial({required String id}) {
    return WorkerProfile(id: id, fullName: defaultName);
  }
}
