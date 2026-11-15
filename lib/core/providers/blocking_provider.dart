import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/blocking_service.dart';
import 'auth_provider.dart';

final blockedUserIdsProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }
  return BlockingService.getBlockedUserIdsStream(authState.user!.uid);
});

final blockedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }
  return BlockingService.getBlockedUsersStream(authState.user!.uid);
});

final isUserBlockedProvider = StreamProvider.family<bool, String>((
  ref,
  targetUserId,
) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value(false);
  }

  // Add safety check for same user
  if (authState.user!.uid == targetUserId) {
    return Stream.value(false);
  }

  try {
    return BlockingService.isUserBlockedStream(
      authState.user!.uid,
      targetUserId,
    ).handleError((error) {
      print('❌ isUserBlockedProvider stream error: $error');
      // Return false on error to not break UI
      return false;
    });
  } catch (e) {
    print('❌ isUserBlockedProvider error: $e');
    return Stream.value(false);
  }
});

final isEitherBlockedProvider = StreamProvider.family<bool, String>((
  ref,
  targetUserId,
) {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return Stream.value(false);
  }

  if (authState.user!.uid == targetUserId) {
    return Stream.value(false);
  }

  // Combine both directions of blocking
  return BlockingService.isEitherBlockedStream(
    authState.user!.uid,
    targetUserId,
  );
});

final blockingNotifierProvider =
    StateNotifierProvider<BlockingNotifier, BlockingState>((ref) {
      final authState = ref.watch(authProvider);
      return BlockingNotifier(authState.user?.uid);
    });

class BlockingState {
  final bool isLoading;
  final String? error;

  BlockingState({this.isLoading = false, this.error});

  BlockingState copyWith({bool? isLoading, String? error}) {
    return BlockingState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class BlockingNotifier extends StateNotifier<BlockingState> {
  final String? _currentUserId;

  BlockingNotifier(this._currentUserId) : super(BlockingState());

  Future<void> blockUser(String targetUserId) async {
    if (_currentUserId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await BlockingService.blockUser(_currentUserId!, targetUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    if (_currentUserId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await BlockingService.unblockUser(_currentUserId!, targetUserId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
