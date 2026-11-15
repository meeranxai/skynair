# Railway Setup for New Firebase Project - Quick Guide

## Do You Need This? 🤔

### Mobile App (APK) - NO ❌
If you're building a mobile app (which you are), **you don't need Railway at all**. Your Firebase config is already in `lib/firebase_options.dart` and works directly from the phone.

### Web App - YES ✅
Only if you want to deploy a web version of G-Network to Railway.

---

## If You Need Railway (Web Deployment)

### Step 1: Update Environment Variables

Go to Railway Dashboard → Your Project → Variables tab → Raw Editor

**Copy and paste these NEW variables:**

```env
# Firebase Configuration (NEW PROJECT)
FIREBASE_API_KEY=AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI
FIREBASE_AUTH_DOMAIN=studio-2145172646-5b4a0.firebaseapp.com
FIREBASE_PROJECT_ID=studio-2145172646-5b4a0
FIREBASE_STORAGE_BUCKET=studio-2145172646-5b4a0.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=951845646390
FIREBASE_APP_ID=1:951845646390:web:c16b39f0a39a1c9e20e897

# Node.js Configuration
NODE_ENV=production
PORT=3000

# App Info
APP_NAME=G-Network
APP_VERSION=1.0.0
```

### Step 2: Remove Old Variables (If Any)

Delete these OLD Firebase variables if they exist:
- `FIREBASE_PROJECT_ID=g-network-community` ❌
- Any old Firebase API keys ❌
- Supabase variables (not needed anymore) ❌

### Step 3: Trigger Redeploy

After updating variables:
1. Railway will automatically redeploy
2. Or manually trigger: Settings → Redeploy

### Step 4: Verify Deployment

Check these endpoints:
- Health: `https://your-app.railway.app/health`
- Status: `https://your-app.railway.app/api/status`

Should return:
```json
{
  "status": "healthy",
  "service": "G-Network Social Media App",
  "socket": "active"
}
```

---

## Summary

### For Mobile App (Your Current Setup):
✅ **No Railway needed**
✅ Firebase config already updated in `lib/firebase_options.dart`
✅ Just build APK and test on phone

### For Web App (If Deploying):
✅ Update Railway environment variables (see above)
✅ Push to GitHub (Railway auto-deploys)
✅ Or manually deploy: `railway up`

---

## Quick Reference

### Old Firebase Project (Remove):
- Project ID: `g-network-community` ❌
- API Key: `AIzaSyD8Sg8rBwkCS4BYwgVrb_V_KQ4eMd0PkZ0` ❌

### New Firebase Project (Use):
- Project ID: `studio-2145172646-5b4a0` ✅
- API Key: `AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI` ✅

### What Changed:
- ✅ Firebase project credentials
- ✅ Storage bucket URL
- ✅ Auth domain
- ❌ Removed Supabase (using Firebase Storage now)

---

**Agar aap sirf mobile app bana rahe ho, to Railway ki zaroorat nahi hai. Sirf web version deploy karne ke liye Railway chahiye!** 📱
