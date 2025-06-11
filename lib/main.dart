import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- 이제 이 임포트가 가능해야 합니다.
import 'screens/splash_screen.dart';

Future<void> main() async {
  // main 함수를 async로 변경
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 작업 전에 초기화 확인

  await dotenv.load(fileName: ".env"); // .env 파일 로드

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
