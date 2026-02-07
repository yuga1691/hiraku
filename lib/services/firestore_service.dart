import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_model.dart';
import '../models/testing_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _apps => _db.collection('apps');

  Future<void> ensureUserDoc(String userId) async {
    final ref = _users.doc(userId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'username': '',
        'createdAt': FieldValue.serverTimestamp(),
        'testedCountTotal': 0,
      });
    }
  }

  Future<void> updateUsername(String userId, String username) async {
    await _users.doc(userId).set(
      {'username': username},
      SetOptions(merge: true),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String userId) {
    return _users.doc(userId).snapshots();
  }

  Stream<AppModel?> watchMyActiveApp(String userId) {
    return _apps
        .where('ownerUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      final doc = snapshot.docs.first;
      return AppModel.fromMap(doc.id, doc.data());
    });
  }

  Stream<List<AppModel>> watchAvailableApps() {
    return _apps
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppModel.fromMap(doc.id, doc.data()))
              .where((app) => app.remainingExposure > 0)
              .toList(),
        );
  }

  Future<void> registerApp({
    required String userId,
    required String name,
    required String playUrl,
    required String packageName,
    required String message,
    required String? iconBase64,
  }) async {
    final existing = await _apps
        .where('ownerUserId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('現在アクティブなアプリがあります。先に終了してください。');
    }

    await _apps.add({
      'ownerUserId': userId,
      'name': name,
      'playUrl': playUrl,
      'packageName': packageName,
      'message': message,
      'iconBase64': iconBase64,
      'isActive': true,
      'remainingExposure': 10,
      'openedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'endedAt': null,
    });
  }

  Future<void> endMyApp(String appId) async {
    await _apps.doc(appId).set(
      {
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<TestingModel>> watchTestingHistory(String userId) {
    return _users
        .doc(userId)
        .collection('testing')
        .orderBy('lastOpenedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TestingModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> openOtherAppTransaction({
    required String currentUserId,
    required AppModel targetApp,
  }) async {
    final targetRef = _apps.doc(targetApp.id);
    final userRef = _users.doc(currentUserId);

    final myActiveAppSnapshot = await _apps
        .where('ownerUserId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    final myActiveAppRef =
        myActiveAppSnapshot.docs.isEmpty ? null : myActiveAppSnapshot.docs.first.reference;

    final historyRef =
        _users.doc(currentUserId).collection('testing').doc(targetApp.id);

    await _db.runTransaction((tx) async {
      final targetSnap = await tx.get(targetRef);
      if (!targetSnap.exists) {
        throw Exception('対象のアプリが見つかりません。');
      }
      final data = targetSnap.data()!;
      final isActive = (data['isActive'] ?? false) as bool;
      final remaining = (data['remainingExposure'] ?? 0) as int;
      if (!isActive || remaining <= 0) {
        throw Exception('このアプリは現在テスト対象外です。');
      }

      final historySnap = await tx.get(historyRef);
      final prevCount = historySnap.exists
          ? (historySnap.data()!['openCountByMe'] ?? 0) as int
          : 0;
      tx.update(targetRef, {
        'openedCount': FieldValue.increment(1),
        'remainingExposure': FieldValue.increment(-1),
      });

      tx.set(
        userRef,
        {'testedCountTotal': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      if (myActiveAppRef != null) {
        tx.update(myActiveAppRef, {
          'remainingExposure': FieldValue.increment(1),
        });
      }

      tx.set(historyRef, {
        'appId': targetApp.id,
        'name': targetApp.name,
        'openCountByMe': prevCount + 1,
        'lastOpenedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
