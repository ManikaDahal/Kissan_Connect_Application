import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:kissan_connect/core/utils/const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/screens/splashScreen.dart';
import 'package:kissan_connect/services/notification_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';
import 'package:kissan_connect/core/providers/connectivity_provider.dart';
import 'package:kissan_connect/widgets/no_internet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase + Push Notifications
  await NotificationService.initialize();

  // Initialize Stripe
  Stripe.publishableKey = Constants.stripePublishableKey;
  await Stripe.instance.applySettings();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: Constants.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'KissanConnect',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      onGenerateRoute: RouteGenerator.generateRoute,
      builder: (context, child) {
        return _ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _ConnectivityWrapper extends ConsumerWidget {
  final Widget child;
  const _ConnectivityWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return Stack(
      children: [
        child,
        // Show the no-internet overlay when connectivity is lost
        if (connectivity.whenOrNull(data: (isConnected) => !isConnected) == true)
          const Positioned.fill(
            child: NoInternetScreen(),
          ),
      ],
    );
  }
}
