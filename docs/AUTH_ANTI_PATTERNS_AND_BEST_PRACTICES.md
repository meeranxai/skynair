# Auth Anti-Patterns and Best Practices

## 🚫 Anti-Patterns That Cause Login Screen Flicker

### 1. Router Watching Mutable State

#### ❌ Anti-Pattern:
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  // Watching entire auth state including mutable user data
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      // Router rebuilds on EVERY auth state change
      // Including profile updates, post count changes, etc.
    },
  );
});
```

**Why it's bad:**
- Router rebuilds on profile edits
- MaterialApp rebuilds
- All screens rebuild
- Login screen flashes

#### ✅ Best Practice:
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  // Only watch authentication boolean
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    redirect: (context, state) {
      // Router only rebuilds on login/logout
      // Profile updates don't affect routing
    },
  );
});
```

**Why it's good:**
- Router only rebuilds on actual auth changes
- Profile updates don't trigger rebuilds
- Smooth, flicker-free UX

---

### 2. Mixing Auth State with User Data

#### ❌ Anti-Pattern:
```dart
class AuthState {
  final User? firebaseUser;
  final UserModel? user;  // ❌ Mutable data in auth state
  final bool isLoading;
  final String? error;
}

class AuthNotifier extends StateNotifier<AuthState> {
  Future<void> updateProfile({String? displayName}) async {
    // Update Firestore
    await FirestoreService.updateUserProfile(...);
    
    // Update state - triggers router rebuild! ❌
    state = state.copyWith(
      user: state.user?.copyWith(displayName: displayName),
    );
  }
}
```

**Why it's bad:**
- Auth state changes on profile updates
- Router watches auth state
- Every profile update triggers navigation logic

#### ✅ Best Practice:
```dart
// Separate providers for separate concerns

// Auth State - ONLY for routing
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// User Profile - for UI data
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier();
});

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  Future<void> updateProfile({String? displayName}) async {
    // Update Firestore
    await FirestoreService.updateUserProfile(...);
    
    // Update state - does NOT affect router ✅
    state = state.copyWith(
      user: state.user?.copyWith(displayName: displayName),
    );
  }
}
```

**Why it's good:**
- Clear separation of concerns
- Auth state stable
- Profile updates don't affect routing

---

### 3. StreamBuilder in MaterialApp

#### ❌ Anti-Pattern:
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // MaterialApp rebuilds on EVERY auth event ❌
        return MaterialApp(
          home: snapshot.hasData ? HomePage() : LoginPage(),
        );
      },
    );
  }
}
```

**Why it's bad:**
- MaterialApp rebuilds on every auth event
- Token refresh triggers rebuild
- Profile updates trigger rebuild
- Entire app restarts

#### ✅ Best Practice:
```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Router handles navigation, MaterialApp stays stable
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      routerConfig: router,  // ✅ Stable, only rebuilds on login/logout
    );
  }
}
```

**Why it's good:**
- MaterialApp built once
- Router handles navigation
- Smooth transitions

---

### 4. FutureBuilder for Auth in Every Screen

#### ❌ Anti-Pattern:
```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      // Fetches user data every time screen builds ❌
      future: FirestoreService.getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        final user = snapshot.data;
        return Text(user?.displayName ?? '');
      },
    );
  }
}
```

**Why it's bad:**
- Fetches data on every screen build
- No caching
- Unnecessary network requests
- Loading indicators everywhere

#### ✅ Best Practice:
```dart
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use cached provider ✅
    final profileState = ref.watch(userProfileProvider);
    final user = profileState.user;
    
    if (profileState.isLoading) {
      return CircularProgressIndicator();
    }
    
    return Text(user?.displayName ?? '');
  }
}
```

**Why it's good:**
- Data cached in provider
- Single fetch on login
- Fast screen transitions
- Consistent data across app

---

### 5. Updating Auth State on Every Write

#### ❌ Anti-Pattern:
```dart
Future<void> createPost(PostModel post) async {
  await FirestoreService.createPost(post);
  
  // Update auth state with new post count ❌
  final authNotifier = ref.read(authProvider.notifier);
  authNotifier.updateUserPostCount(newCount);
  // This triggers router rebuild!
}

Future<void> followUser(String userId) async {
  await FirestoreService.followUser(userId);
  
  // Update auth state with new follower count ❌
  final authNotifier = ref.read(authProvider.notifier);
  authNotifier.updateFollowerCount(newCount);
  // This triggers router rebuild!
}
```

**Why it's bad:**
- Every write operation updates auth state
- Auth state changes trigger router rebuild
- App feels sluggish and broken

#### ✅ Best Practice:
```dart
Future<void> createPost(PostModel post) async {
  await FirestoreService.createPost(post);
  
  // Update user profile provider, NOT auth state ✅
  ref.read(userProfileProvider.notifier).refreshProfile();
  // Router not affected
}

Future<void> followUser(String userId) async {
  await FirestoreService.followUser(userId);
  
  // Update user profile provider ✅
  ref.read(userProfileProvider.notifier).refreshProfile();
  // Router not affected
}
```

**Why it's good:**
- Write operations don't affect routing
- Smooth UX
- No unnecessary rebuilds

---

### 6. Auth State Changes on Token Refresh

#### ❌ Anti-Pattern:
```dart
void _init() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    // This fires on token refresh too! ❌
    state = state.copyWith(firebaseUser: user);
    
    if (user != null) {
      _loadUserProfile(user);  // Unnecessary reload
    }
  });
}
```

**Why it's bad:**
- Token refresh triggers profile reload
- Happens every hour
- Unnecessary network requests
- Can cause UI flicker

#### ✅ Best Practice:
```dart
void _init() {
  FirebaseAuth.instance.authStateChanges().listen((user) {
    // Only react to actual login/logout ✅
    if (state.firebaseUser?.uid != user?.uid) {
      state = state.copyWith(firebaseUser: user);
      
      if (user != null) {
        _loadUserProfile(user);
      }
    }
    // Token refresh doesn't trigger reload
  });
}
```

**Why it's good:**
- Only loads profile on actual auth change
- Token refresh ignored
- Better performance

---

### 7. Global State for Local UI

#### ❌ Anti-Pattern:
```dart
// Storing UI state in auth provider ❌
class AuthState {
  final User? firebaseUser;
  final UserModel? user;
  final bool isEditingProfile;  // ❌ UI state in auth
  final bool isUploadingImage;  // ❌ UI state in auth
}

// Every UI state change triggers router rebuild
```

**Why it's bad:**
- UI state mixed with auth state
- Router rebuilds on UI changes
- Poor separation of concerns

#### ✅ Best Practice:
```dart
// Keep UI state local ✅
class EditProfileDialog extends StatefulWidget {
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  bool isUploading = false;  // ✅ Local UI state
  
  @override
  Widget build(BuildContext context) {
    // UI state doesn't affect global providers
  }
}
```

**Why it's good:**
- UI state stays local
- No global state pollution
- Better performance

---

### 8. Synchronous State Updates

#### ❌ Anti-Pattern:
```dart
Future<void> updateProfile({String? displayName}) async {
  // Update state immediately ❌
  state = state.copyWith(
    user: state.user?.copyWith(displayName: displayName),
  );
  
  // Then update Firestore
  await FirestoreService.updateUserProfile(...);
  // If this fails, state is inconsistent!
}
```

**Why it's bad:**
- Optimistic update can fail
- State becomes inconsistent
- No error recovery

#### ✅ Best Practice:
```dart
Future<void> updateProfile({String? displayName}) async {
  try {
    // Update Firestore first ✅
    await FirestoreService.updateUserProfile(...);
    
    // Then update state (only on success)
    state = state.copyWith(
      user: state.user?.copyWith(displayName: displayName),
    );
  } catch (e) {
    // State remains consistent
    state = state.copyWith(error: e.toString());
    rethrow;
  }
}
```

**Why it's good:**
- State always consistent
- Proper error handling
- Reliable updates

---

### 9. Multiple Auth Listeners

#### ❌ Anti-Pattern:
```dart
// In main.dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  // Handle auth change
});

// In auth_provider.dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  // Handle auth change again
});

// In router_provider.dart
FirebaseAuth.instance.authStateChanges().listen((user) {
  // Handle auth change yet again
});
```

**Why it's bad:**
- Multiple listeners for same event
- Duplicate logic
- Hard to maintain
- Race conditions

#### ✅ Best Practice:
```dart
// Single source of truth ✅
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Everyone watches this provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

// Router watches
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  // ...
});
```

**Why it's good:**
- Single source of truth
- Consistent behavior
- Easy to maintain

---

### 10. Ignoring Loading States

#### ❌ Anti-Pattern:
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    redirect: (context, state) {
      // What if authState is loading? ❌
      final isAuthenticated = authState.value != null;
      // User might see login screen while loading
    },
  );
});
```

**Why it's bad:**
- Login screen flashes during loading
- Poor UX
- Confusing for users

#### ✅ Best Practice:
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',  // ✅ Show splash while loading
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') {
        return null;  // Allow splash screen
      }
      
      return authState.when(
        data: (user) {
          final isAuthenticated = user != null;
          // Handle routing based on auth state
        },
        loading: () => '/splash',  // ✅ Stay on splash while loading
        error: (_, __) => '/login',
      );
    },
  );
});
```

**Why it's good:**
- Smooth loading experience
- No login screen flash
- Better UX

---

## ✅ Best Practices Summary

### 1. Separation of Concerns
```dart
// Auth State - for routing
final authStateProvider = StreamProvider<User?>(...)

// User Profile - for UI
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(...)

// Auth Actions - for operations
final authActionsProvider = Provider<AuthActions>(...)
```

### 2. Minimal Router Dependencies
```dart
// Router watches ONLY authentication boolean
final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  // ...
});
```

### 3. Stable MaterialApp
```dart
// MaterialApp never rebuilds
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(routerConfig: router);
  }
}
```

### 4. Cached User Data
```dart
// Load once, cache in provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  final authState = ref.watch(authStateProvider);
  return UserProfileNotifier(authState.value);
});
```

### 5. Local UI Updates
```dart
// Profile updates don't affect routing
await ref.read(userProfileProvider.notifier).updateProfile(
  displayName: newName,
);
// Router not affected, UI updates instantly
```

### 6. Proper Error Handling
```dart
try {
  await ref.read(authActionsProvider).signInWithEmailAndPassword(email, password);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Login failed: $e')),
  );
}
```

### 7. Loading States
```dart
// Show splash screen while loading
if (state.matchedLocation == '/splash') {
  return null;
}

// Handle loading state properly
return authState.when(
  data: (user) => /* handle auth */,
  loading: () => '/splash',
  error: (_, __) => '/login',
);
```

### 8. Single Source of Truth
```dart
// One auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Everyone watches this
```

### 9. Consistent State Updates
```dart
// Update Firestore first, then state
await FirestoreService.updateUserProfile(...);
state = state.copyWith(user: updatedUser);
```

### 10. Performance Optimization
```dart
// Use select to watch specific fields
final userName = ref.watch(
  userProfileProvider.select((state) => state.user?.displayName),
);
// Only rebuilds when displayName changes
```

---

## 🎓 Key Principles

1. **Auth state is for routing, not UI data**
2. **Router should watch minimal state**
3. **Profile updates should not affect routing**
4. **MaterialApp should be stable**
5. **UI state should be local**
6. **Data should be cached**
7. **Loading states should be handled**
8. **Errors should be caught**
9. **State should be consistent**
10. **Performance should be optimized**

---

## 📚 Related Documentation

- `AUTH_FLICKER_FIX_GUIDE.md` - Complete explanation
- `AUTH_FLICKER_IMPLEMENTATION_STEPS.md` - Step-by-step guide
- `AUTH_FLICKER_QUICK_FIX.md` - Quick reference
- `AUTH_ARCHITECTURE_DIAGRAM.md` - Visual guide
