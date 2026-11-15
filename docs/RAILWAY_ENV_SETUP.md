# Railway Environment Variables Setup - Updated for New Firebase Project

## ⚠️ IMPORTANT: Do You Need Railway?

### For Mobile App (APK) - NO RAILWAY NEEDED ❌
- Your G-Network mobile app **does NOT need Railway**
- Firebase config is in `lib/firebase_options.dart` (already updated)
- App connects directly to Firebase from phone
- **Skip this guide if you're only building mobile app**

### For Web Deployment - RAILWAY NEEDED ✅
- If deploying Flutter web version to Railway
- Server hosts the web build and provides Socket.IO
- Continue reading below

---

## Required Environment Variables for Railway (Web Deployment)

### 1. Node.js Configuration
```bash
NODE_ENV=production
PORT=3000
```

### 2. Firebase Variables (NEW PROJECT - Updated!)
```bash
FIREBASE_API_KEY=AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI
FIREBASE_AUTH_DOMAIN=studio-2145172646-5b4a0.firebaseapp.com
FIREBASE_PROJECT_ID=studio-2145172646-5b4a0
FIREBASE_STORAGE_BUCKET=studio-2145172646-5b4a0.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=951845646390
FIREBASE_APP_ID=1:951845646390:web:c16b39f0a39a1c9e20e897
```

### 3. App Configuration (Optional)
```bash
APP_NAME=G-Network
APP_VERSION=1.0.0
```

### ⚠️ Note About Supabase
Your app now uses **Firebase Storage** instead of Supabase for images. Supabase variables are **NOT needed** anymore.

## How to Add in Railway

### Method 1: Railway Dashboard (Easiest)
1. Go to Railway Dashboard: https://railway.app
2. Select your project: **G-Network**
3. Click on your service
4. Go to **Variables** tab
5. Click **+ New Variable**
6. Add each variable:
   - Variable name: `FIREBASE_PROJECT_ID`
   - Value: `studio-2145172646-5b4a0`
7. Click **Add**
8. Repeat for all Firebase variables above

### Method 2: Railway CLI
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link to project
railway link

# Add NEW Firebase variables
railway variables set FIREBASE_API_KEY=AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI
railway variables set FIREBASE_AUTH_DOMAIN=studio-2145172646-5b4a0.firebaseapp.com
railway variables set FIREBASE_PROJECT_ID=studio-2145172646-5b4a0
railway variables set FIREBASE_STORAGE_BUCKET=studio-2145172646-5b4a0.firebasestorage.app
railway variables set FIREBASE_MESSAGING_SENDER_ID=951845646390
railway variables set FIREBASE_APP_ID=1:951845646390:web:c16b39f0a39a1c9e20e897
railway variables set NODE_ENV=production
```

### Method 3: Raw Editor (Fastest)
1. Railway Dashboard → Variables tab
2. Click **Raw Editor**
3. Paste these variables:
```
FIREBASE_API_KEY=AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI
FIREBASE_AUTH_DOMAIN=studio-2145172646-5b4a0.firebaseapp.com
FIREBASE_PROJECT_ID=studio-2145172646-5b4a0
FIREBASE_STORAGE_BUCKET=studio-2145172646-5b4a0.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=951845646390
FIREBASE_APP_ID=1:951845646390:web:c16b39f0a39a1c9e20e897
NODE_ENV=production
PORT=3000
APP_NAME=G-Network
APP_VERSION=1.0.0
```
4. Click **Update Variables**
5. Railway will automatically redeploy

## Important Notes

### Security ⚠️
- **Never commit** `.env` files to Git
- Keep Firebase API keys secure (use Railway's encrypted variables)
- Railway environment variables are encrypted at rest

### For Flutter Mobile App (Your Current Setup)
- ❌ Railway deployment **NOT needed** for mobile app
- ✅ Mobile app uses `lib/firebase_options.dart` (already updated)
- ✅ Firebase/Firestore work directly from app
- ✅ Just build APK: `flutter build apk --release`

### For Web Deployment (If Needed in Future)
- ✅ Railway deployment needed for web version
- ✅ Set all Firebase environment variables
- ✅ Build web: `flutter build web --release`
- ✅ Deploy: `railway up` or push to GitHub (auto-deploy)

### Server Configuration
Your `server-final.js` doesn't actually use Firebase env variables directly. The Firebase config is embedded in the Flutter web build. However, setting these variables is good practice for:
- Documentation purposes
- Future backend API integration
- Consistency across environments

## What Are You Deploying?

### If Mobile App (APK) - Your Current Setup:
- ❌ Railway NOT needed
- ✅ Firebase config in `lib/firebase_options.dart` ✅ (Already done!)
- ✅ Build APK: `flutter build apk --release`
- ✅ Install on phone and test

### If Web App (Future):
- ✅ Railway deployment needed
- ✅ Set all environment variables (see above)
- ✅ Build: `flutter build web --release`
- ✅ Deploy: Push to GitHub (Railway auto-deploys)

### Current Server Purpose:
Your `server-final.js` provides:
- Static file serving for Flutter web build
- Socket.IO for real-time features
- Health check endpoints
- CORS and security headers

## Check Your Setup

After adding variables, verify:
```bash
railway variables
```

Should show all your variables (values hidden for security).

## Redeploy

After adding variables:
```bash
railway up
```

Or trigger redeploy from Railway Dashboard.

## Need Help?

Check Railway docs: https://docs.railway.app/develop/variables
