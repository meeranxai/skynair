# 📱 Skynaire - Project Documentation

Welcome to the official documentation for **Skynaire**, a modern, media-centric social media platform built with Flutter.

---

## 🚀 Project Overview

**Skynaire** is a premium social media application designed for high engagement through visual storytelling. It features a streamlined "Post-Only" media architecture, focusing on high-quality images and videos while providing a familiar, intuitive user experience similar to Instagram.

### Core Philosophy
- **Visual First**: High-quality media display with a clean, distraction-free UI.
- **Unified Experience**: Simplified post-only architecture for consistency across the app.
- **Real-time Interaction**: Instant updates for likes, comments, and messaging.
- **Social Connectivity**: Seamless following, blocking, and private messaging systems.

---

## 🛠 Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod 2.0](https://riverpod.dev/) (using `StateNotifierProvider`, `StreamProvider`, and `FamilyProvider`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio) & [Http](https://pub.dev/packages/http)
- **Real-time**: [Socket.io Client](https://pub.dev/packages/socket_io_client)
- **Local Storage**: [Hive](https://pub.dev/packages/hive) & [Shared Preferences](https://pub.dev/packages/shared_preferences)

### Backend & Infrastructure
- **Authentication**: [Firebase Auth](https://firebase.google.com/docs/auth)
- **Database**: [Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Media Storage**: [Supabase Storage](https://supabase.com/storage) & [Cloudinary](https://cloudinary.com/) (Mixed/Migrated)
- **Push Notifications**: [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging)
- **Hosting**: [Railway](https://railway.app/) (for Node.js socket/API server)

---

## 📂 Project Structure

```text
lib/
├── core/               # Core utilities, services, and shared models
│   ├── config/         # App constants and environment configuration
│   ├── models/         # Data models (Post, User, Story, etc.)
│   ├── providers/      # Global state providers (Auth, Posts, Users)
│   ├── services/       # Firebase, Firestore, and API logic
│   ├── utils/          # Formatting, validators, and helpers
│   └── widgets/        # Shared UI components
├── features/           # Modular feature folders
│   ├── auth/           # Login, Signup, Password Reset
│   ├── home/           # Main feed, Story bar
│   ├── posts/          # Post creation, Detail view, Archive
│   ├── stories/        # Story creation and viewer
│   ├── explore/        # Search and discovery grid
│   ├── profile/        # User profiles and settings
│   ├── messages/       # Real-time chat system
│   ├── comments/       # Post commenting system
│   └── notifications/  # Activity notifications
└── main.dart           # Application entry point
```

---

## ✨ Key Features

### 1. Unified Media Feed
- **Instagram-Style Cards**: Professional and clean post cards with double-tap-to-like.
- **Media-Only**: Exclusively supports image and video posts for a consistent aesthetic.
- **Archive System**: Users can archive posts to hide them from the profile while keeping them saved.

### 2. Stories System
- **Ephemeral Content**: 24-hour expiring stories.
- **Story Bar**: Interactive horizontal bar on the home feed.
- **Rich Media**: Support for full-screen image and video viewing.

### 3. Advanced Profiles
- **Grid View**: Classic Instagram-style 3x3 grid for media.
- **Real-time Stats**: Instant updates for follower/following counts.
- **Privacy Controls**: Support for private profiles and follow requests.

### 4. Real-time Messaging
- **Instant Chat**: One-on-one private messaging using Socket.io.
- **Media Sharing**: Send images and text within the chat.
- **Online Status**: Real-time indicators for user activity.

### 5. Smart Search & Explore
- **Masonry Grid**: Beautifully staggered explore grid.
- **User Discovery**: Search for users by name or username.
- **Trending Filter**: Discover the latest media content.

---

## ⚙️ Configuration & Setup

### Environment Variables
The app uses `AppConfig` for environment-specific settings:
- `API_BASE_URL`: The URL for the backend socket/API server.
- `SUPABASE_URL` & `SUPABASE_ANON_KEY`: Credentials for media storage.
- `ENABLE_STORIES`, `ENABLE_MESSAGING`: Feature toggles.

### Firebase Setup
1.  Initialize Firebase in `lib/main.dart`.
2.  Enable Email/Password authentication.
3.  Set up Cloud Firestore with appropriate security rules (see `firestore.rules`).
4.  Configure FCM for notifications.

---

## 🧪 Development Workflow

### Building the App
- **Debug**: `flutter run`
- **Release APK**: `flutter build apk --release`
- **Clean Build**: `flutter clean && flutter pub get`

### Key Command References
- **Build Runner**: `flutter pub run build_runner build --delete-conflicting-outputs` (for Hive/JSON models)
- **Launcher Icons**: `flutter pub run flutter_launcher_icons`

---

## 📝 Recent Updates (2026)
- ✅ **Post-Only Transition**: Removed all legacy "Article" logic for a pure media experience.
- ✅ **UI Redesign**: Standardized post cards and redesigned the post creation flow.
- ✅ **Archive Logic**: Fixed inconsistent states and improved UI feedback for archived posts.
- ✅ **Performance**: Optimized Firestore queries for instant profile updates.

---

*Documentation maintained by Antigravity AI.*
