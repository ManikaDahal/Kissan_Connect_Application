import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kissan_connect/core/utils/const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/screens/splashScreen.dart';
import 'package:kissan_connect/services/notification_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase + Push Notifications
  await NotificationService.initialize();

  // Initialize Stripe
  Stripe.publishableKey = Constants.stripePublishableKey;
  await Stripe.instance.applySettings();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Constants.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'KissanConnect',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
