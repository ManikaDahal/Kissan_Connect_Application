import 'package:flutter/material.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/screens/splashScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KissanConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: SplashScreen(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
