class TestingModel {
  TestingModel({
    required this.appId,
    required this.name,
    required this.playUrl,
    required this.packageName,
    required this.lastOpenedAt,
    required this.openCountByMe,
    required this.isEndedByDeveloper,
  });

  final String appId;
  final String name;
  final String playUrl;
  final String packageName;
  final DateTime? lastOpenedAt;
  final int openCountByMe;
  final bool isEndedByDeveloper;

  factory TestingModel.fromMap(Map<String, dynamic> data) {
    return TestingModel(
      appId: (data['appId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      playUrl: (data['playUrl'] ?? '') as String,
      packageName: (data['packageName'] ?? '') as String,
      lastOpenedAt: (data['lastOpenedAt'] as dynamic)?.toDate(),
      openCountByMe: (data['openCountByMe'] ?? 0) as int,
      isEndedByDeveloper: (data['isEndedByDeveloper'] ?? false) as bool,
    );
  }
}
