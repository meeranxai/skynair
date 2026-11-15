import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Family provider for fetching any user's profile by UID (Real-time)
final userProfileByIdProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserProfileStream(userId);
});

/// Family provider for user search
final userSearchProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) {
    return [];
  }
  return await FirestoreService.searchUsers(query);
});

/// Family provider for user followers
final userFollowersProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  userId,
) async {
  return await FirestoreService.getUserFollowers(userId);
});

/// Family provider for user following
final userFollowingProvider = FutureProvider.family<List<UserModel>, String>((
  ref,
  userId,
) async {
  return await FirestoreService.getUserFollowing(userId);
});

/// Family provider for user posts count
final userPostsCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserProfileStream(userId).map((user) {
    return user?.postsCount ?? 0;
  });
});

/// Family provider for user followers count
final userFollowersCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserProfileStream(userId).map((user) {
    return user?.followersCount ?? 0;
  });
});

/// Family provider for user following count
final userFollowingCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return FirestoreService.getUserProfileStream(userId).map((user) {
    return user?.followingCount ?? 0;
  });
});

/// Family provider for fetching user by username
final userByUsernameProvider = FutureProvider.family<UserModel?, String>((
  ref,
  username,
) async {
  return await FirestoreService.getUserByUsername(username);
});
