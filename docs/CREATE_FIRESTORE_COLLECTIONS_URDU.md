# 📦 Firestore Collections Manually Create Karna

## 🎯 Collections Jo Chahiye

Follow button ke liye 2 collections chahiye:
1. **follows** - Follow/unfollow data
2. **blocks** - Block/unblock data

## 📝 Step-by-Step Guide

### Step 1: Firebase Console Open Karein

1. Browser mein jao: https://console.firebase.google.com
2. Apna project select karein: **g-network-community**
3. Left sidebar mein **Firestore Database** click karein

### Step 2: "follows" Collection Create Karein

#### A. Collection Banao
1. **Start collection** button click karein
2. Collection ID: `follows`
3. **Next** click karein

#### B. Pehla Document Add Karein
```
Document ID: (Auto-ID ya manual)

Fields:
- followerId: string = "your_user_id"
- followingId: string = "other_user_id"
- createdAt: timestamp = (current time)
```

**Example**:
```
Document ID: user1_user2

Fields:
followerId: "abc123"
followingId: "xyz789"
createdAt: January 11, 2026 at 10:00:00 AM UTC+5
```

#### C. Save Karein
- **Save** button click karein
- Collection create ho jayega!

### Step 3: "blocks" Collection Create Karein

#### A. Collection Banao
1. **Start collection** button click karein (ya + icon)
2. Collection ID: `blocks`
3. **Next** click karein

#### B. Pehla Document Add Karein
```
Document ID: (Auto-ID ya manual)

Fields:
- blockerId: string = "your_user_id"
- blockedId: string = "blocked_user_id"
- createdAt: timestamp = (current time)
```

**Example**:
```
Document ID: user1_user3

Fields:
blockerId: "abc123"
blockedId: "def456"
createdAt: January 11, 2026 at 10:00:00 AM UTC+5
```

#### C. Save Karein
- **Save** button click karein
- Collection create ho jayega!

## ✅ Verification

### Check Karein Collections Exist Karte Hain:

1. Firebase Console > Firestore Database
2. Left panel mein dekhein:
   - ✅ `follows` collection
   - ✅ `blocks` collection

### Test Document Delete Kar Sakte Hain:

Agar aapne test documents banaye the:
1. Document par click karein
2. Three dots (...) > **Delete document**
3. Confirm karein

**Note**: Collections empty bhi rakh sakte hain, bas exist karna chahiye!

## 🔧 Alternative: Empty Collections

Agar aap empty collections rakhna chahte hain:

### Option 1: Dummy Document (Recommended)
```
Collection: follows
Document ID: _placeholder

Fields:
dummy: boolean = true
```

Yeh document bas collection ko exist karane ke liye hai.

### Option 2: App Se Pehla Action
- Kisi ko follow karo
- Collection automatically create ho jayega
- Document automatically add ho jayega

## 📋 Collection Structure Reference

### follows Collection
```javascript
{
  "followerId": "user_id_who_follows",
  "followingId": "user_id_being_followed",
  "createdAt": Timestamp
}
```

**Document ID Format**: `{followerId}_{followingId}`
**Example**: `abc123_xyz789`

### blocks Collection
```javascript
{
  "blockerId": "user_id_who_blocks",
  "blockedId": "user_id_being_blocked",
  "createdAt": Timestamp
}
```

**Document ID Format**: `{blockerId}_{blockedId}`
**Example**: `abc123_def456`

## 🎯 Quick Steps Summary

1. **Firebase Console** > **Firestore Database**
2. **Start collection** > `follows` > Add dummy document > **Save**
3. **Start collection** > `blocks` > Add dummy document > **Save**
4. **Verify** both collections exist
5. **App restart** karein (Hot restart: R)
6. **Test** follow button

## ⚠️ Important Notes

1. **Collection Names**: Exactly `follows` aur `blocks` hone chahiye (lowercase)
2. **Document Structure**: Fields sahi hone chahiye
3. **Permissions**: Firestore rules already set hain
4. **Empty OK**: Collections empty bhi rakh sakte hain

## 🚀 After Creating Collections

### Step 1: App Restart
```bash
# Console mein
R
```

### Step 2: Test Follow Button
1. Kisi user ke profile par jao
2. Follow button ab properly dikhna chahiye
3. Click karo
4. Follow action work karna chahiye

### Step 3: Check Data
1. Firebase Console > Firestore
2. `follows` collection check karein
3. New document add hona chahiye

## 🔍 Troubleshooting

### Issue: Collection Create Nahi Ho Raha
**Solution**: 
- Firestore Database enabled hai?
- Billing enabled hai? (Spark plan free hai)
- Permissions check karein

### Issue: Document Save Nahi Ho Raha
**Solution**:
- Field types sahi hain?
- Timestamp field properly set hai?
- Try Auto-ID instead of manual ID

### Issue: Follow Button Abhi Bhi Gray
**Solution**:
1. Collections create kiye?
2. App restart kiya?
3. Console logs check karein
4. Firestore rules deploy kiye?

## ✅ Success Checklist

- [ ] Firebase Console open kiya
- [ ] `follows` collection create kiya
- [ ] `blocks` collection create kiya
- [ ] Collections verify kiye
- [ ] App restart kiya (R)
- [ ] Follow button test kiya
- [ ] Follow action work kar raha hai

## 🎉 Done!

Collections create hone ke baad follow button properly kaam karega! 🚀
