@echo off
echo ========================================
echo Firebase Media Post Checker
echo ========================================
echo.
echo Ye script aapko Firebase Console open karega
echo taake aap check kar saken ke:
echo.
echo 1. Images Firebase Storage mein upload ho rahi hain ya nahi
echo 2. Firestore posts mein image URL save ho raha hai ya nahi
echo.
echo ========================================
echo Opening Firebase Console...
echo ========================================
echo.
echo STEP 1: Check Storage
echo - Go to Storage tab
echo - Look for "post_images" folder
echo - Check if your images are there
echo.
echo STEP 2: Check Firestore
echo - Go to Firestore Database tab
echo - Open "posts" collection
echo - Find your latest post
echo - Check if "image" field has a URL
echo.
echo STEP 3: Test Image URL
echo - Copy the image URL from Firestore
echo - Paste it in browser
echo - See if image loads
echo.
echo Opening Firebase Console in browser...
start https://console.firebase.google.com/
echo.
echo ========================================
echo Manual Check Instructions:
echo ========================================
echo.
echo 1. Select your project
echo 2. Go to Storage (left sidebar)
echo 3. Check if post_images folder exists
echo 4. Go to Firestore Database
echo 5. Open posts collection
echo 6. Click on any post document
echo 7. Look for "image" field
echo 8. If image field is null or empty:
echo    - Image upload is failing
echo    - Check storage rules
echo    - Check app logs
echo.
echo 9. If image field has URL but not showing in app:
echo    - Copy URL and test in browser
echo    - Check if URL is accessible
echo    - Check app's image loading code
echo.
pause
