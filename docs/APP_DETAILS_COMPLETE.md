# 📱 Skynaire App - Comprehensive Documentation

Yeh file Skynaire app (formerly G-Network) ki mukammal details provide karti hai, jis mein iska architecture, features, aur technical stack shamil hain.

---

## 🌟 1. Project Overview
**Skynaire** ek modern social media application hai jo Flutter framework par banayi gayi hai. Iska maqsad users ko ek premium, fast, aur interactive social experience dena hai.

- **Primary Platform:** Android, iOS, Web, Windows
- **Current Status:** Phase 1 Complete (Articles & Social Core)
- **Design Philosophy:** Glassmorphism, Material 3, Dark/Light Mode support.

---

## 🛠️ 2. Technical Stack (Tech Stack)

| Category | Technology |
|----------|------------|
| **Frontend Framework** | Flutter 3.10+ (Dart) |
| **State Management** | Riverpod 2.6+ |
| **Backend / Auth** | Firebase (Auth, Firestore, Storage) |
| **Database** | Cloud Firestore (NoSQL) |
| **Media Handling** | Cloudinary (Current) / Supabase (Migration) |
| **Navigation** | GoRouter |
| **Local Storage** | Hive (Caching), Shared Preferences |
| **Real-time** | Socket.io / Firebase Streams |

---

## 📁 3. Project Structure (Architecture)
App **Feature-based architecture** follow karti hai taake scalability aur maintenance asaan ho.

### 📂 `lib/core/` (Core Operations)
- **config/**: App settings aur Firebase configurations.
- **models/**: Global data structures (User, Post, Comment).
- **providers/**: App-wide state management scripts.
- **services/**: Firebase interactions aur API calls logic.
- **theme/**: Visual tokens, colors, aur typography.
- **router/**: Navigation routes (Home, Profile, Auth, etc.).
- **utils/**: Helpers, formatters, aur validators.

### 📂 `lib/features/` (Main Modules)
1. **auth/**: Login, Registration (Email & Google), Forgot Password.
2. **home/**: Main feed gallery, activity feed (Like/Comment logic).
3. **articles/**: Professional article writing and reading interface.
4. **posts/**: Media-based social posts.
5. **profile/**: User profile management, personalized feeds, @usernames.
6. **explore/**: Search functionality aur discovery page.
7. **messages/**: Real-time chat system (UI & Logic).
8. **stories/**: Short-term status updates with cropping features.
9. **notifications/**: User activity alerts.
10. **settings/**: Branding settings, about section, account management.

---

## ✨ 4. Key Features (Main Khoobiyan)

### 🔐 Authentication System
- **Google Sign-In:** Multi-platform support ke sath.
- **Email/Password:** Traditional login system.
- **Username Guard:** Har user ke liye auto-generated unique @username.
- **Session Management:** Secure login state persisting.

### 📝 Content Creation
- **Article System:** Markdown support ke sath professional long-form content.
- **Post System:** Photos aur captions share karne ka platform.
- **Categories:** Content ko categories mein divide karne ki sahulat.
- **Content Guard:** Automated moderation taake vulgar content platform par na aaye.

### 🤝 Social Interactions
- **Follow/Unfollow:** Real-time following system.
- **Interaction Engine:** Likes, Comments, aur Shares (Real-time updates).
- **Real-time Messaging:** Chat functionality (Phase-wise enablement).

### 🎨 UI & UX
- **Glassmorphism:** Modern translucent UI elements.
- **Responsive Design:** Mobile aur Desktop dono ke liye optimize.
- **Theme Support:** Dynamic Dark aur Light mode switching.

---

## 🚀 5. Deployment & Maintenance

### Build Commands
- **Android APK:** `flutter build apk --release` (Use `build_new_apk.bat` for automation)
- **Web:** `flutter build web --release`
- **Windows:** `flutter build windows --release`

### Automation Scripts
- **`build_new_apk.bat`**: Automatic cleansing aur fresh APK build.
- **`deploy_firestore_rules.bat`**: Firestore security rules update karna.
- **`fix_all_firebase_issues.bat`**: Firebase integration errors solve karna.

---

## 🔮 6. Future Roadmap (Future Plans)
1. **AI Integration:** AI-based feed recommendation system.
2. **Advanced Messaging:** Voice notes aur group chats.
3. **Monetization:** Creators ke liye subscription models.
4. **Enhanced Stories:** Video stories aur filters support.

---

## 🇵🇰 Summary in Urdu
Yeh app ek complete social media solution hai jo **Flutter** aur **Firebase** par mabni hai. Is mein features jaise ke authentication, post creation, profile management, aur real-time updates shamil hain. App ka interface bohot modern hai aur yeh tamaam platforms (Android, iOS, Web) par chalti hai. Haliya rebranding ke baad iska naam **Skynaire** rakha gaya hai jo ke ek premium brand identity ko show karta hai.

---
*Documentation Created on: 2026-03-19*
*Developer: Rajput com / Team Skynaire*
