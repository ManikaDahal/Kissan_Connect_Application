import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        RouteGenerator.navigateToPageWithoutStack(
          context,
          Routes.onboardingRoute,
        );
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/splashScreen.png",
              width: MediaQuery.of(context).size.width * 0.75,
            ),
          ],
        ),
      ),
    );
  }
}
