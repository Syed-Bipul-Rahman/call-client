// notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:call_agora_lock/constants.dart';
import 'package:call_agora_lock/prefs_helpers.dart';
import 'call_screen.dart';

// Create a dedicated notification service class
class NotificationService {
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Channel IDs
  static const String _callChannelId = 'call_channel_id';
  static const String _defaultChannelId = 'default_channel_id';

  // Task names for WorkManager
  static const String _notificationCheckTask = 'notificationCheckTask';
  static const String _callServiceTask = 'callServiceTask';

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up Firebase Messaging
      await _initializeFirebaseMessaging();

      // Register notification listeners
      await _setupNotificationListeners();

      // Schedule periodic background work
    //  _schedulePeriodicWork();

      print('📱 Notification service initialized successfully');
    } catch (e) {
      print('🚨 Error initializing notification service: $e');
    }
  }

  // Initialize local notifications with proper channels
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

// Create notification channels (Android)
  static Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Create call notification channel (high priority)
      const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
        _callChannelId,
        'Call Notifications',
        description: 'Used for incoming call notifications',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('incoming_call'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      // Create default notification channel
      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        _defaultChannelId,
        'Default Notifications',
        description: 'Used for regular app notifications',
        importance: Importance.high,
      );

      // Create the notification channels individually
      await androidPlugin.createNotificationChannel(callChannel);
      await androidPlugin.createNotificationChannel(defaultChannel);
    }
  }

  // Initialize Firebase Messaging
  static Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request high priority permissions on iOS
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          criticalAlert: true,
          provisional: false,
          sound: true,
        );
      }

      // Configure foreground notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get and store FCM token
      await _getFcmToken();
    } catch (e) {
      print('🚨 Error initializing Firebase Messaging: $e');
    }
  }

  // Get FCM token and store it
  static Future<void> _getFcmToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await PrefsHelper.setString(Constants.fcmToken, token);
        print('📱 FCM Token: $token');
      }
    } catch (e) {
      print('🚨 Error getting FCM token: $e');
    }
  }

  // Set up notification listeners
  static Future<void> _setupNotificationListeners() async {
    // 1. Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 2. When app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleAppOpenFromBackground);

    // 3. Check for initial message (app opened from terminated state)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Foreground message received: ${message.messageId}');
    _logMessageData(message);

    if (message.data['type'] == 'call') {
      _handleIncomingCall(message);

      // Start foreground service for call (Android only)
      if (Platform.isAndroid) {
        _startCallForegroundService(message);
      }
    } else {
      _showRegularNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? 'You have a new notification',
      );
    }
  }

  // Handle when app is opened from background via notification
  static void _handleAppOpenFromBackground(RemoteMessage message) {
    print('🔔 App opened from background notification: ${message.messageId}');
    _logMessageData(message);

    if (message.data['type'] == 'call') {
      _handleIncomingCall(message);
    }
  }

  // Handle initial message (app opened from terminated state)
  static void _handleInitialMessage(RemoteMessage message) {
    print(
        '🔔 App opened from terminated state notification: ${message.messageId}');
    _logMessageData(message);

    // Add small delay to ensure app is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (message.data['type'] == 'call') {
        _handleIncomingCall(message);
      }
    });
  }

  // Log message data for debugging
  static void _logMessageData(RemoteMessage message) {
    print('📦 Message data:');
    message.data.forEach((key, value) {
      print('- $key: $value');
    });
  }

  // Handle incoming call notification
  static void _handleIncomingCall(RemoteMessage message) async {
    // 1. Show high-priority notification first
    await _showCallNotification(message);

    // 2. Extract call data
    Map<String, dynamic> callData = {
      'callerId': message.data['callerId'] ?? '',
      'callerName': message.data['callerName'] ?? 'Unknown Caller',
      'callType': message.data['callType'] ?? 'video',
      'roomId': message.data['roomId'] ?? '',
      'caller_profile_pic': message.data['caller_profile_pic'],
    };

    // 3. Store call data temporarily (important for recovering state)
    await _storeCallData(callData);

    // 4. Open call screen with reliable navigation
    _openCallScreen(callData);
  }

  // Store call data temporarily
  static Future<void> _storeCallData(Map<String, dynamic> callData) async {
    try {
      // Store as JSON string
      await PrefsHelper.setString('active_call_data', jsonEncode(callData));
      await PrefsHelper.setBool('has_active_call', true);
    } catch (e) {
      print('🚨 Error storing call data: $e');
    }
  }

  // Retrieve stored call data
  static Future<Map<String, dynamic>?> getStoredCallData() async {
    try {
      bool hasActiveCall =
          await PrefsHelper.getBool('has_active_call') ?? false;
      if (!hasActiveCall) return null;

      String callDataStr = await PrefsHelper.getString('active_call_data');
      if (callDataStr.isEmpty) return null;

      return jsonDecode(callDataStr) as Map<String, dynamic>;
    } catch (e) {
      print('🚨 Error retrieving call data: $e');
      return null;
    }
  }

  // Clear stored call data
  static Future<void> clearStoredCallData() async {
    await PrefsHelper.setBool('has_active_call', false);
    await PrefsHelper.setString('active_call_data', '');
  }

  // Open call screen with reliable navigation
  // Open call screen with reliable navigation
  static void _openCallScreen(Map<String, dynamic> callData) {
    try {
      // Use navigatorKey for navigation when app is in foreground
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => CallScreen(callData: callData),
          ),
        );
      } else {
        // For Android, we'll rely on the full screen intent in the notification
        // No need to try to start activity directly
        print('🔔 Navigator not available, relying on notification full screen intent');

        // Re-show notification with full screen intent
        _showCallNotification(RemoteMessage(
            data: {
              'roomId': callData['roomId'] ?? '',
              'callerName': callData['callerName'] ?? 'Unknown Caller'
            }
        ));
      }
    } catch (e) {
      print('🚨 Error opening call screen: $e');
    }
  }

  // Show call notification with high priority and sound
  static Future<void> _showCallNotification(RemoteMessage message) async {
    try {
      // Android notification details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _callChannelId,
        'Call Notifications',
        channelDescription: 'Used for incoming call notifications',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('incoming_call'),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        visibility: NotificationVisibility.public,
        timeoutAfter: 60000,
      );

      // iOS notification details
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'incoming_call.mp3',
        interruptionLevel: InterruptionLevel.critical,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Generate unique ID for the notification
      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Show notification
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        message.notification?.title ?? 'Incoming Call',
        message.notification?.body ?? 'Someone is calling you',
        platformDetails,
        payload: 'call:${message.data['roomId']}',
      );

      // Store notification ID for later use
      await PrefsHelper.setInt('last_call_notification_id', notificationId);
    } catch (e) {
      print('🚨 Error showing call notification: $e');
    }
  }

  // Show regular notification
  static Future<void> _showRegularNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _defaultChannelId,
        'Default Notifications',
        channelDescription: 'Used for regular app notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      print('🚨 Error showing regular notification: $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');

    if (response.payload?.startsWith('call:') == true) {
      String roomId = response.payload!.split(':')[1];
      _handleCallNotificationTap(roomId);
    }
  }

  // Handle call notification tap
  static void _handleCallNotificationTap(String roomId) async {
    try {
      // First check if we already have stored call data
      Map<String, dynamic>? callData = await getStoredCallData();

      // Use stored data or create minimal data
      if (callData == null || callData['roomId'] != roomId) {
        callData = {
          'roomId': roomId,
          'callerName': 'Incoming Call',
          'callType': 'video',
        };
      }

      // Open call screen
      _openCallScreen(callData);
    } catch (e) {
      print('🚨 Error handling call notification tap: $e');
    }
  }

  // Start foreground service for call (Android only)
  static Future<void> _startCallForegroundService(RemoteMessage message) async {
    if (Platform.isAndroid) {
      try {
        // Schedule a one-time task for the call service
        await Workmanager().registerOneOffTask(
          _callServiceTask,
          _callServiceTask,
          inputData: {
            'roomId': message.data['roomId'] ?? '',
            'callerName': message.data['callerName'] ?? 'Unknown Caller',
            'callType': message.data['callType'] ?? 'video',
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      } catch (e) {
        print('🚨 Error starting call foreground service: $e');
      }
    }
  }

  // Schedule periodic work for notification checks
  static void _schedulePeriodicWork() {
    try {
      // Schedule periodic task to ensure notifications are working
      Workmanager().registerPeriodicTask(
        _notificationCheckTask,
        _notificationCheckTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (e) {
      print('🚨 Error scheduling periodic work: $e');
    }
  }
}

// Top-level callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print('📱 Background task executed: $taskName');

    try {
      // Initialize for background processing
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      switch (taskName) {
        case 'notificationCheckTask':
          await _performNotificationCheck();
          break;
        case 'callServiceTask':
          if (inputData != null) {
            await _handleCallServiceTask(inputData);
          }
          break;
      }

      return true;
    } catch (e) {
      print('🚨 Error in background task: $e');
      return false;
    }
  });
}

// Notification check background task
Future<void> _performNotificationCheck() async {
  try {
    // Check if there's an active call
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasActiveCall = prefs.getBool('has_active_call') ?? false;

    if (hasActiveCall) {
      // Ensure notification is still visible
      String callDataStr = prefs.getString('active_call_data') ?? '';
      if (callDataStr.isNotEmpty) {
        Map<String, dynamic> callData = jsonDecode(callDataStr);

        // Show notification again if needed
        await _refreshCallNotification(callData);
      }
    }
  } catch (e) {
    print('🚨 Error in notification check: $e');
  }
}

// Refresh call notification to ensure it's visible
Future<void> _refreshCallNotification(Map<String, dynamic> callData) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android notification details
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'call_channel_id',
    'Call Notifications',
    channelDescription: 'Used for incoming call notifications',
    importance: Importance.max,
    priority: Priority.max,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('incoming_call'),
    fullScreenIntent: true,
    ongoing: true,
  );

  // iOS notification details
  const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'incoming_call.mp3',
    interruptionLevel: InterruptionLevel.critical,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iOSDetails,
  );

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    999, // Use consistent ID for refreshing
    'Ongoing Call',
    callData['callerName'] ?? 'Unknown Caller',
    platformDetails,
    payload: 'call:${callData['roomId']}',
  );
}

// Handle call service task
Future<void> _handleCallServiceTask(Map<String, dynamic> inputData) async {
  try {
    // Store call data
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_call', true);
    await prefs.setString('active_call_data', jsonEncode(inputData));

    // Show notification
    await _refreshCallNotification(inputData);
  } catch (e) {
    print('🚨 Error in call service task: $e');
  }
}

// Background message handler for Firebase
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize for background processing
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("🔔 Background message received: ${message.messageId}");

  if (message.data['type'] == 'call') {
    // Initialize notifications
    FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );
    await fln.initialize(initSettings);

    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'call_channel_id',
      'Call Notifications',
      channelDescription: 'Used for incoming call notifications',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('incoming_call'),
      fullScreenIntent: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'incoming_call.mp3',
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    // Show notification
    await fln.show(
      message.hashCode,
      message.notification?.title ?? 'Incoming Call',
      message.notification?.body ?? 'Someone is calling you',
      platformDetails,
      payload: 'call:${message.data['roomId']}',
    );

    // Store call data
    Map<String, dynamic> callData = {
      'callerId': message.data['callerId'] ?? '',
      'callerName': message.data['callerName'] ?? 'Unknown Caller',
      'callType': message.data['callType'] ?? 'video',
      'roomId': message.data['roomId'] ?? '',
      'caller_profile_pic': message.data['caller_profile_pic'],
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_call', true);
    await prefs.setString('active_call_data', jsonEncode(callData));
  }
}
