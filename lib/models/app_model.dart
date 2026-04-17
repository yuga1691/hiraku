class AppOpenLogEntry {
  AppOpenLogEntry({
    required this.dateKey,
    required this.testerAppName,
  });

  final String dateKey;
  final String testerAppName;

  factory AppOpenLogEntry.fromMap(Map<String, dynamic> data) {
    return AppOpenLogEntry(
      dateKey: (data['dateKey'] ?? '') as String,
      testerAppName: (data['testerAppName'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'testerAppName': testerAppName,
    };
  }
}

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
    required this.openCountByDate,
    required this.openCountByTesterAppName,
    required this.recentOpenLogs,
    required this.boostUntil,
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
  final Map<String, int> openCountByDate;
  final Map<String, int> openCountByTesterAppName;
  final List<AppOpenLogEntry> recentOpenLogs;
  final DateTime? boostUntil;
  final DateTime? createdAt;
  final DateTime? endedAt;

  bool get isBoostActive {
    final until = boostUntil;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

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
      openCountByDate: _parseCountByDate(data['openCountByDate']),
      openCountByTesterAppName: _parseCountByDate(
        data['openCountByTesterAppName'],
      ),
      recentOpenLogs: _parseRecentOpenLogs(data['recentOpenLogs']),
      boostUntil: (data['boostUntil'] as dynamic)?.toDate(),
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      endedAt: (data['endedAt'] as dynamic)?.toDate(),
    );
  }

  static Map<String, int> _parseCountByDate(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((key, value) {
      final count = (value ?? 0) as int;
      return MapEntry(key.toString(), count);
    });
  }

  static List<AppOpenLogEntry> _parseRecentOpenLogs(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (item) => AppOpenLogEntry.fromMap(<String, dynamic>{
            for (final entry in item.entries) entry.key.toString(): entry.value,
          }),
        )
        .where(
          (entry) => entry.dateKey.isNotEmpty && entry.testerAppName.isNotEmpty,
        )
        .toList();
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
      'openCountByDate': openCountByDate,
      'openCountByTesterAppName': openCountByTesterAppName,
      'recentOpenLogs': recentOpenLogs.map((entry) => entry.toMap()).toList(),
      'boostUntil': boostUntil,
      'createdAt': createdAt,
      'endedAt': endedAt,
    };
  }
}
