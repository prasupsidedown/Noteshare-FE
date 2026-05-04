import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';
import 'dashboard_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String _loginError = '';
  String _registerError = '';

  // ========== LOGIN ==========
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = 'Email dan password harus diisi';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'] as String;
        final user = data['data']['user'];

        await AuthStorage.saveAuth(
          token: token,
          userId: user['id'],
          name: user['name'],
          email: user['email'],
        );

        debugPrint('Login berhasil: ${user['email']}');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } else {
        setState(
          () => _loginError = data['message'] ?? 'Email atau password salah',
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
      setState(
        () => _loginError =
            'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== REGISTER ==========
  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _registerError = '';
    });

    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();
    final confirmPassword = _registerConfirmPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _registerError = 'Nama lengkap harus diisi';
        _isLoading = false;
      });
      return;
    }
    if (!_emailRegExp.hasMatch(email)) {
      setState(() {
        _registerError = 'Masukkan email yang valid';
        _isLoading = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _registerError = 'Password minimal 6 karakter';
        _isLoading = false;
      });
      return;
    }
    if (password != confirmPassword) {
      setState(() {
        _registerError = 'Konfirmasi password tidak cocok';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['data']['token'] as String;
        final user = data['data']['user'];

        await AuthStorage.saveAuth(
          token: token,
          userId: user['id'],
          name: user['name'],
          email: user['email'],
        );

        debugPrint('Registrasi berhasil: ${user['email']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil! Anda masuk otomatis.'),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } else {
        setState(() => _registerError = data['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      debugPrint('Register error: $e');
      setState(
        () => _registerError =
            'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.book, size: 45, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NOTESHARE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 32),

                // ========== LOGIN FORM ==========
                if (_isLogin) ...[
                  const Text(
                    'Masuk ke akun Anda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _loginEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'email@example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _loginPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (_loginError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _loginError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = false),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
                // ========== REGISTER FORM ==========
                else ...[
                  const Text(
                    'Daftar Akun Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _registerNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'email@example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      helperText: 'Gunakan email yang valid',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Minimal 6 karakter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _registerConfirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password',
                      hintText: 'Masukkan ulang password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_registerError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _registerError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = true),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
