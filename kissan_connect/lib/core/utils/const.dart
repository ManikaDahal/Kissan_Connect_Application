import 'package:flutter/material.dart';

class Constants {
  static const String apiBaseUrl =
      "https://kissan-connect-application.onrender.com";

  // Payment Keys
  static const String stripePublishableKey =
      "pk_test_51TD0NGK11DAbC8QAQyV1QyecbrRzuBImfhA6nz7QHutbRKy6LHQaub251eJRXDWMlzGFVN5bqluhGrkOZqay4ig700oHGtFOhK";
  static const String khaltiPublicKey = "5c92f5e5b6514b7c93576c3380acb62b";

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
