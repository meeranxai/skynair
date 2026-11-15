# Message Navigation White Screen Fix ✅

## Problem (مسئلہ)
Jab messages list mein user par click karte hain to screen white ho jati hai.

## Root Cause (اصل وجہ)
**Parameter mismatch between navigation and router!**

### What Was Wrong:

**messages_list_page.dart** was using `extra` parameter:
```dart
context.push(
  '/chat/${conversation.id}',
  extra: {
    'otherUserId': otherUserId,
    'otherUserName': user.displayName,
    'otherUserAvatar': user.photoURL,
  },
);
```

**router_provider.dart** was expecting query parameters:
```dart
final otherUserId = state.uri.queryParameters['otherUserId']!;
final otherUserName = state.uri.queryParameters['otherUserName']!;
final otherUserAvatar = state.uri.queryParameters['otherUserAvatar'];
```

**Result:** Parameters were null, causing ChatPage to crash and show white screen!

## Solution (حل)

Changed navigation to use **query parameters** instead of `extra`:

### Before:
```dart
context.push(
  '/chat/${conversation.id}',
  extra: {...},  // ❌ Wrong
);
```

### After:
```dart
// Build query parameters
final queryParams = {
  'otherUserId': otherUserId,
  'otherUserName': user.displayName,
  if (user.photoURL != null) 'otherUserAvatar': user.photoURL!,
};

// Build URI with query parameters
final uri = Uri(
  path: '/chat/${conversation.id}',
  queryParameters: queryParams,
);

context.push(uri.toString());  // ✅ Correct
```

## Files Changed

✅ `lib/features/messages/pages/messages_list_page.dart`
- Changed navigation from `extra` to query parameters
- Added proper URI building with query parameters
- Added null check for avatar URL

## Testing (ٹیسٹنگ)

### Test Steps:
1. Open app
2. Go to Messages tab
3. Click on any conversation
4. ✅ Chat page should open properly
5. ✅ User name and avatar should display
6. ✅ No white screen

### Expected Behavior:
- ✅ Smooth navigation to chat page
- ✅ User details properly passed
- ✅ Chat loads correctly
- ✅ No errors in console

## Why This Happened

GoRouter has two ways to pass data:
1. **Query Parameters** - In URL: `/chat/123?userId=abc&name=John`
2. **Extra** - Separate object passed with navigation

Router was configured for query parameters but navigation was using extra, causing mismatch.

## Benefits of Query Parameters

✅ **URL-based** - Parameters visible in URL
✅ **Deep linking** - Can share chat links
✅ **Browser compatible** - Works in web version
✅ **Persistent** - Survives page refresh

## Related Files

- `lib/features/messages/pages/messages_list_page.dart` - Navigation source
- `lib/core/router/router_provider.dart` - Router configuration
- `lib/features/messages/pages/chat_page.dart` - Destination page

## Status: FIXED ✅

Messages list se chat page par navigation ab properly kaam kar raha hai!

## Quick Test Command

```bash
flutter run -d windows
```

Then:
1. Login karein
2. Messages tab par jayein
3. Kisi conversation par click karein
4. Chat page khul jayega (no white screen!)
