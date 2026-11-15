class AppConfig {
  static const String appName = 'Skynaire';
  static const String appVersion = '1.0.0';

  // Environment detection
  static bool get isProduction =>
      const bool.fromEnvironment('dart.vm.product', defaultValue: false);

  static bool get isDevelopment => !isProduction;

  // API Configuration - Environment-based
  static String get baseUrl {
    if (isProduction) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://mySkynaire-production.up.railway.app',
      );
    } else {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      );
    }
  }

  static String get socketUrl {
    if (isProduction) {
      return const String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: 'https://mySkynaire-production.up.railway.app',
      );
    } else {
      return const String.fromEnvironment(
        'SOCKET_URL',
        defaultValue: 'http://localhost:5000',
      );
    }
  }

  // Firebase Configuration
  static const String firebaseProjectId = 'studio-2145172646-5b4a0';

  // Supabase Configuration - Use environment variables
  static String get supabaseUrl {
    return const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://rniqhvmtezowdbabhogz.supabase.co',
    );
  }

  static String get supabaseAnonKey {
    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuaXFodm10ZXpvd2RiYWJob2d6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNjg4MDQsImV4cCI6MjA4Mjk0NDgwNH0.aqsGQ_SUU_cL-_gOQqQNV3p6tYW8D8IGe24O6TmJPRg',
    );
  }

  static String get supabaseStorageBucket {
    return const String.fromEnvironment(
      'SUPABASE_STORAGE_BUCKET',
      defaultValue: 'images',
    );
  }

  // App Constants
  static const int postsPerPage = 10;
  static const int maxImageSize = 8 * 1024 * 1024; // 8MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const Duration socketTimeout = Duration(seconds: 20);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 15);

  // Feature Flags - Can be controlled via environment
  static bool get enableAI =>
      const bool.fromEnvironment('ENABLE_AI', defaultValue: true);
  static bool get enableReels =>
      const bool.fromEnvironment('ENABLE_REELS', defaultValue: true);
  static bool get enableStories =>
      const bool.fromEnvironment('ENABLE_STORIES', defaultValue: true);
  static bool get enableMessaging =>
      const bool.fromEnvironment('ENABLE_MESSAGING', defaultValue: true);
  static bool get enableNotifications =>
      const bool.fromEnvironment('ENABLE_NOTIFICATIONS', defaultValue: true);

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double maxContentWidth = 600.0;

  // Validation Constants
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 25;
  static const int maxBioLength = 150;
  static const int maxPostTitleLength = 100;
  static const int maxPostDescriptionLength = 2000;

  // Cache Constants
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Network Constants
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Debug helpers
  static void printConfig() {
    if (isDevelopment) {
      // Use log instead of print for better debugging
      final config =
          '''
=== App Configuration ===
Environment: ${isProduction ? 'Production' : 'Development'}
Base URL: $baseUrl
Socket URL: $socketUrl
Supabase URL: ${supabaseUrl.isNotEmpty ? supabaseUrl : 'Not configured'}
Supabase Bucket: $supabaseStorageBucket
Features: AI=$enableAI, Reels=$enableReels, Stories=$enableStories
========================''';

      // This will be optimized out in production builds
      assert(() {
        // ignore: avoid_print
        print(config);
        return true;
      }());
    }
  }

  // Validation helpers
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static bool validateConfiguration() {
    final issues = <String>[];

    if (!isValidUrl(baseUrl)) {
      issues.add('Invalid base URL: $baseUrl');
    }

    if (!isValidUrl(socketUrl)) {
      issues.add('Invalid socket URL: $socketUrl');
    }

    // Supabase validation - only warn, don't fail
    if (supabaseUrl.isEmpty) {
      assert(() {
        // ignore: avoid_print
        print('⚠️ Supabase URL is empty - image upload will not work');
        return true;
      }());
    } else if (!isValidUrl(supabaseUrl)) {
      issues.add('Invalid Supabase URL: $supabaseUrl');
    }

    if (supabaseAnonKey.isEmpty) {
      assert(() {
        // ignore: avoid_print
        print('⚠️ Supabase anon key is empty - image upload will not work');
        // ignore: avoid_print
        print(
          'ℹ️ Get your key from: https://app.supabase.com → Settings → API',
        );
        return true;
      }());
    }

    if (issues.isNotEmpty) {
      // Use assert for debug-only logging
      assert(() {
        // ignore: avoid_print
        print('❌ Configuration Issues:');
        for (final issue in issues) {
          // ignore: avoid_print
          print('  - $issue');
        }
        return true;
      }());
      return false;
    }

    return true;
  }
}
