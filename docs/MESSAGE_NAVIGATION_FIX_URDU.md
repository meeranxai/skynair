# Message Navigation - سفید سکرین کا مسئلہ حل ✅

## مسئلہ کیا تھا؟

جب آپ messages list میں کسی user پر click کرتے تھے تو screen سفید ہو جاتی تھی.

## اصل وجہ

**Navigation اور Router میں parameters کا طریقہ مختلف تھا!**

### غلطی:

**messages_list_page.dart** میں `extra` استعمال ہو رہا تھا:
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

**router_provider.dart** میں query parameters چاہیے تھے:
```dart
final otherUserId = state.uri.queryParameters['otherUserId']!;
final otherUserName = state.uri.queryParameters['otherUserName']!;
```

**نتیجہ:** Parameters null تھے، ChatPage crash ہو رہا تھا، سفید screen دکھ رہی تھی!

## حل

Navigation کو **query parameters** استعمال کرنے کے لیے تبدیل کیا:

### پہلے:
```dart
context.push(
  '/chat/${conversation.id}',
  extra: {...},  // ❌ غلط
);
```

### اب:
```dart
// Query parameters بنائیں
final queryParams = {
  'otherUserId': otherUserId,
  'otherUserName': user.displayName,
  if (user.photoURL != null) 'otherUserAvatar': user.photoURL!,
};

// URI بنائیں query parameters کے ساتھ
final uri = Uri(
  path: '/chat/${conversation.id}',
  queryParameters: queryParams,
);

context.push(uri.toString());  // ✅ صحیح
```

## تبدیل شدہ فائل

✅ `lib/features/messages/pages/messages_list_page.dart`
- Navigation کو `extra` سے query parameters میں تبدیل کیا
- URI properly build کیا query parameters کے ساتھ
- Avatar URL کے لیے null check شامل کیا

## ٹیسٹ کیسے کریں؟

### قدم:
1. App کھولیں
2. Messages tab پر جائیں
3. کسی conversation پر click کریں
4. ✅ Chat page کھل جائے گا
5. ✅ User کا نام اور تصویر دکھے گی
6. ✅ سفید screen نہیں آئے گی

### متوقع نتیجہ:
- ✅ Chat page آسانی سے کھل جائے گا
- ✅ User کی تفصیلات صحیح طریقے سے منتقل ہوں گی
- ✅ Chat load ہو جائے گی
- ✅ Console میں کوئی errors نہیں

## یہ کیوں ہوا؟

GoRouter میں data pass کرنے کے دو طریقے ہیں:
1. **Query Parameters** - URL میں: `/chat/123?userId=abc&name=John`
2. **Extra** - علیحدہ object navigation کے ساتھ

Router query parameters کے لیے configured تھا لیکن navigation extra استعمال کر رہا تھا، اس لیے mismatch ہو گیا.

## Query Parameters کے فوائد

✅ **URL-based** - Parameters URL میں نظر آتے ہیں
✅ **Deep linking** - Chat links share کر سکتے ہیں
✅ **Browser compatible** - Web version میں کام کرتا ہے
✅ **Persistent** - Page refresh کے بعد بھی رہتے ہیں

## متعلقہ فائلیں

- `lib/features/messages/pages/messages_list_page.dart` - Navigation کا source
- `lib/core/router/router_provider.dart` - Router configuration
- `lib/features/messages/pages/chat_page.dart` - Destination page

## Status: حل ہو گیا ✅

Messages list سے chat page پر navigation اب ٹھیک سے کام کر رہا ہے!

## فوری ٹیسٹ

```bash
flutter run -d windows
```

پھر:
1. Login کریں
2. Messages tab پر جائیں
3. کسی conversation پر click کریں
4. Chat page کھل جائے گا (سفید screen نہیں!)

## خلاصہ

**مسئلہ:** Navigation اور Router میں parameters کا طریقہ مختلف تھا

**حل:** Navigation کو query parameters استعمال کرنے کے لیے تبدیل کیا

**نتیجہ:** اب messages list سے chat page پر جانا بالکل ٹھیک کام کر رہا ہے! 🎉
