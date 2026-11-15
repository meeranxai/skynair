# Firestore Indexes - دستی طریقہ

## 7 Indexes جو بنانے ہیں

---

## Index 1: Notifications - Unread Filter

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `toUserId` - Ascending
2. `isRead` - Ascending

**استعمال:** Unread notifications دیکھنے کے لیے

---

## Index 2: Notifications - Type Filter

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `type` - Ascending
2. `fromUserId` - Ascending
3. `toUserId` - Ascending

**استعمال:** Notification type کے مطابق filter کرنے کے لیے

---

## Index 3: Notifications - Post Specific

**Collection ID:** `notifications`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `type` - Ascending
2. `fromUserId` - Ascending
3. `toUserId` - Ascending
4. `postId` - Ascending

**استعمال:** کسی خاص post کی notifications کے لیے

---

## Index 4: Comments - Replies (جوابات)

**Collection ID:** `comments`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `parentCommentId` - Ascending
2. `createdAt` - Ascending

**استعمال:** Comment replies (nested comments) کے لیے

---

## Index 5: Comments - User History

**Collection ID:** `comments`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `authorId` - Ascending
2. `createdAt` - Descending

**استعمال:** User کی تمام comments دیکھنے کے لیے

---

## Index 6: Stories - Highlights

**Collection ID:** `stories`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `userId` - Ascending
2. `isHighlight` - Ascending
3. `createdAt` - Descending

**استعمال:** Story highlights feature کے لیے

---

## Index 7: Stories - Expiry

**Collection ID:** `stories`  
**Query Scope:** Collection

**Fields (فیلڈز):**
1. `expiresAt` - Ascending
2. `createdAt` - Descending

**استعمال:** Expired stories cleanup کے لیے

---

## کیسے بنائیں؟ (قدم بہ قدم)

### قدم 1: Firebase Console کھولیں

```
https://console.firebase.google.com/
```

اپنا project منتخب کریں

### قدم 2: Firestore Indexes پر جائیں

1. بائیں طرف "Firestore Database" پر کلک کریں
2. اوپر "Indexes" tab پر کلک کریں

### قدم 3: نیا Index بنائیں

1. "Create Index" button دبائیں
2. یہ معلومات بھریں:

**Index 1 کے لیے:**
- Collection ID: `notifications` لکھیں
- Query scope: "Collection" منتخب کریں
- "Add field" دبائیں
  - Field path: `toUserId` لکھیں
  - Order: "Ascending" منتخب کریں
- پھر "Add field" دبائیں
  - Field path: `isRead` لکھیں
  - Order: "Ascending" منتخب کریں
- "Create" button دبائیں

### قدم 4: باقی 6 Indexes بھی ایسے ہی بنائیں

ہر index کے لیے اوپر دی گئی تفصیلات استعمال کریں

### قدم 5: انتظار کریں

- ہر index بننے میں 5-10 منٹ لگتے ہیں
- Status "Building" سے "Enabled" ہو جائے گا

---

## فوری نقل (Copy-Paste)

### Index 1
```
Collection: notifications
Field 1: toUserId (Ascending)
Field 2: isRead (Ascending)
```

### Index 2
```
Collection: notifications
Field 1: type (Ascending)
Field 2: fromUserId (Ascending)
Field 3: toUserId (Ascending)
```

### Index 3
```
Collection: notifications
Field 1: type (Ascending)
Field 2: fromUserId (Ascending)
Field 3: toUserId (Ascending)
Field 4: postId (Ascending)
```

### Index 4
```
Collection: comments
Field 1: parentCommentId (Ascending)
Field 2: createdAt (Ascending)
```

### Index 5
```
Collection: comments
Field 1: authorId (Ascending)
Field 2: createdAt (Descending)
```

### Index 6
```
Collection: stories
Field 1: userId (Ascending)
Field 2: isHighlight (Ascending)
Field 3: createdAt (Descending)
```

### Index 7
```
Collection: stories
Field 1: expiresAt (Ascending)
Field 2: createdAt (Descending)
```

---

## ترجیحی ترتیب

### پہلے یہ بنائیں (اہم):
1. ✅ Index 1 - Unread notifications
2. ✅ Index 4 - Comment replies

### پھر یہ بنائیں:
3. ✅ Index 2 - Notification type
4. ✅ Index 6 - Story highlights

### اختیاری (بعد میں):
5. ⚠️ Index 3 - Notification with post
6. ⚠️ Index 5 - User comments
7. ⚠️ Index 7 - Story expiry

---

## آسان طریقہ (خودکار)

دستی طریقے کی بجائے، یہ command استعمال کریں:

```bash
firebase deploy --only firestore:indexes
```

یہ تمام 7 indexes خودکار طور پر بنا دے گا!

---

## تصدیق کریں

ہر index بنانے کے بعد:

1. Firebase Console میں status چیک کریں
2. "Enabled" ہونے تک انتظار کریں
3. App میں feature test کریں

---

## وقت کا تخمینہ

**دستی طریقہ:**
- ہر index: 5-10 منٹ
- کل وقت: ~1 گھنٹہ

**خودکار طریقہ:**
- Command چلانا: 1 منٹ
- Indexes بننا: 10-15 منٹ
- کل وقت: ~15 منٹ

---

## تجویز

**بہترین طریقہ:** خودکار command استعمال کریں! 🚀

```bash
firebase deploy --only firestore:indexes
```

یا

```bash
deploy_indexes.bat
```

یہ تیز اور آسان ہے!

---

## خلاصہ

**کل Indexes:** 7  
**طریقہ 1:** دستی (1 گھنٹہ)  
**طریقہ 2:** خودکار (15 منٹ) ✅ تجویز کردہ

اگر دستی طریقہ استعمال کر رہے ہیں تو اوپر دی گئی تفصیلات استعمال کریں!
