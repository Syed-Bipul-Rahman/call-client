import 'package:call_agora_lock/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/platform/platform.dart';

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // @override
  // void initState() {
  //   super.initState();
  //
  //   NotificationHelper.init().then((_) {
  //     // Get FCM Token
  //     NotificationHelper.getFcmToken();
  //
  //     // Start listening for notifications
  //     NotificationHelper.firebaseListenNotification(context: context);
  //   });
  // }
  //
  // @override
  // void initState() {
  //   super.initState();
  //   _initializeNotifications();
  // }
  //
  // Future<void> _initializeNotifications() async {
  //   // Initialize notification services
  //   await NotificationHelper.init();
  //
  //   // Setup listeners
  //   await NotificationHelper.setupNotificationListeners();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
