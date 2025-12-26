import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/login_page.dart'; // 로그인 페이지 임포트!
import '../screens/home/home_page.dart'; // 홈 페이지 예시
import '../screens/auth/signup_page.dart'; // 회원가입 페이지 import
import '../screens/welcome/welcome_page.dart'; // 웰컴 페이지
import '../screens/profile/profile_page.dart'; //  ProfilePage import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB를 새로 만들었을 때 SharedPreferences도 초기화(프로필 이미지 등 삭제)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('profile_image');
  await prefs.remove('name');
  await prefs.remove('email');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '배재톡',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/welcome', // 초기 화면을 메인 페이지로 설정
      routes: {
        '/welcome': (context) => WelcomePage(), // 메인 페이지 추가
        '/login': (context) => LoginPage(), // 로그인 페이지  
        '/signup': (context) => SignUpPage(), // 회원가입 페이지
        '/home': (context) => HomePage(), // 홈 페이지
        '/myInfo': (context) => ProfilePage(), // 프로필 페이지
      },
    );
  }
}
