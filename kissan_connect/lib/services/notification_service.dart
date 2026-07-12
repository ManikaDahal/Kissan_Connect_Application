import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kissan_connect/services/api_service.dart';

/// Top-level handler for background messages (must be outside a class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for high-importance alerts.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kissan_high_importance_channel',
    'KissanConnect Notifications',
    description: 'Order updates, new products, and discount alerts.',
    importance: Importance.max,
    playSound: true,
  );

  /// Call once at app startup (in main.dart).
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ requires explicit permission)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up local notifications for foreground display
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Show a local notification when a push arrives in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data['route'],
        );
      }
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRoute(message.data['route']);
    });

    // Handle notification tap when app was completely terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRoute(initialMessage.data['route']);
    }
  }

  /// After login, send the FCM token to the Django backend.
  static Future<void> sendTokenToServer() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await ApiService.post('users/fcm-token/', {'fcm_token': token});
      }
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        ApiService.post('users/fcm-token/', {'fcm_token': newToken});
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to send FCM token: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    _handleRoute(response.payload);
  }

  static void _handleRoute(String? route) {
    if (route == null) return;
    // Navigate using the global navigator key from Constants
    // Routes: 'orders', 'seller_orders', 'home'
    debugPrint('NotificationService: Navigate to $route');
  }
}
