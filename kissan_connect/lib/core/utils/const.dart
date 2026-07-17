import 'package:flutter/material.dart';

class Constants {
  static const String apiBaseUrl =
      "https://manika051-kissanconnect.hf.space";

  // Payment Keys
  static const String stripePublishableKey =
      "pk_test_51TD0NGK11DAbC8QAQyV1QyecbrRzuBImfhA6nz7QHutbRKy6LHQaub251eJRXDWMlzGFVN5bqluhGrkOZqay4ig700oHGtFOhK";
  static const String khaltiPublicKey = "5c92f5e5b6514b7c93576c3380acb62b";
  static const String esewaClientId = "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const String esewaSecretKey = "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Weather API
  static const String openWeatherApiKey = "dd32260d07aba141704576a8e9813ee9";
}
