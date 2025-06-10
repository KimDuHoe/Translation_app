import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MilestoneApp());
}

class MilestoneApp extends StatelessWidget {
  const MilestoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '마일스톤',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSans',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
