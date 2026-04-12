import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'local_notification_service.dart';

class AppNotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  final Set<String> _processingDocIds = <String>{};

  Future<void> startForUser(String userId) async {
    await stop();
    if (userId.isEmpty) return;
    _subscription = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isNotified', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        if (_processingDocIds.add(doc.id)) {
          unawaited(_processNotification(userId: userId, doc: doc));
        }
      }
    });
  }

  Future<void> _processNotification({
    required String userId,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) async {
    try {
      final data = doc.data();
      final type = (data['type'] ?? '') as String;
      if (type == 'tester_joined') {
        final testerName = (data['testerName'] ?? '') as String;
        await LocalNotificationService.instance.showTesterJoinedNotification(
          testerName: testerName,
        );
      }
      await _db
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(doc.id)
          .set({
        'isNotified': true,
        'notifiedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } finally {
      _processingDocIds.remove(doc.id);
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _processingDocIds.clear();
  }
}
