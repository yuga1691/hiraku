class AppModel {
  AppModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.playUrl,
    required this.packageName,
    required this.message,
    required this.iconBase64,
    required this.isActive,
    required this.remainingExposure,
    required this.openedCount,
    required this.createdAt,
    required this.endedAt,
  });

  final String id;
  final String ownerUserId;
  final String name;
  final String playUrl;
  final String packageName;
  final String message;
  final String? iconBase64;
  final bool isActive;
  final int remainingExposure;
  final int openedCount;
  final DateTime? createdAt;
  final DateTime? endedAt;

  factory AppModel.fromMap(String id, Map<String, dynamic> data) {
    return AppModel(
      id: id,
      ownerUserId: (data['ownerUserId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      playUrl: (data['playUrl'] ?? '') as String,
      packageName: (data['packageName'] ?? '') as String,
      message: (data['message'] ?? '') as String,
      iconBase64: data['iconBase64'] as String?,
      isActive: (data['isActive'] ?? false) as bool,
      remainingExposure: (data['remainingExposure'] ?? 0) as int,
      openedCount: (data['openedCount'] ?? 0) as int,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      endedAt: (data['endedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUserId': ownerUserId,
      'name': name,
      'playUrl': playUrl,
      'packageName': packageName,
      'message': message,
      'iconBase64': iconBase64,
      'isActive': isActive,
      'remainingExposure': remainingExposure,
      'openedCount': openedCount,
      'createdAt': createdAt,
      'endedAt': endedAt,
    };
  }
}
