@echo off
echo ============================================
echo DEBUGGING PROFILE POSTS LOADING ISSUE
echo ============================================
echo.

echo Issue: Profile loads but posts section shows spinning loading
echo Focus: userPostsProvider stream timeout/error
echo.

echo 1. Quick diagnosis steps:
echo.
echo Step 1: Check Firebase indexes status
echo Opening Firebase Console...
start https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/indexes
echo.
echo Look for these indexes and their status:
echo ✓ posts.authorId - should be "Enabled"
echo ✓ posts.postType - should be "Enabled" 
echo ✓ posts (authorId, createdAt) - should be "Enabled"
echo.

echo Step 2: Check browser console for specific errors
echo.
echo Manual steps:
echo 1. Open app: flutter run -d chrome
echo 2. Login and go to another user's profile
echo 3. Press F12 (Developer Tools)
echo 4. Go to Console tab
echo 5. Look for these specific errors:
echo.
echo Expected errors to look for:
echo ❌ "getUserPostsStream timed out"
echo ❌ "Missing index for query: authorId"
echo ❌ "Permission denied"
echo ❌ "Error processing posts snapshot"
echo.

echo Step 3: Check Firestore data structure
echo Opening Firestore Console...
start https://console.firebase.google.com/project/studio-2145172646-5b4a0/firestore/data/~2Fposts
echo.
echo Verify posts collection has:
echo ✓ Documents exist
echo ✓ authorId field matches user UIDs
echo ✓ postType field = "media" or "article"
echo ✓ createdAt field is timestamp
echo ✓ isArchived field is false or missing
echo.

echo Step 4: Test with different users
echo.
echo Try these scenarios:
echo 1. User with posts - should show grid
echo 2. User with no posts - should show "No posts yet"
echo 3. Your own profile - should work fine
echo 4. New user account - should show empty state
echo.

echo ============================================
echo LIKELY CAUSES & QUICK FIXES:
echo.
echo CAUSE 1: authorId index still building
echo SOLUTION: Wait 2-5 more minutes, check Firebase Console
echo.
echo CAUSE 2: Posts collection empty or wrong structure
echo SOLUTION: Check Firestore Console, verify data exists
echo.
echo CAUSE 3: getUserPostsStream timeout (10 seconds)
echo SOLUTION: Already fixed, should show error after 10 seconds
echo.
echo CAUSE 4: Wrong postType filtering
echo SOLUTION: Check posts have postType="media" field
echo.
echo CAUSE 5: Permission denied on posts collection
echo SOLUTION: Check Firestore rules allow read access
echo ============================================
echo.

echo 5. Quick test commands:
echo.
echo Test 1: Check if indexes are ready
firebase firestore:indexes:list
echo.
echo Test 2: Clean build and retry
echo flutter clean
echo flutter pub get  
echo flutter run -d chrome
echo.

echo 6. Expected timeline:
echo - Index building: 2-10 minutes from deployment
echo - Posts loading: 1-3 seconds after indexes ready
echo - Error timeout: 10 seconds if still failing
echo.

pause