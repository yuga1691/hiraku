class TestingModel {
  TestingModel({
    required this.appId,
    required this.name,
    required this.lastOpenedAt,
    required this.openCountByMe,
  });

  final String appId;
  final String name;
  final DateTime? lastOpenedAt;
  final int openCountByMe;

  factory TestingModel.fromMap(Map<String, dynamic> data) {
    return TestingModel(
      appId: (data['appId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      lastOpenedAt: (data['lastOpenedAt'] as dynamic)?.toDate(),
      openCountByMe: (data['openCountByMe'] ?? 0) as int,
    );
  }
}
