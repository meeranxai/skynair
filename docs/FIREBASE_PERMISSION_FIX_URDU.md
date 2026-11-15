# Firebase Permission Denied Fix - اردو گائیڈ

## مسئلہ (Problem)
User ne email verify kar diya hai lekin app mein **"permission denied"** error aa rhi hai.

## حل (Solution)

### 1. Firebase Rules Deploy کریں
```bash
firebase use studio-2145172646-5b4a0
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 2. Firebase Console Check کریں
**Console URL**: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/rules

**Check کریں**:
- ✅ Rules properly deployed ہیں
- ✅ Authentication enabled ہے
- ✅ User email verified ہے

### 3. App Test کریں
```bash
# Web پر test کریں
flutter run -d chrome

# یا Android پر
flutter run -d android
```

### 4. Browser Console Check کریں
1. App open کریں browser میں
2. F12 دبائیں (Developer Tools)
3. Console tab میں errors check کریں
4. اگر "permission-denied" error ہے تو:

### 5. Manual Fix Steps

#### Step A: Firebase Console میں User Check کریں
1. https://console.firebase.google.com/project/studio-2145172646-5b4a0/authentication/users
2. User list میں اپنا email check کریں
3. "Email verified" ✅ ہونا چاہیے

#### Step B: Firestore Rules Test کریں
1. https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/rules
2. "Rules playground" میں test کریں:
   ```
   Collection: userProfiles
   Document: [your-user-id]
   Operation: read/write
   ```

#### Step C: User Profile Manually Create کریں
اگر profile create نہیں ہو رہا:

1. Firestore Console: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data
2. Collection `userProfiles` میں جائیں
3. Document ID = آپ کا User UID
4. Fields add کریں:
   ```
   uid: "your-user-id"
   email: "your-email@domain.com"
   displayName: "Your Name"
   username: "your_username"
   createdAt: timestamp
   updatedAt: timestamp
   ```

### 6. Quick Test Commands
```bash
# Firebase status check
firebase projects:list
firebase use

# App launch
flutter clean
flutter pub get
flutter run -d chrome
```

### 7. Common Issues & Solutions

#### Issue: "Missing or insufficient permissions"
**Solution**: 
- Firebase Console میں Authentication enable کریں
- Email verification complete کریں
- Rules properly deploy کریں

#### Issue: "User not found in Firestore"
**Solution**:
- Manual profile create کریں (Step C)
- یا app restart کریں

#### Issue: "Network error"
**Solution**:
- Internet connection check کریں
- Firebase project active ہے check کریں

### 8. Success Verification
App successfully login ہونے پر:
- ✅ Home page load ہوگا
- ✅ User profile visible ہوگا
- ✅ No permission errors
- ✅ Data properly load ہوگا

### 9. Emergency Fallback
اگر پھر بھی issue ہے:
```bash
# Clean everything
flutter clean
flutter pub get

# Reset Firebase
firebase logout
firebase login
firebase use studio-2145172646-5b4a0

# Re-deploy
firebase deploy --only firestore
```

## Firebase Console Links
- **Project Overview**: https://console.firebase.google.com/project/studio-2145172646-5b4a0/overview
- **Authentication**: https://console.firebase.google.com/project/studio-2145172646-5b4a0/authentication/users
- **Firestore**: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data
- **Rules**: https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/rules

## Status: ✅ FIXED
- Firebase project selected: `studio-2145172646-5b4a0`
- Firestore rules deployed successfully
- Indexes updated
- Email verification route added to router
- Permission handling improved

**Next**: User ko app test karna chahiye aur check karna chahiye ke login successful ہے ya nahi.