# Auth Flicker - Quick Fix Reference

## 🎯 The Problem
Profile edits and post creation cause the app to restart and show login screen.

## 🔧 The Solution
Separate auth state (for routing) from user profile data (for UI).

---

## 📦 New Files Created

1. `lib/core/providers/auth_state_provider.dart` - Minimal auth for routing
2. `lib/core/providers/user_profile_provider.dart` - User data management
3. `lib/core/router/router_provider_fixed.dart` - Fixed router

---

## 🔄 Quick Migration Guide

### 1. Router (CRITICAL FIX)
```dart
// OLD - lib/core/router/router_provider.dart
import '../providers/auth_provider.dart';
final authState = ref.watch(authProvider);  // ❌

// NEW
import '../providers/auth_state_provider.dart';
final isAuthenticated = ref.watch(isAuthenticatedProvider);  // ✅
```

### 2. Login/Logout Actions
```dart
// OLD
await ref.read(authProvider.notifier).login(email, password);
await ref.read(authProvider.notifier).signOut();

// NEW
await ref.read(authActionsProvider).signInWithEmailAndPassword(email, password);
await ref.read(authActionsProvider).signOut();
```

### 3. Display User Data
```dart
// OLD
final authState = ref.watch(authProvider);
final user = authState.user;

// NEW
final profileState = ref.watch(userProfileProvider);
final user = profileState.user;
```

### 4. Update Profile (CRITICAL FIX)
```dart
// OLD - Causes app restart ❌
await ref.read(authProvider.notifier).updateUserProfile(
  displayName: name,
  bio: bio,
);

// NEW - No app restart ✅
await ref.read(userProfileProvider.notifier).updateProfile(
  displayName: name,
  bio: bio,
);
```

---

## 📝 Files to Update

### Priority 1 (Critical - Causes Flicker)
- [ ] `lib/core/router/router_provider.dart` - Router watching wrong state
- [ ] `lib/features/profile/widgets/enhanced_edit_profile_dialog.dart` - Profile edit

### Priority 2 (Important)
- [ ] `lib/features/auth/pages/login_page.dart` - Login actions
- [ ] `lib/features/auth/pages/signup_page.dart` - Signup actions
- [ ] `lib/features/settings/pages/settings_page.dart` - Logout action

### Priority 3 (UI Display)
- [ ] `lib/features/profile/pages/profile_page.dart` - Display user data
- [ ] `lib/features/home/pages/home_page.dart` - Display user data
- [ ] `lib/features/create_post/pages/create_post_page.dart` - Get user data

---

## 🧪 Quick Test

### Test Profile Edit (Most Important)
1. Login to app
2. Go to profile
3. Click edit
4. Change name
5. Save
6. ✅ Should update instantly
7. ✅ Should NOT show login screen
8. ✅ Should NOT restart app

### If Still Seeing Flicker
```bash
# Find files still using old provider
grep -r "ref.watch(authProvider)" lib/
grep -r "authProvider.notifier" lib/

# Update those files to use new providers
```

---

## 🎯 Key Principle

```
┌─────────────────────────────────────────┐
│  Auth State (for routing)               │
│  - Login/Logout ONLY                    │
│  - Changes rarely                       │
│  - Router watches this                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  User Profile (for UI)                  │
│  - Name, photo, bio, etc.               │
│  - Changes frequently                   │
│  - UI screens watch this                │
│  - Router IGNORES this                  │
└─────────────────────────────────────────┘
```

---

## 🚀 Expected Result

### Before Fix:
```
Edit Profile → App Restarts → Login Screen Flash → Splash → Back to App
Time: 2-3 seconds ❌
```

### After Fix:
```
Edit Profile → Profile Updates Instantly
Time: 100ms ✅
```

---

## 📚 Full Documentation

- `AUTH_FLICKER_FIX_GUIDE.md` - Complete explanation and architecture
- `AUTH_FLICKER_IMPLEMENTATION_STEPS.md` - Step-by-step migration guide

---

## ✅ Success Checklist

- [ ] Router only watches `isAuthenticatedProvider`
- [ ] Profile edit uses `userProfileProvider.notifier.updateProfile()`
- [ ] Login uses `authActionsProvider.signInWithEmailAndPassword()`
- [ ] Logout uses `authActionsProvider.signOut()`
- [ ] UI screens watch `userProfileProvider` for user data
- [ ] No files reference old `authProvider` (except legacy/backup)
- [ ] Profile edit does NOT show login screen
- [ ] Post creation does NOT show login screen
- [ ] App resume does NOT show login screen
