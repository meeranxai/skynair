# Manual Demo Stories Cleanup - Step by Step 🧹

Script run karne mein issues aa rahe hain, to yeh manual steps follow karo:

---

## Method 1: Firebase Console (Easiest) ✅

### Step 1: Firebase Console Kholo
1. Browser mein jao: https://console.firebase.google.com
2. Apna project select karo

### Step 2: Firestore Database Kholo
1. Left sidebar se **"Firestore Database"** par click karo
2. **"Data"** tab par jao

### Step 3: Stories Collection Kholo
1. **"stories"** collection par click karo
2. Saari stories ki list dikhegi

### Step 4: Demo Stories Delete Karo
Demo users ki stories identify karo (userName field dekho):
- ❌ user1
- ❌ user2  
- ❌ user3
- ❌ user4
- ❌ demo_user
- ❌ test_user

**Har demo story ke liye:**
1. Story document par click karo
2. Top right mein **"Delete document"** (trash icon) par click karo
3. Confirm karo

### Step 5: Verify
- Refresh karo
- Check karo ke sirf real users ki stories bachi hain

---

## Method 2: Firestore Rules (Prevention) 🛡️

Future mein demo data add hone se rokne ke liye:

### firestore.rules mein add karo:

```javascript
match /stories/{storyId} {
  allow read: if true;
  allow create: if request.auth != null 
    && !request.resource.data.userName.matches('.*user[0-9]+.*')
    && !request.resource.data.userName.matches('.*demo.*')
    && !request.resource.data.userName.matches('.*test.*');
  allow update, delete: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}
```

Yeh rule ensure karega ke:
- ✅ Sirf authenticated users stories create kar sakte hain
- ❌ "user1", "user2" jaise names allowed nahi hain
- ❌ "demo" ya "test" wale names allowed nahi hain

---

## Method 3: Quick Firebase CLI (Advanced) 💻

Agar Firebase CLI installed hai:

```bash
# Login
firebase login

# Select project
firebase use your-project-id

# Open Firestore in browser
firebase firestore:delete stories --recursive
```

---

## After Cleanup Checklist ✅

Cleanup ke baad verify karo:

### 1. Story Bar Check
- [ ] App kholo
- [ ] Home page par jao
- [ ] Story bar mein sirf "Your Story" button dikhna chahiye
- [ ] user1, user2, user3, user4 nahi dikhne chahiye

### 2. Database Check
- [ ] Firebase Console kholo
- [ ] Firestore → stories collection
- [ ] Sirf real users ki stories honi chahiye

### 3. Test Story Creation
- [ ] App mein story create karo
- [ ] Check karo ke properly show ho rahi hai
- [ ] 24 hours baad auto-delete honi chahiye

---

## Current Story System Status 📊

Aapka story system **already fully functional** hai:

### ✅ Working Features:
- **Create Stories**: Camera se photo/video
- **View Stories**: Tap to navigate
- **Realtime Updates**: Firebase se live data
- **Auto-Expire**: 24 hours baad delete
- **Story Replies**: Message kar sakte hain
- **Story Highlights**: Save kar sakte hain
- **View Count**: Kitne logo ne dekha

### 🎯 What's Next:
1. Demo stories delete karo (manual ya script se)
2. Real users ko stories create karne do
3. System automatically handle karega

---

## Firebase Console Quick Links 🔗

- **Firebase Console**: https://console.firebase.google.com
- **Firestore Database**: https://console.firebase.google.com/project/YOUR_PROJECT/firestore
- **Storage**: https://console.firebase.google.com/project/YOUR_PROJECT/storage
- **Authentication**: https://console.firebase.google.com/project/YOUR_PROJECT/authentication

---

## Need Help? 💬

Agar koi confusion hai to:
1. Firebase Console screenshot share karo
2. Story bar ka screenshot share karo
3. Main exactly bata dunga kya delete karna hai

---

**Note**: Demo stories delete karne se koi real user data affect nahi hoga. Sirf test data clean hoga! ✨
