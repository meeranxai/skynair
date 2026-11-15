# Content Moderation System - Urdu Guide 🛡️

## Kya Hai Yeh System?

Yeh ek **Automated Content Moderation System** hai jo aapki social media app mein **real-time** content ko check karta hai aur **restricted words** ko detect karta hai.

## Main Features

### 1. Real-time Detection ⚡
Jab user article ya post likh raha ho, toh **turant** check hota hai ke koi forbidden word toh nahi use ho raha.

### 2. Warning System ⚠️
Agar koi restricted word mil jaye, toh:
- **Inline Warning** dikhta hai text field ke neeche
- **Publish Button** disable ho jata hai
- **Detailed Dialog** dikhta hai jab user publish karne ki koshish kare

### 3. Server-side Protection 🔒
Sirf client-side check nahi, **Supabase Edge Function** bhi check karta hai taake koi bypass na kar sake.

### 4. Strike System 📊
- **1-2 Strikes**: Warning
- **3-4 Strikes**: Restricted posting
- **5+ Strikes**: Account suspended

## Kaise Use Karein?

### Step 1: Database Setup

Supabase SQL Editor mein yeh query run karein:

```sql
-- File: supabase/migrations/20260107_moderation_system.sql
-- Copy paste karein poori file
```

### Step 2: Edge Function Deploy

```bash
# Supabase CLI install karein
npm install -g supabase

# Login karein
supabase login

# Project link karein
supabase link --project-ref YOUR_PROJECT_REF

# Function deploy karein
supabase functions deploy moderate-content
```

### Step 3: Flutter App Mein Use Karein

**Create Post Page** mein normal TextField ki jagah **ModeratedTextField** use karein:

```dart
import '../../../core/widgets/moderated_text_field.dart';

// Title field
ModeratedTextField(
  controller: _titleController,
  labelText: 'Title',
  hintText: 'Article ka title likhein...',
  maxLines: 2,
  showInlineWarning: true,
  onModerationChange: (result) {
    // Check karo content clean hai ya nahi
    setState(() {
      _canPublish = result.isClean;
    });
  },
)

// Description field
ModeratedTextField(
  controller: _descriptionController,
  labelText: 'Description',
  hintText: 'Apna article likhein...',
  maxLines: 10,
  showInlineWarning: true,
  showCharacterCount: true,
)

// Publish button
ElevatedButton(
  onPressed: _canPublish ? _publishPost : null,
  child: Text(_canPublish ? 'Publish' : 'Violations Fix Karein'),
)
```

## Restricted Keywords

### 1. Scams & Fraud 💰
```
free money, paisa double, investment scam
get rich quick, easy money, ghar baithe kamao
lottery winner, prize money, instant loan
```

### 2. Platform Integrity 🚫
```
follow for follow, f4f, buy followers
buy likes, fake followers, followers kharido
engagement pod, spam, bot followers
```

### 3. Hate Speech 😡
```
hate, kill, terrorist, bomb, attack
violence, abuse, harass, bully, threat
```

### 4. Adult Content 🔞
```
porn, xxx, adult content, explicit
nsfw, 18+, sex, nude
```

### 5. Misinformation 📰
```
fake news, conspiracy, hoax
false information, jhooti khabar, galat khabar
```

### 6. Personal Information 🔐
```
phone number, email address, home address
credit card, password, bank account number
aadhar number, cnic number
```

## Warning Messages

### Medium Severity (Yellow)
```
⚠️ Warning: Inhe hatayein warna publish nahi kar sakte.
```

### High Severity (Orange)
```
⚠️ High Risk: Multiple violations se account restrict hoga.
```

### Severe Severity (Red)
```
⚠️ Severe Violation: Aapka account immediately suspend ho sakta hai.
```

## User Flow

```
1. User article likhna shuru karta hai
   ↓
2. Real-time check hota hai har keystroke pe
   ↓
3. Agar restricted word detect ho:
   - Inline warning dikhta hai
   - Publish button disable ho jata hai
   ↓
4. User word hatata hai
   ↓
5. Warning gayab ho jata hai
   ↓
6. Publish button enable ho jata hai
   ↓
7. User publish karta hai
   ↓
8. Server-side validation hota hai
   ↓
9. Agar clean hai toh post create hota hai
   ↓
10. Agar violation hai toh:
    - Strike add hota hai
    - Log create hota hai
    - Error message dikhta hai
```

## Strike System Details

### Kaise Strikes Milte Hain?

| Severity | Strikes | Example |
|----------|---------|---------|
| Medium | 0 | Platform integrity |
| High | 1 | Scams, misinformation |
| Severe | 2 | Hate speech, adult content |

### Kya Hota Hai Strikes Pe?

**1-2 Strikes:**
- Warning message
- Normal posting allowed
- Monitoring shuru

**3-4 Strikes:**
- Restricted posting
- Limited features
- Admin review

**5+ Strikes:**
- Account suspended
- Cannot create posts
- Can only view content
- Admin approval required

### Strikes Kaise Check Karein?

Supabase SQL Editor mein:

```sql
-- Apne strikes check karein
SELECT moderation_strikes, is_suspended 
FROM users 
WHERE uid = 'YOUR_USER_ID';

-- Apni violations dekhen
SELECT * FROM moderation_logs 
WHERE user_id = 'YOUR_USER_ID' 
ORDER BY created_at DESC;
```

## Admin Dashboard

### Violations Dekhein

```sql
-- Sab violations
SELECT * FROM moderation_dashboard;

-- Top violators
SELECT * FROM moderation_dashboard 
ORDER BY moderation_strikes DESC 
LIMIT 10;

-- Recent violations
SELECT * FROM moderation_logs 
WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

### User Unsuspend Karein

```sql
UPDATE users 
SET is_suspended = FALSE,
    moderation_strikes = 0,
    suspended_at = NULL,
    suspension_reason = NULL
WHERE uid = 'USER_ID';
```

## Testing Kaise Karein?

### Test Case 1: Clean Content ✅
```
Input: "Yeh ek behtareen article hai technology ke baare mein"
Expected: Koi warning nahi, publish kar sakte hain
```

### Test Case 2: Scam Detection ❌
```
Input: "Free money! Paisa double karo abhi!"
Expected: Warning dikhega, publish nahi kar sakte
```

### Test Case 3: Platform Integrity ❌
```
Input: "Follow for follow! Followers kharido yahan se"
Expected: Warning dikhega, publish nahi kar sakte
```

### Test Case 4: Multiple Violations ❌
```
Input: "Free money! Follow for follow! Buy likes!"
Expected: Multiple warnings, severe alert
```

## Customization

### Naye Keywords Add Karein

**File 1:** `lib/core/services/content_moderation_service.dart`

```dart
static const Map<String, List<String>> _restrictedKeywords = {
  'your_category': [
    'keyword1',
    'keyword2',
    'keyword3',
  ],
};
```

**File 2:** `supabase/functions/moderate-content/index.ts`

```typescript
const RESTRICTED_KEYWORDS = {
  your_category: [
    'keyword1',
    'keyword2',
    'keyword3',
  ],
}
```

### Strike Threshold Change Karein

```typescript
// Edge Function mein
if (newStrikes >= 5) { // Yeh number change karein
  // Auto-suspend
}
```

## Common Issues

### Issue 1: Keywords Detect Nahi Ho Rahe

**Solution:** 
- Check karein spelling sahi hai
- Word boundaries check karein
- Case-insensitive hai toh lowercase mein add karein

### Issue 2: Edge Function Kaam Nahi Kar Raha

**Solution:**
```bash
# Logs check karein
supabase functions logs moderate-content

# Redeploy karein
supabase functions deploy moderate-content
```

### Issue 3: Strikes Apply Nahi Ho Rahe

**Solution:**
- Database permissions check karein
- RLS policies verify karein
- User ID sahi hai check karein

## Best Practices

1. **Regular Updates**: Keywords list ko regularly update karein
2. **False Positives**: Agar koi word galti se detect ho raha hai, toh regex improve karein
3. **User Feedback**: Users ko appeal system dein
4. **Admin Review**: High strikes wale users ko manually review karein
5. **Transparency**: Users ko clear batayein ke kya allowed hai aur kya nahi

## Future Improvements

- [ ] AI-based detection (OpenAI Moderation API)
- [ ] Image content moderation
- [ ] Appeal system
- [ ] Context-aware detection
- [ ] Multi-language NLP
- [ ] User reputation score

---

**Status:** ✅ Complete aur Production Ready
**Support:** Koi issue ho toh documentation check karein ya admin se contact karein
