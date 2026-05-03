import 'package:flutter/material.dart';
import 'api.config.dart';
import 'pages/splash_page.dart';
<<<<<<< HEAD
=======
import 'pages/login_page.dart';
import 'pages/register_page.dart';
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
import 'pages/dashboard_page.dart';
import 'pages/auth_page.dart';

<<<<<<< HEAD
void main() {
=======
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dbkowlazgxdcqqjrvlhh.supabase.co',
    anonKey:
        'sb_publishable_DL2D_EemJofCFkONb7_mHg_cAYbHfLZ',
  );
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
  runApp(const NoteshareApp());
}

class NoteshareApp extends StatelessWidget {
  const NoteshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      title: 'Noteshare',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FutureBuilder<bool>(
        future: AuthStorage.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashPage();
          }
          return snapshot.data == true
              ? const DashboardPage()
              : const AuthPage();
        },
      ),
=======
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
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
    );
  }
}