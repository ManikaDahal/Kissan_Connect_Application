import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = "";

  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    // Load version and wait 2 s simultaneously.
    // PackageInfo resolves in < 50 ms on real devices, so the version is
    // always ready before the delay ends — no more "..." flicker.
    await Future.wait([
      _loadVersion(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;

    final bool loggedIn = await ApiService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      RouteGenerator.navigateToPageWithoutStack(
        context,
        Routes.bottomNavBarRoute,
      );
    } else {
      RouteGenerator.navigateToPageWithoutStack(
        context,
        Routes.onboardingRoute,
      );
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version.isEmpty ? "1.0.0" : info.version;
        });
      }
    } catch (_) {
      // Fallback for MissingPluginException during hot reload
      if (mounted) setState(() => _version = "1.0.0");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/splashScreen.png",
              width: MediaQuery.of(context).size.width * 0.5,
            ),
            const SizedBox(height: 24),
            // Only show version text once it's actually loaded
            if (_version.isNotEmpty)
              Text(
                "Version $_version",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
