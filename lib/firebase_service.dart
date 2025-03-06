import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:call_agora_lock/constants.dart';
import 'package:call_agora_lock/prefs_helpers.dart';

// Import the call screen
// import 'package:call_agora_lock/screens/call_screen.dart';

import 'call_screen.dart';

FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure initialization
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("🔔 Background Notification Received: ${message.messageId}");
  print("📱 Notification Type: ${message.data['type']}");

  // Initialize local notifications
  await initLocalNotificationsForBackground();

  // Show notification
  if (message.data['type'] == 'call') {
    await showCallNotification(message);


  }
}

// Initialize notifications for background messages
Future<void> initLocalNotificationsForBackground() async {
  AndroidInitializationSettings androidInitSettings =
  const AndroidInitializationSettings("@mipmap/ic_launcher");
  var iOSInitSettings = const DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iOSInitSettings
  );
  await fln.initialize(initializationSettings);
}

// Show a high-priority call notification
Future<void> showCallNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'call_channel_id',
    'Call Notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('incoming_call'),
    fullScreenIntent: true,
  );

  const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'incoming_call.mp3',
    interruptionLevel: InterruptionLevel.critical,
  );

  NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails, iOS: iOSDetails);

  await fln.show(
    message.hashCode,
    message.notification?.title ?? 'Incoming Call',
    message.notification?.body ?? 'Someone is calling you',
    platformDetails,
    payload: 'call:${message.data['roomId']}',
  );
}

class NotificationHelper {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Get and store FCM token
  static Future<void> getFcmToken() async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        PrefsHelper.setString(Constants.fcmToken, fcmToken);
        print('📱 FCM Token: $fcmToken');
      }
    } catch (e) {
      print('🚨 Error getting FCM token: $e');
    }
  }

  // Initialize Firebase Messaging
  static Future<void> init() async {
    try {
      // Request permissions with high interruption level
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          criticalAlert: true, // For high-priority alerts
          provisional: false,
          sound: true,
        );
      }

      // Configure notification presentation options
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Setup background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await initLocalNotifications();

      // Get FCM token
      await getFcmToken();
    } catch (e) {
      print('🚨 Notification initialization error: $e');
    }
  }

  // Initialize local notifications
  static Future<void> initLocalNotifications() async {
    try {
      AndroidInitializationSettings androidInitSettings =
      const AndroidInitializationSettings("@mipmap/ic_launcher");
      var iOSInitSettings = const DarwinInitializationSettings();
      var initializationSettings = InitializationSettings(
          android: androidInitSettings,
          iOS: iOSInitSettings
      );

      fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await fln.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('🔔 Notification clicked: ${response.payload}');

          if (response.payload?.startsWith('call:') == true) {
            String roomId = response.payload!.split(':')[1];
            _handleCallNotificationTap(roomId);
          }
        },
      );
    } catch (e) {
      print('🚨 Local notification init error: $e');
    }
  }

  // Setup notification listeners
  static Future<void> setupNotificationListeners() async {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received');
      _logMessageData(message);

      if (message.data['type'] == 'call') {
        _handleIncomingCall(message);
      } else {
        // Show regular notification
        showTextNotification(
          title: message.notification?.title ?? 'Notification',
          body: message.notification?.body ?? 'You have a new notification',
        );
      }
    });

    // 2. Background message opens
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App opened from background notification');
      _logMessageData(message);

      if (message.data['type'] == 'call') {
        _handleIncomingCall(message);
      }
    });

    // 3. App opened from terminated state
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 App opened from terminated state notification');
      _logMessageData(initialMessage);

      if (initialMessage.data['type'] == 'call') {
        _handleIncomingCall(initialMessage);
      }
    }
  }

  // Log message data
  static void _logMessageData(RemoteMessage message) {
    print('📦 Message data: ${message.data}');
    message.data.forEach((key, value) {
      print('- $key: $value');
    });
  }

  // Handle incoming call
  static void _handleIncomingCall(RemoteMessage message) {
    // Extract call data
    Map<String, dynamic> callData = {
      'callerId': message.data['callerId'] ?? '',
      'callerName': message.data['callerName'] ?? 'Unknown Caller',
      'callType': message.data['callType'] ?? 'video',
      'roomId': message.data['roomId'] ?? '',
      'caller_profile_pic': message.data['caller_profile_pic'],
    };

    // Navigate to call screen
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CallScreen(callData: callData),
      ),
    );
  }

  // Handle call notification tap
  static void _handleCallNotificationTap(String roomId) {
    // This would open call screen when notification is tapped
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callData: {
            'roomId': roomId,
            'callerName': 'Incoming Call',
            'callType': 'video',
          },
        ),
      ),
    );
  }

  // Show text notification
  static Future<void> showTextNotification({
    required String title,
    required String body,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel_id',
        'Default Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails, iOS: iOSDetails);

      await fln.show(
        DateTime.now().millisecond,
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      print('🚨 Error showing notification: $e');
    }
  }
}