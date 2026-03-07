import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Required for platform check
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

// --- PUSH NOTIFICATION SERVICE ---

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission (Required for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FIX: Topics are not supported on Web clients
      if (!kIsWeb) {
        await _fcm.subscribeToTopic('new_sermons');
      } else {
        debugPrint("FCM: Skipping topic subscription on Web.");
      }
    }

    // Set the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message: ${message.notification?.title}');
    });
  }
}

// --- MAIN ENTRY POINT ---

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await PushNotificationService.initialize();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.rhemalize.app.audio',
      androidNotificationChannelName: 'Rhemalize Audio Playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint("Audio init skip: $e");
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
    });
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep Link received: $uri');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

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
