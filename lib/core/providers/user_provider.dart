
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

final userProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return FirestoreService.getUserProfileStream(uid);
});
