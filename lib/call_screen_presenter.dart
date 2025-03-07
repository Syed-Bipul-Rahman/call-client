// call_screen_presenter.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:call_agora_lock/prefs_helpers.dart';
import 'call_screen.dart';

class CallScreenPresenter {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Constants
  static const String _callChannelId = 'call_channel_high_priority';
  static const int _fullScreenNotificationId = 888;
  static const String _callDataKey = 'active_call_data';
  static const String _hasActiveCallKey = 'has_active_call';

  // Initialize the presenter
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      await _setupFullScreenIntentChannel();
    }
  }

  // Setup dedicated channel for full-screen intents on Android
  static Future<void> _setupFullScreenIntentChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // High priority channel specifically for full-screen intents
      const AndroidNotificationChannel fullScreenChannel = AndroidNotificationChannel(
        _callChannelId,
        'Incoming Call Alerts',
        description: 'Critical alerts for incoming calls',
        importance: Importance.max,
        // priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('incoming_call'),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(fullScreenChannel);

      // Request exact alarms permission for reliable scheduling
      await androidPlugin.requestExactAlarmsPermission();

      // Request notification runtime permissions
      // await androidPlugin.requestPermission();

      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestNotificationsPermission();
      // Request notification policy access if targeting Android 13+
      try {
        await androidPlugin.requestNotificationsPermission();
      } catch (e) {
        // May not be available on all Android versions
        print('⚠️ Could not request notifications permission: $e');
      }
    }
  }

  // Present call screen when phone is locked
  static Future<void> presentCallScreen(Map<String, dynamic> callData) async {
    // 1. Store call data for recovery
    await _storeCallData(callData);

    // 2. Send high-priority full-screen notification
    await _showFullScreenNotification(callData);

    // 3. Start a wakelock if possible (platform-specific)
    await _acquireWakeLock();

    // 4. Schedule a retry mechanism in case the first attempt fails
    _scheduleRetryIfNeeded(callData);
  }

  // Store call data for recovery
  static Future<void> _storeCallData(Map<String, dynamic> callData) async {
    try {
      await PrefsHelper.setString(_callDataKey, jsonEncode(callData));
      await PrefsHelper.setBool(_hasActiveCallKey, true);

      // Also store timestamp for expiration logic
      await PrefsHelper.setInt('call_received_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('🚨 Error storing call data in presenter: $e');
    }
  }

  // Show full-screen notification that can unlock the device
  static Future<void> _showFullScreenNotification(Map<String, dynamic> callData) async {
    try {
      // Create platform-specific notification details
      final NotificationDetails platformDetails = _createPlatformNotificationDetails();

      // Set up intent to open activity directly on Android
      if (Platform.isAndroid) {
        await _setupAndroidFullScreenIntent(callData);
      }

      // Show the notification
      await _localNotifications.show(
        _fullScreenNotificationId,
        callData['callerName'] ?? 'Incoming Call',
        'Tap to answer call',
        platformDetails,
        payload: 'call:${callData['roomId']}:fullscreen',
      );
    } catch (e) {
      print('🚨 Error showing full-screen notification: $e');
    }
  }

  // Create notification details with platform-specific settings
  static NotificationDetails _createPlatformNotificationDetails() {
    // Android notification details with full-screen intent
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _callChannelId,
      'Incoming Call Alerts',
      channelDescription: 'Critical alerts for incoming calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      playSound: true,
      usesChronometer: true,
      ongoing: true,
      autoCancel: false,
      sound: const RawResourceAndroidNotificationSound('incoming_call'),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'answer',
          'Answer',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_answer'),
          contextual: true,
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'decline',
          'Decline',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_decline'),
        ),
      ],
    );

    // iOS notification details with critical alert settings
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'incoming_call.mp3',
      interruptionLevel: InterruptionLevel.critical,
      // Critical alerts require special entitlement from Apple
      // critical: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
  }

  // Setup Android-specific full screen intent
  static Future<void> _setupAndroidFullScreenIntent(Map<String, dynamic> callData) async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Set custom intent extras to help launch the correct activity
        // await androidPlugin.setNotificationOngoing(_fullScreenNotificationId, true);
        await androidPlugin.startForegroundService(1, "joybangla", "amar sonar bangla");
      }
    } catch (e) {
      print('🚨 Error setting up Android full-screen intent: $e');
    }
  }

  // Acquire wakelock to keep CPU active
  static Future<void> _acquireWakeLock() async {
    // This would normally use a wakelock package
    // Since we're keeping this implementation minimal,
    // we'll provide guidance on adding this functionality later
    print('📱 Would acquire wakelock here');
  }

  // Schedule retry in case the first attempt fails
  static void _scheduleRetryIfNeeded(Map<String, dynamic> callData) {
    // Schedule a few retries with increasing delays
    [1, 3, 5].forEach((seconds) {
      Timer(Duration(seconds: seconds), () async {
        // Check if call is still active before retrying
        bool isActive = await PrefsHelper.getBool(_hasActiveCallKey) ?? false;
        if (isActive) {
          print('📱 Retry attempt after $seconds seconds');
          _showFullScreenNotification(callData);
        }
      });
    });
  }

  // Method to launch call screen from notification
  static Future<void> launchCallScreenFromNotification(String roomId) async {
    // Get the stored call data
    Map<String, dynamic>? callData = await _getStoredCallData();

    if (callData != null && callData['roomId'] == roomId) {
      await _openCallScreen(callData);
    } else {
      // Fallback with minimal data
      await _openCallScreen({
        'roomId': roomId,
        'callerName': 'Incoming Call',
        'callType': 'video',
      });
    }
  }

  // Get stored call data
  static Future<Map<String, dynamic>?> _getStoredCallData() async {
    try {
      bool hasActiveCall = await PrefsHelper.getBool(_hasActiveCallKey) ?? false;
      if (!hasActiveCall) return null;

      String callDataStr = await PrefsHelper.getString(_callDataKey);
      if (callDataStr.isEmpty) return null;

      return jsonDecode(callDataStr) as Map<String, dynamic>;
    } catch (e) {
      print('🚨 Error retrieving call data: $e');
      return null;
    }
  }

  // Open call screen with the given data
  static Future<void> _openCallScreen(Map<String, dynamic> callData) async {
    try {
      // Get top-level navigator key from NotificationService
      final navigatorKey = GlobalKey<NavigatorState>();

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => CallScreen(callData: callData),
          ),
        );
      } else {
        print('🚨 Navigator not available for call screen');
        // Use platform-specific approach to force activity start
        if (Platform.isAndroid) {
          // This would be handled by the full-screen intent
        }
      }
    } catch (e) {
      print('🚨 Error opening call screen: $e');
    }
  }

  // Clear active call data
  static Future<void> clearCallData() async {
    await PrefsHelper.setBool(_hasActiveCallKey, false);
    await PrefsHelper.setString(_callDataKey, '');

    // Also cancel the notification
    await _localNotifications.cancel(_fullScreenNotificationId);
  }
}