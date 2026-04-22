class HirakuUser {
  HirakuUser({
    required this.id,
    required this.username,
    required this.createdAt,
    required this.testedCountTotal,
    required this.hasInitialUserBadge,
    required this.hasOfficialBadge,
  });

  final String id;
  final String username;
  final DateTime? createdAt;
  final int testedCountTotal;
  final bool hasInitialUserBadge;
  final bool hasOfficialBadge;

  factory HirakuUser.fromMap(String id, Map<String, dynamic> data) {
    return HirakuUser(
      id: id,
      username: (data['username'] ?? '') as String,
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
      testedCountTotal: (data['testedCountTotal'] ?? 0) as int,
      hasInitialUserBadge: (data['hasInitialUserBadge'] ?? false) as bool,
      hasOfficialBadge: (data['hasOfficialBadge'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'createdAt': createdAt,
      'testedCountTotal': testedCountTotal,
      'hasInitialUserBadge': hasInitialUserBadge,
      'hasOfficialBadge': hasOfficialBadge,
    };
  }
}
