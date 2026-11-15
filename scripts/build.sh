#!/bin/bash

# Build script for G-Network Social Media App
# This script replaces environment variables in templates and builds the app

echo "🔧 Starting G-Network build process..."

# Set default values if environment variables are not set
FIREBASE_API_KEY=${FIREBASE_API_KEY:-"AIzaSyD8cfRISFxmMM63ajzAVNmN7QpF70xYRSI"}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-"studio-2145172646-5b4a0.firebaseapp.com"}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-"studio-2145172646-5b4a0"}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-"studio-2145172646-5b4a0.firebasestorage.app"}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-"951845646390"}
FIREBASE_APP_ID=${FIREBASE_APP_ID:-"1:951845646390:web:c16b39f0a39a1c9e20e897"}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-"358032029950-dd16pt5sf8r0u0cen0b9g891pkjfkacn.apps.googleusercontent.com"}

echo "✅ Using Firebase Project: $FIREBASE_PROJECT_ID"

# Replace placeholders in web/index.html
echo "🔄 Configuring Firebase settings..."

# Create index.html from template if template exists
if [ -f "web/index.html.template" ]; then
    cp web/index.html.template web/index.html
fi

# Replace placeholders with actual values
sed -i "s/FIREBASE_API_KEY_PLACEHOLDER/$FIREBASE_API_KEY/g" web/index.html
sed -i "s/FIREBASE_AUTH_DOMAIN_PLACEHOLDER/$FIREBASE_AUTH_DOMAIN/g" web/index.html
sed -i "s/FIREBASE_PROJECT_ID_PLACEHOLDER/$FIREBASE_PROJECT_ID/g" web/index.html
sed -i "s/FIREBASE_STORAGE_BUCKET_PLACEHOLDER/$FIREBASE_STORAGE_BUCKET/g" web/index.html
sed -i "s/FIREBASE_MESSAGING_SENDER_ID_PLACEHOLDER/$FIREBASE_MESSAGING_SENDER_ID/g" web/index.html
sed -i "s/FIREBASE_APP_ID_PLACEHOLDER/$FIREBASE_APP_ID/g" web/index.html
sed -i "s/GOOGLE_CLIENT_ID_PLACEHOLDER/$GOOGLE_CLIENT_ID/g" web/index.html

echo "✅ Firebase configuration updated"

# Replace in auth service
echo "🔄 Configuring Google Sign In..."
sed -i "s/GOOGLE_CLIENT_ID_PLACEHOLDER/$GOOGLE_CLIENT_ID/g" lib/core/services/auth_service.dart

echo "✅ Google Sign In configuration updated"

# Get Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Generate code
echo "🔨 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build web app
echo "🚀 Building Flutter web app..."
flutter build web --release

echo "🎉 Build completed successfully!"
echo "📁 Output: build/web/"