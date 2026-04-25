import 'package:cloud_functions/cloud_functions.dart';

class AdminFeedbackService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  );

  Future<void> submit({
    required String type,
    required String message,
  }) async {
    final callable = _functions.httpsCallable('submitAdminFeedback');
    await callable.call(<String, dynamic>{
      'type': type,
      'message': message,
    });
  }
}

