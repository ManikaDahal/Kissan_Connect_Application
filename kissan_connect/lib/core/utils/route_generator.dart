import 'package:flutter/material.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/features/auth/presentation/pages/bottom_nav_bar.dart';
import 'package:kissan_connect/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:kissan_connect/features/auth/presentation/pages/login_page.dart';
import 'package:kissan_connect/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:kissan_connect/features/auth/presentation/pages/reset_password_page.dart';
import 'package:kissan_connect/features/auth/presentation/pages/signup_page.dart';
import 'package:kissan_connect/screens/home/category_products_screen.dart';
import 'package:kissan_connect/screens/home/checkout_screen.dart';
import 'package:kissan_connect/screens/onboarding_screen.dart';

class RouteGenerator {
  static void navigateToPage(
    BuildContext context,
    String route, {
    dynamic arguments,
  }) {
    Navigator.push(
      context,
      generateRoute(RouteSettings(name: route, arguments: arguments)),
    );
  }

  static void navigateToPageWithoutStack(
    BuildContext context,
    String route, {
    dynamic arguments,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      generateRoute(RouteSettings(name: route, arguments: arguments)),
      (route) => false,
    );
  }

  static void navigateBack(BuildContext context) {
    Navigator.pop(context);
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
        case Routes.bottomNavBarRoute:
        return MaterialPageRoute(builder: (_) => const BottomNavBar());

      case Routes.loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case Routes.signupRoute:
        return MaterialPageRoute(builder: (_) => const SignupPage());

      case Routes.forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case Routes.enterOTPRoute:
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(builder: (_) => OTPVerificationPage(email: args));
        }
        return MaterialPageRoute(builder: (_) => const OTPVerificationPage(email: ''));

      case Routes.resetPasswordRoute:
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(
              email: args['email'] ?? '',
              otp: args['otp'] ?? '',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ResetPasswordPage(email: '', otp: ''),
        );

      case Routes.categoryProductsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CategoryProductsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
        );

      case Routes.checkoutRoute:
        return MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
