import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:kissan_connect/core/utils/const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/screens/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Stripe
  Stripe.publishableKey = Constants.stripePublishableKey;
  await Stripe.instance.applySettings();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KhaltiScope(
      publicKey: Constants.khaltiPublicKey,
      enabledDebugging: true,
      builder: (context, navKey) {
        return MaterialApp(
          navigatorKey: navKey,
          debugShowCheckedModeBanner: false,
          title: 'KissanConnect',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          ),
          home: SplashScreen(),
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}
