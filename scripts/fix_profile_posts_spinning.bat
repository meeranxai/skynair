@echo off
echo ============================================
echo FIXING PROFILE POSTS SPINNING LOADING
echo ============================================
echo.

echo Issue: Profile loads but posts section shows spinning loading
echo Target: userPostsProvider stream for specific user
echo.

echo 1. Immediate diagnosis:
echo.
echo Step 1: Check if authorId index is ready
firebase firestore:indexes:list | findstr "authorId"
echo.

echo Step 2: Quick app test with console logging
echo.
echo Manual test steps:
echo 1. flutter run -d chrome --debug
echo 2. Open browser console (F12)
echo 3. Login and go to another user's profile
echo 4. Look for these console messages:
echo.
echo Expected logs:
echo ✓ "Processing X documents for user [uid]"
echo ✓ "Returning X media posts for user [uid]"
echo ❌ "getUserPostsStream timeout for user [uid]"
echo ❌ "Missing index for query: authorId"
echo.

echo 3. Quick fixes to try:
echo.
echo Fix 1: Wait for indexes (if still building)
echo - Check Firebase Console for "Enabled" status
echo - Wait 2-5 more minutes if still "Building"
echo.
echo Fix 2: Clear browser cache and restart
echo - Press Ctrl+Shift+Delete
echo - Clear all browsing data
echo - Restart browser and app
echo.
echo Fix 3: Test with different users
echo - Try user with many posts
echo - Try user with no posts (should show empty state)
echo - Try your own profile (should work)
echo.
echo Fix 4: Check data structure in Firestore
echo - Open Firestore Console
echo - Go to posts collection
echo - Verify posts have authorId field
echo - Verify authorId matches user UIDs
echo.

echo ============================================
echo EXPECTED BEHAVIOR:
echo.
echo ✅ Profile info loads (name, bio, stats)
echo ✅ Posts section loads within 15 seconds
echo ✅ Shows grid of posts OR "No posts yet" message
echo ✅ No infinite spinning loader
echo ✅ Console shows processing logs
echo ============================================
echo.

echo 4. If still failing after 10 minutes:
echo.
echo Emergency steps:
echo 1. Check Firebase Console → Indexes
echo 2. Look for any "Error" status indexes
echo 3. Re-deploy indexes: firebase deploy --only firestore:indexes
echo 4. Wait 5 more minutes
echo 5. Test again
echo.

echo 5. Data verification:
echo.
echo Check Firestore Console:
echo - posts collection exists
echo - Documents have authorId field
echo - authorId values match user UIDs from userProfiles
echo - postType field = "media" (for posts tab)
echo - createdAt field is valid timestamp
echo.

echo Opening Firebase Console for verification...
start https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
start https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data/~2Fposts
echo.

pause