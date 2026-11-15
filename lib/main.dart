import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer';

import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/router/router_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_model.dart';
import 'core/models/post_model.dart';
import 'core/providers/realtime_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/widgets/no_internet_overlay.dart';
import 'core/providers/security_provider.dart';
import 'core/widgets/app_lock_screen.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_service.dart';
import 'core/providers/theme_provider.dart';
// import 'core/services/collection_initializer_service.dart'; // Temporarily disabled

// Background handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('🔔 Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Print and validate configuration
    log('🔄 Validating configuration...');
    AppConfig.printConfig();

    if (!AppConfig.validateConfiguration()) {
      throw Exception(
        'Invalid configuration detected. Please check your environment variables.',
      );
    }
    log('✅ Configuration validated successfully');

    // Initialize Firebase
    log('🔄 Initializing Firebase...');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        log('✅ Firebase initialized successfully');
      } else {
        log('ℹ️ Firebase already initialized');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('duplicate') ||
          e.toString().toLowerCase().contains('already exists')) {
        log('ℹ️ Firebase already initialized (caught race condition)');
      } else {
        log('❌ Error initializing Firebase: $e');
        rethrow;
      }
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications (if applicable)

    // Disable offline persistence (Instagram/Facebook/Twitter behavior)
    log('🔄 Disabling Firestore offline persistence...');
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false, // Disable offline caching
    );
    log(
      '✅ Firestore offline persistence disabled - app requires internet connection',
    );

    // Connect to Firebase Emulators in Debug Mode if explicitly enabled
    const useEmulators = bool.fromEnvironment(
      'USE_EMULATORS',
      defaultValue: false,
    );
    if (kDebugMode && useEmulators) {
      try {
        log('🔧 Connecting to Firebase Emulators...');

        // Connect to Auth Emulator
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

        // Connect to Firestore Emulator
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

        // Connect to Storage Emulator
        await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

        log('✅ Connected to Firebase Emulators');
      } catch (e) {
        log('⚠️ Failed to connect to Firebase Emulators: $e');
      }
    } else if (kDebugMode) {
      log(
        'ℹ️ Running in Debug Mode without Emulators. Use --dart-define=USE_EMULATORS=true to enable them.',
      );
    }

    // Initialize Hive for local caching
    log('🔄 Initializing Hive...');
    await Hive.initFlutter();

    // Register Hive adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(PostModelAdapter());
    log('✅ Hive initialized successfully');

    // Initialize Supabase
    log('🔄 Initializing Supabase...');
    if (AppConfig.supabaseUrl.isNotEmpty &&
        AppConfig.supabaseAnonKey.isNotEmpty) {
      await SupabaseService.initialize(
        supabaseUrl: AppConfig.supabaseUrl,
        supabaseAnonKey: AppConfig.supabaseAnonKey,
      );
      log('✅ Supabase initialized successfully');
    } else {
      log(
        '⚠️ Supabase credentials not configured - image upload will not work',
      );
      log(
        'ℹ️ Please configure SUPABASE_URL and SUPABASE_ANON_KEY in .env.supabase',
      );
    }

    // Initialize Connectivity Service
    log('🔄 Initializing Connectivity Service...');
    await ConnectivityService().initialize();
    log('✅ Connectivity Service initialized');

    // Initialize Notification Service
    log('🔄 Initializing Notification Service...');
    await NotificationService.initialize();
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    log('✅ Notification Service initialized');

    // Initialize Firestore Collections (Temporarily disabled for production)
    log('🔄 Firestore collections will auto-create when first used');
    // try {
    //   await CollectionInitializerService.initializeCollections();
    //   log('✅ Firestore collections initialized');
    // } catch (e) {
    //   log('⚠️ Collection initialization failed: $e');
    //   // Continue app startup - collections will be created when first used
    // }

    log('🚀 Starting Skynaire App...');
    runApp(const ProviderScope(child: SkynaireApp()));
  } catch (e, stackTrace) {
    log('❌ App initialization failed: $e');
    log('Stack trace: $stackTrace');

    // Attempt to run the app anyway to avoid showing the error screen to users
    // This handles cases like "duplicate app" where the app is actually fine
    log('🚀 Launching app despite error (Best Effort)...');
    runApp(const ProviderScope(child: SkynaireApp()));
  }
}

class SkynaireApp extends ConsumerStatefulWidget {
  const SkynaireApp({super.key});

  @override
  ConsumerState<SkynaireApp> createState() => _SkynaireAppState();
}

class _SkynaireAppState extends ConsumerState<SkynaireApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize session usage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionServiceProvider).initSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockNotifier = ref.read(appLockProvider.notifier);

    if (state == AppLifecycleState.paused) {
      lockNotifier.recordPause();
      ref.read(sessionServiceProvider).updateLastActive();
    } else if (state == AppLifecycleState.resumed) {
      lockNotifier.lock();
      ref.read(sessionServiceProvider).updateLastActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final router = ref.watch(appRouterProvider);
      final lockState = ref.watch(appLockProvider);
      final themeMode = ref.watch(themeProvider);

      // Initialize real-time connection when app starts
      ref.watch(realtimeConnectionProvider);

      return MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(
                1.0,
              ), // Prevent text scaling issues
            ),
            child: Stack(
              children: [
                NoInternetOverlay(child: child!),
                if (lockState.isLocked) const AppLockScreen(),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      log('❌ App build failed: $e');
      log('Stack trace: $stackTrace');

      // Return a simple error widget
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skynaire - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Try to restart
                    main();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'If this error persists, please check:\n'
                  '• Internet connection\n'
                  '• Firebase configuration\n'
                  '• Browser console for more details',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
