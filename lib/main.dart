import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'firebase_options.dart';
import 'screens/main_app_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_main_screen.dart' as admin_screen;
import 'providers/auth_provider.dart';
import 'providers/sermon_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/theme_provider.dart';
import 'services/connectivity_service.dart';
import 'utils/app_logger.dart';

// --- PUSH NOTIFICATION SERVICE ---

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.debug("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (!kIsWeb) {
        await _fcm.subscribeToTopic('new_sermons');
      }
    }

    // 2. Setup Foreground Notification Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Initialize Local Notifications for pop-ups
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initializationSettings);
    }

    // 4. Set the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle messages in foreground (Show the pop-up)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
      AppLogger.debug('Foreground Message received: ${notification?.title}');
    });
  }
}

// --- MAIN ENTRY POINT ---

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- FIRESTORE CONNECTIVITY SETTINGS ---
  // Persistence and Cache settings to help with offline-to-online transitions
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Make sure this 'await' is present!
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rhemalize.app.audio',
      androidNotificationChannelName: 'Rhemalize Audio Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
    AppLogger.debug("Audio service initialized successfully");
  } catch (e) {
    AppLogger.debug("Audio service initialization failed", e);
  }

  // 4. Push Notifications
  try {
    await PushNotificationService.initialize();
  } catch (e) {
    AppLogger.debug("Push notification initialization failed", e);
  }

  runApp(const RhemalizeApp());
}

class RhemalizeApp extends StatelessWidget {
  const RhemalizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SermonProvider()),
        ChangeNotifierProxyProvider<SermonProvider, AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, sermonProv, audioProv) {
            audioProv!.dataDelegate = sermonProv;
            return audioProv;
          },
        ),
        ChangeNotifierProxyProvider<SermonProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (_, sermonProv, favProv) =>
              favProv!..setSermons(sermonProv.sermons),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Rhemalize',
            themeMode: themeProv.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              colorSchemeSeed: Colors.deepPurple,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.deepPurple,
            ),
            home: const AuthRoot(),
          );
        },
      ),
    );
  }
}

class AuthRoot extends StatefulWidget {
  const AuthRoot({super.key});

  @override
  State<AuthRoot> createState() => _AuthRootState();
}

class _AuthRootState extends State<AuthRoot> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initAppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.startMonitoring(context);
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  void _initAppLinks() {
    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((e) {
      AppLogger.debug('Initial deep link failed', e);
    });
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (e) {
        AppLogger.debug('Deep link stream failed', e);
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    AppLogger.debug('Deep Link received: $uri');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isGuest) {
      return const MainApp();
    }

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snap.hasData) {
          return const LoginScreen();
        }

        if (auth.userRole == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (auth.userRole == 'admin') {
          return const admin_screen.AdminMainScreen();
        } else {
          return const MainApp();
        }
      },
    );
  }
}
