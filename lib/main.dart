import 'package:call_agora_lock/firebase_options.dart';
import 'package:call_agora_lock/pages/registerPage.dart';
import 'package:call_agora_lock/pages/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:flutter_login/flutter_login.dart';


import 'firebase_service.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  //
  //
  //
  // // Register background handler
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //
  //
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseMessaging.instance.setAutoInitEnabled(true);
  // FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  //   alert: true,
  //   badge: true,
  //   sound: true,
  // );
  // try {
  //   if (GetPlatform.isMobile) {
  //     final RemoteMessage? remoteMessage =
  //         await FirebaseMessaging.instance.getInitialMessage();
  //     if (remoteMessage != null) {}
  //
  //     print('Call Firebase Init');
  //     await NotificationHelper.init();
  //
  //     // await NotificationHelper.init(flutterLocalNotificationsPlugin);
  //     // FirebaseMessaging.onBackgroundMessage(NotificationHelper.firebaseMessagingBackgroundHandler);
  //   }
  // } catch (e) {}
  // // NotificationHelper.getFcmToken();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
