import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../api.config.dart';
import 'auth_page.dart';
import 'dashboard_page.dart';
=======
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../main.dart'; // Import MainWrapper
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
<<<<<<< HEAD
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final isLoggedIn = await AuthStorage.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const DashboardPage() : const AuthPage(),
      ),
    );
=======
    // Tunggu 3 detik
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Cek apakah user sudah login
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Jika sudah login → MainWrapper (Dashboard)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } else {
      // Jika belum login → LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
<<<<<<< HEAD
            colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
=======
            colors: [
              Color(0xFF1E3A5F),
              Color(0xFF3B82F6),
            ],
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
<<<<<<< HEAD
=======
            // Logo
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
<<<<<<< HEAD
              child: const Icon(Icons.book, size: 65, color: Color(0xFF1E3A5F)),
            ),
            const SizedBox(height: 32),
=======
              child: const Icon(
                Icons.book,
                size: 65,
                color: Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(height: 32),
            // Nama Aplikasi
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
            const Text(
              'NOTESHARE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
<<<<<<< HEAD
=======
            // Tagline
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
            const Text(
              'Bagikan Catatan, Bagikan Ilmu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
