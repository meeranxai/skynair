@echo off
echo ============================================
echo FIXING ALL FEED LOADING ISSUES
echo ============================================
echo.

echo 1. Deploying ALL missing Firestore indexes...
echo   - Posts indexes (authorId, postType, createdAt)
echo   - Follows indexes (followerId, followingId)
echo   - Composite indexes for queries
echo.
firebase deploy --only firestore:indexes

echo.
echo 2. Checking Firebase project status...
firebase use

echo.
echo 3. Verifying deployed indexes...
echo Opening Firebase Console to check index status...
echo https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
echo.

echo 4. Testing all feed types...
echo.
echo MANUAL TEST CHECKLIST:
echo.
echo ✓ HOME FEED:
echo   - Open app: flutter run -d chrome
echo   - Login with your account
echo   - Check "For You" tab loads posts
echo   - Switch to "Following" tab
echo   - Switch to "Trending" tab
echo   - All should load without spinning errors
echo.
echo ✓ PROFILE POSTS:
echo   - Go to your profile (bottom nav)
echo   - Check your posts load in grid
echo   - Visit another user's profile
echo   - Check their posts load properly
echo.
echo ✓ FOLLOWING FEED:
echo   - Go to Home → Following tab
echo   - Should show posts from people you follow
echo   - If empty, follow someone first
echo.
echo ✓ TRENDING FEED:
echo   - Go to Home → Trending tab
echo   - Should show popular posts
echo   - Based on likes and engagement
echo.

echo 5. Common issues and wait times:
echo.
echo ⏳ INDEX BUILDING TIME:
echo   - Single field indexes: 1-2 minutes
echo   - Composite indexes: 2-5 minutes
echo   - Large collections: Up to 10 minutes
echo.
echo 🔍 DEBUGGING STEPS:
echo   - Press F12 in browser (Developer Tools)
echo   - Go to Console tab
echo   - Look for "Missing index" errors
echo   - Wait for indexes to show "Enabled" status
echo.
echo 🚨 IF STILL FAILING:
echo   - Clear browser cache (Ctrl+Shift+Delete)
echo   - Restart app: flutter clean && flutter run
echo   - Check Firebase Console for index status
echo   - Wait additional 5 minutes for propagation
echo.

echo ============================================
echo FIREBASE CONSOLE QUICK LINKS:
echo.
echo Indexes Status:
echo https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
echo.
echo Firestore Data:
echo https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data
echo.
echo Authentication:
echo https://console.firebase.google.com/project/studio-2145172646-5b4a0/authentication/users
echo ============================================

echo.
echo 6. Expected Results After Fix:
echo   ✅ Home feed loads all tabs (For You, Following, Trending)
echo   ✅ Profile posts load in grid format
echo   ✅ Other users' profiles show their posts
echo   ✅ No more spinning loaders stuck
echo   ✅ Pull-to-refresh works on all feeds
echo   ✅ Fast loading times (under 3 seconds)
echo.

pause