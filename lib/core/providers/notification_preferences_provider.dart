import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_preferences.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final notificationPreferencesProvider = StreamProvider<NotificationPreferences>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) {
    return Stream.value(const NotificationPreferences());
  }
  return FirestoreService.getNotificationPreferencesStream(user.uid);
});

final notificationPreferencesNotifierProvider =
    Provider<NotificationPreferencesNotifier>((ref) {
  return NotificationPreferencesNotifier(ref);
});

class NotificationPreferencesNotifier {
  final Ref _ref;

  NotificationPreferencesNotifier(this._ref);

  Future<void> togglePushNotifications(bool enabled) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    await FirestoreService.updateNotificationPreferences(
      user.uid,
      {'pushNotificationsEnabled': enabled},
    );
  }

  Future<void> toggleLikesAndComments(bool enabled) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    await FirestoreService.updateNotificationPreferences(
      user.uid,
      {'likesAndCommentsEnabled': enabled},
    );
  }

  Future<void> toggleNewFollowers(bool enabled) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    await FirestoreService.updateNotificationPreferences(
      user.uid,
      {'newFollowersEnabled': enabled},
    );
  }
}
