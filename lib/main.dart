import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'package:campus_counseling_app/services/notification_service.dart';
import 'package:campus_counseling_app/utils/navigation_service.dart';

// Screens
import 'package:campus_counseling_app/splash_screen.dart';
import 'package:campus_counseling_app/welcome_screen.dart';
import 'package:campus_counseling_app/role_selection_screen.dart';
import 'package:campus_counseling_app/student_dashboard_screen.dart';
import 'package:campus_counseling_app/student_login_screen.dart';
import 'package:campus_counseling_app/counselor_login_screen.dart';
import 'package:campus_counseling_app/counselor_signup_screen.dart';
import 'package:campus_counseling_app/book_screen.dart';
import 'package:campus_counseling_app/counselor_dashboard_screen.dart';
import 'package:campus_counseling_app/counselor_bookings_screen.dart';
import 'package:campus_counseling_app/student_chat_screen.dart';
import 'package:campus_counseling_app/CounselorInChatScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final logger = Logger();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.i('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBTKTlBeFkWYByUvGmfXP9751mWaR3exhY",
        authDomain: "campus-counselling-app.firebaseapp.com",
        projectId: "campus-counselling-app",
        storageBucket: "campus-counselling-app.appspot.com",
        messagingSenderId: "1071502381770",
        appId: "1:1071502381770:web:c5f255bdf5deefd43f5a33",
      ),
    );
  } else {
    await Firebase.initializeApp();
    await initializeLocalNotifications(); // ✅ local notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const CampusCounsellingApp());
}

class CampusCounsellingApp extends StatelessWidget {
  const CampusCounsellingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusCounselling',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/splashscreen',
      routes: {
        '/splashscreen': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/student_login': (context) => const StudentLoginScreen(),
        '/student_home': (context) => const StudentDashboardScreen(),
        '/counselor_login': (context) => const CounselorLoginScreen(),
        '/counselor_signup': (context) => const CounselorSignupScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/student_dashboard_screen':
            (context) => const StudentDashboardScreen(),
        '/student_chat': (context) => const StudentChatScreen(),
        '/book_screen': (context) => const BookScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/counselor_dashboard': (context) => const CounselorDashboardScreen(),
        '/counselor_bookings': (context) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            return const Scaffold(body: Center(child: Text('Not logged in')));
          }
          return CounselorBookingsScreen(counselorId: currentUser.uid);
        },
        '/counselor_in_chat':
            (context) => const CounselorInChatScreen(
              studentName: '',
              chatId: '',
              appointmentId: '',
              counselorId: '',
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/student_chat') {
          return MaterialPageRoute(
            builder: (context) => const StudentChatScreen(),
          );
        }

        if (settings.name == '/counselor_in_chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => CounselorInChatScreen(
                  studentName: args['studentName'],
                  chatId: args['chatId'],
                  appointmentId: args['appointmentId'],
                  counselorId: '',
                ),
          );
        }

        return MaterialPageRoute(
          builder:
              (context) =>
                  const Scaffold(body: Center(child: Text('Unknown Route'))),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      logger.i('User granted permission: ${settings.authorizationStatus}');
      _token = await messaging.getToken();
      logger.i('FCM Token: $_token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (!mounted) return;

        logger.i('Foreground message: ${message.notification?.title}');
        if (message.notification != null) {
          showLocalNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logger.i('Notification opened: ${message.notification?.title}');
        // Add navigation here if needed
      });
    } catch (e) {
      logger.e('Error setting up Firebase Messaging: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CampusCounselling')),
      body: const Center(child: Text('Welcome to CampusCounselling App!')),
    );
  }
}
