# Skynaire Social Media App

A modern, feature-rich social media application built with Flutter and Firebase.

## 🚀 Features

### ✅ Authentication
- **Google Sign In** - Seamless authentication with Google accounts
- **Email/Password Login** - Traditional login system
- **Real User Profiles** - Displays actual user names and profile pictures
- **Unique Usernames** - Auto-generated unique usernames for each user

### ✅ Professional UI/UX
- **Modern Design** - Clean, professional interface with gradient themes
- **Responsive Layout** - Works on web, mobile, and desktop
- **Smooth Animations** - Engaging user interactions
- **Glass Morphism** - Modern design elements

### ✅ Social Features
- **Post Creation** - Create posts with text, images, and categories
- **Real-time Feed** - Live updates of posts from all users
- **User Profiles** - Complete profile management
- **Professional Post Cards** - Beautiful post display with author info

### ✅ Technical Features
- **Firebase Integration** - Firestore database and Authentication
- **Real-time Updates** - Live data synchronization
- **Unique Username System** - Collision-free username generation
- **Error Handling** - Robust error management
- **State Management** - Riverpod for efficient state management

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth)
- **State Management**: Riverpod
- **UI Components**: Material Design 3
- **Authentication**: Firebase Auth + Google Sign In
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (for images)

## 📱 Supported Platforms

- ✅ Web (Chrome, Firefox, Safari, Edge)
- ✅ Android
- ✅ iOS
- ✅ Windows Desktop
- ✅ macOS Desktop
- ✅ Linux Desktop

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Dart SDK
- Firebase project setup
- Google Sign In configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/meeranxai/mygnetwork.git
   cd mygnetwork
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase**
   - Add your `google-services.json` (Android)
   - Add your `GoogleService-Info.plist` (iOS)
   - Update `web/index.html` with your Firebase config

5. **Run the app**
   ```bash
   # For web
   flutter run -d chrome --web-port=8080
   
   # For mobile (with device connected)
   flutter run
   
   # For desktop
   flutter run -d windows  # or macos/linux
   ```

## 🔥 Firebase Configuration

### Required Firebase Services
- **Authentication** (Google Sign In enabled)
- **Firestore Database**
- **Storage** (for image uploads)

### Firestore Security Rules
The app includes comprehensive security rules for:
- User profile management
- Post creation and management
- Real-time messaging
- Follow system

## 📂 Project Structure

```
lib/
├── core/
│   ├── config/          # App and Firebase configuration
│   ├── models/          # Data models (User, Post, etc.)
│   ├── providers/       # Riverpod state providers
│   ├── services/        # Firebase and API services
│   ├── router/          # Navigation routing
│   └── theme/           # App theming
├── features/
│   ├── auth/            # Authentication pages
│   ├── home/            # Home feed and widgets
│   ├── create_post/     # Post creation
│   ├── profile/         # User profiles
│   ├── messages/        # Real-time messaging
│   └── settings/        # App settings
└── main.dart           # App entry point
```

## 🎨 Key Features Implemented

### Authentication System
- Google Sign In with proper error handling
- Real user name and profile picture display
- Unique username generation with collision handling
- Fallback authentication methods

### Post System
- Professional post creation interface
- Category-based post organization
- Image upload support
- Real-time post feed
- Author information with usernames

### User Management
- Unique username system (@username format)
- Profile management
- User search functionality
- Online status tracking

## 🚀 Deployment

### Web Deployment
```bash
flutter build web --release
```

### Mobile App Build
```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Meeran Xai**
- GitHub: [@meeranxai](https://github.com/meeranxai)
- Project: G-Network Social Media Platform

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Material Design for UI guidelines
- Riverpod for state management

---

**Built with ❤️ using Flutter & Firebase**