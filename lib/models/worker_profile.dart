/// Профиль полевого сотрудника (локально, без бэкенда).
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    this.photoPath,
  });

  static const defaultName = 'Полевой сотрудник';

  final String id;
  final String fullName;
  /// Имя файла в [ImageStorageService] (подкаталог report_images).
  final String? photoPath;

  WorkerProfile copyWith({
    String? id,
    String? fullName,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return WorkerProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'photoPath': photoPath,
      };

  factory WorkerProfile.fromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? defaultName,
      photoPath: json['photoPath'] as String?,
    );
  }

  factory WorkerProfile.initial({required String id}) {
    return WorkerProfile(id: id, fullName: defaultName);
  }
}
