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
  String _version = "...";

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        final bool loggedIn = await ApiService.isLoggedIn();
        
        if (mounted) {
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
      }
    });
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version.isEmpty ? "1.0.0" : info.version;
        });
      }
    } catch (e) {
      // In case of MissingPluginException during hot reload without full restart
      if (mounted) {
        setState(() {
          _version = "1.0.0"; 
        });
      }
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
