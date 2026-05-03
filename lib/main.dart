import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/search_page.dart';
import 'pages/upload_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dbkowlazgxdcqqjrvlhh.supabase.co',
    anonKey:
        'sb_publishable_DL2D_EemJofCFkONb7_mHg_cAYbHfLZ',
  );
  runApp(const NoteshareApp());
}

class NoteshareApp extends StatelessWidget {
  const NoteshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTESHARE',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3A5F),
        fontFamily: 'Poppins',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      ),
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const SearchPage(),
    const UploadPage(),
    const ChatbotPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      // ========== BOTTOM NAVIGATION BAR DIHAPUS ==========
      // Tidak ada bottomNavigationBar lagi
      // Navigasi hanya melalui Drawer (garis tiga)
    );
  }
}