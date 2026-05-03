import 'package:flutter/material.dart';
import 'api.config.dart';
import 'pages/splash_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/auth_page.dart';

void main() {
  runApp(const NoteshareApp());
}

class NoteshareApp extends StatelessWidget {
  const NoteshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
