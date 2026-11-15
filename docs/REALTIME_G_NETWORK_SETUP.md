# Real-time G-Network Setup Guide

## 🚀 Complete JWT + Socket.IO Real-time Social Network

This guide will help you set up the complete real-time G-Network application with JWT authentication and Socket.IO integration.

## 📋 Prerequisites

- Node.js (v16 or higher)
- MongoDB (local or cloud)
- Flutter SDK (latest stable)
- Android Studio / VS Code

## 🔧 Backend Setup

### 1. Install Dependencies

Navigate to the backend directory and install dependencies:

```bash
cd G-Network/backend
npm install bcryptjs jsonwebtoken
```

### 2. Environment Variables

Create a `.env` file in the backend directory:

```env
# Database
MONGODB_URI=mongodb://localhost:27017/g-network
# or for MongoDB Atlas:
# MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/g-network

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here-make-it-long-and-random
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=5000
NODE_ENV=development

# CORS Configuration
FRONTEND_URL=http://localhost:5173
CORS_ORIGIN=http://localhost:5173

# Optional: Firebase (for migration compatibility)
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

### 3. Start Backend Server

```bash
cd G-Network/backend
npm run dev
```

The server should start on `http://localhost:5000`

## 📱 Flutter Setup

### 1. Install Dependencies

Navigate to the Flutter app directory:

```bash
cd social_media_app
flutter pub get
```

### 2. Update App Configuration

The app is already configured to use JWT authentication. Make sure your backend URL is correct in `lib/core/config/app_config.dart`:

```dart
static const String baseUrl = 'http://localhost:5000'; // Development
static const String socketUrl = 'http://localhost:5000';
```

For Android emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
static const String socketUrl = 'http://10.0.2.2:5000';
```

### 3. Run the Flutter App

```bash
flutter run
```

## 🔐 Authentication Flow

### Registration
1. User registers with email, password, display name, and username
2. Backend validates input and creates user with hashed password
3. JWT token is generated and returned
4. Token is stored securely on device
5. Socket connection is established with JWT authentication

### Login
1. User logs in with email and password
2. Backend validates credentials
3. JWT token is generated and returned
4. User status is updated to online
5. Socket connection is established
6. Real-time features are activated

### Real-time Features
- **Online Users**: See who's currently online
- **Live Posts**: New posts appear instantly
- **Real-time Notifications**: Get notified of new activities
- **Live Messaging**: Instant messaging with typing indicators
- **Presence Updates**: See when users come online/offline

## 🌐 Socket.IO Events

### Client → Server Events
- `new_post`: Broadcast new post to all users
- `like_post`: Broadcast post like to all users
- `send_message`: Send message to specific chat
- `typing`: Send typing indicator
- `user_activity_update`: Update user activity status
- `join_chat`: Join a chat room
- `mark_messages_read`: Mark messages as read

### Server → Client Events
- `user_online`: User came online
- `user_offline`: User went offline
- `online_users_list`: List of currently online users
- `new_post`: New post was created
- `post_liked`: Post was liked
- `receive_message`: New message received
- `display_typing`: Typing indicator
- `notification`: New notification

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update user profile
- `GET /api/auth/online-users` - Get online users

### Posts (existing)
- `GET /api/posts` - Get posts
- `POST /api/posts` - Create post
- `PUT /api/posts/:id/like` - Like post
- `DELETE /api/posts/:id` - Delete post

## 🚀 Testing the Real-time Features

### 1. Test Authentication
1. Register a new account
2. Login with credentials
3. Check that JWT token is stored
4. Verify socket connection is established

### 2. Test Real-time Posts
1. Open app on multiple devices/browsers
2. Create a post on one device
3. Verify it appears instantly on other devices

### 3. Test Online Users
1. Login on multiple devices
2. Check online users list updates in real-time
3. Logout from one device and verify status updates

### 4. Test Messaging
1. Start a chat between two users
2. Send messages and verify real-time delivery
3. Test typing indicators

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt with salt rounds
- **Socket Authentication**: JWT verification for socket connections
- **Input Validation**: Server-side validation for all inputs
- **CORS Protection**: Configured CORS for security
- **Rate Limiting**: API rate limiting to prevent abuse

## 🐛 Troubleshooting

### Backend Issues
- **MongoDB Connection**: Ensure MongoDB is running
- **Port Conflicts**: Change PORT in .env if 5000 is occupied
- **JWT Errors**: Verify JWT_SECRET is set in .env

### Flutter Issues
- **Network Errors**: Check backend URL configuration
- **Socket Connection**: Verify backend is running and accessible
- **Authentication**: Clear app data if having login issues

### Common Solutions
```bash
# Clear Flutter cache
flutter clean
flutter pub get

# Restart backend
cd G-Network/backend
npm run dev

# Check backend health
curl http://localhost:5000/health
```

## 📊 Architecture Overview

```
┌─────────────────┐    JWT Auth     ┌─────────────────┐
│   Flutter App   │ ←──────────────→ │  Node.js API    │
│                 │                 │                 │
│ • JWT Storage   │    Socket.IO    │ • JWT Verify    │
│ • Real-time UI  │ ←──────────────→ │ • Real-time     │
│ • State Mgmt    │                 │ • Broadcasting  │
└─────────────────┘                 └─────────────────┘
                                            │
                                            ▼
                                    ┌─────────────────┐
                                    │    MongoDB      │
                                    │                 │
                                    │ • Users         │
                                    │ • Posts         │
                                    │ • Messages      │
                                    └─────────────────┘
```

## 🎯 Key Features Implemented

✅ **JWT Authentication System**
- Registration and login
- Secure token storage
- Auto-refresh and logout

✅ **Real-time Socket.IO Integration**
- JWT-based socket authentication
- Online user tracking
- Live post broadcasting

✅ **Clean Architecture**
- Provider-based state management
- Service layer separation
- Proper error handling

✅ **Security Best Practices**
- Password hashing
- Input validation
- CORS protection
- Rate limiting

✅ **User Experience**
- Real-time notifications
- Online status indicators
- Smooth animations
- Error handling

## 🚀 Next Steps

1. **Deploy Backend**: Deploy to Railway, Render, or Heroku
2. **Build APK**: Create production Flutter build
3. **Add Features**: Implement additional real-time features
4. **Performance**: Optimize for production use
5. **Testing**: Add comprehensive tests

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section
2. Verify all environment variables are set
3. Ensure MongoDB and backend are running
4. Check Flutter dependencies are installed

The app is now ready for real-time social networking with JWT authentication and Socket.IO integration!