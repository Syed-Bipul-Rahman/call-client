import 'package:call_agora_lock/constants.dart';
import 'package:call_agora_lock/prefs_helpers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

class NotificationHelper {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Fetch and store FCM Token
  static Future<void> getFcmToken() async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        PrefsHelper.setString(Constants.fcmToken, fcmToken);
        print('📱 FCM Token Successfully Generated: $fcmToken');
      } else {
        print('❌ Failed to generate FCM Token');
      }
    } catch (e) {
      print('🚨 Error generating FCM Token: $e');
    }
  }

  // Initialize Firebase Messaging
  static Future<void> init() async {
    try {
      // Request Notification Permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Notification Permission Status: ${settings.authorizationStatus}');

      // Get and log FCM Token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔑 FCM Token: $token');
        PrefsHelper.setString(Constants.fcmToken, token);
      }

      // Configure messaging options
      _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('🚨 Initialization Error: $e');
    }



    // Configure background and terminated state handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 App Opened from Background Notification');
      _handleNotificationNavigation(message);
    });

    // Handle initial message when app is launched from terminated state
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print('🚀 App Launched from Terminated State Notification');
      _handleNotificationNavigation(initialMessage);
    }
  }

  static void _handleNotificationNavigation(RemoteMessage message) {
    // Implement your navigation logic based on notification type
    String? type = message.data['type'];

    switch (type) {
      case 'call':
      // Navigate to call screen
      // Example:
      // Navigator.pushNamed(context, '/call', arguments: message.data);
        break;
      case 'message':
      // Navigate to message screen
        break;
      default:
        print('🤷 Unknown notification type: $type');
    }

  }

  // Comprehensive Notification Listener
  static Future<void> firebaseListenNotification({required BuildContext context}) async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Detailed Logging
      print('🔔 Notification Received');
      print('🏷️ Title: ${message.notification?.title}');
      print('📝 Body: ${message.notification?.body}');

      // Print all data fields
      print('📦 Full Notification Data:');
      message.data.forEach((key, value) {
        print('- $key: $value');
      });

      // Specific type checking
      String? type = message.data['type'];
      print('📲 Notification Type: $type');

      // You can add more specific logging based on your needs
      if (message.data.containsKey('callType')) {
        print('📞 Call Type: ${message.data['callType']}');
      }

      // Rest of your existing code
      initLocalNotification(message: message);
      showTextNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? 'You have a new message',
      );
    }, onError: (error) {
      print('🚨 Notification Receive Error: $error');
    });
  }

  // Detailed Notification Logging
  static void _logNotificationDetails(RemoteMessage message, {String notificationType = 'UNKNOWN'}) {
    print('===== $notificationType NOTIFICATION =====');
    print('🔔 Notification Title: ${message.notification?.title}');
    print('📝 Notification Body: ${message.notification?.body}');
    print('📦 Notification Data: ${message.data}');

    // Log each data key-value pair
    message.data.forEach((key, value) {
      print('🔑 Data Key: $key, Value: $value');
    });
    print('================================');
  }

  // Initialize Local Notification
  static Future<void> initLocalNotification({required RemoteMessage message}) async {
    try {
      // Android Notification Settings
      AndroidInitializationSettings androidInitSettings =
      const AndroidInitializationSettings("@mipmap/ic_launcher");

      // iOS Notification Settings
      var iOSInitSettings = const DarwinInitializationSettings();

      // Combined Initialization Settings
      var initializationSettings = InitializationSettings(
          android: androidInitSettings,
          iOS: iOSInitSettings
      );

      // Request Notifications Permission for Android
      fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Initialize Local Notifications
      await fln.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse? payload) {
          print('🔔 Local Notification Payload Received');
          if (payload != null) {
            handleMessage(message: message);
          }
        },
      );
    } catch (e) {
      print('🚨 Local Notification Initialization Error: $e');
    }
  }

  // Handle Notification Message
  static void handleMessage({required RemoteMessage message}) {
    try {
      Map<String, dynamic> data = message.data;
      String type = data["type"] ?? 'unknown';

      print('🚀 Handling Notification Type: $type');
      print('📬 Notification Data: $data');

      // Add your custom routing or action logic here
      // Example:
      // if (type == "call") {
      //   Navigator.pushNamed(context, CallScreen.routeName, arguments: data);
      // }
    } catch (e) {
      print('🚨 Message Handling Error: $e');
    }
  }

  // Show Text Notification
  static Future<void> showTextNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Android Notification Details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'notification_channel',
        'Notification Channel',
        playSound: true,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      // iOS Notification Details
      var iOSDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true
      );

      // Combined Notification Details
      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Show Notification
      await fln.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('🚨 Show Notification Error: $e');
    }
  }
}