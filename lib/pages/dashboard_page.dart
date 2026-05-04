import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';
import '../widgets/app_drawer.dart';
import '../widgets/notification_bell.dart';
import '../widgets/floating_chat_button.dart';
import 'semester_detail_page.dart';
import 'search_page.dart';
import 'upload_page.dart';
import 'profile_page.dart';
import 'course_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _semesterData = [];
  bool _isLoading = true;
  String _userName = '';

  final List<Color> _cardColors = const [
    Color(0xFFE8F4FD), Color(0xFFE8F5E9), Color(0xFFFEF3E8),
    Color(0xFFFDE8EF), Color(0xFFEDE7F6), Color(0xFFE0F2F1),
    Color(0xFFFFF3E0), Color(0xFFF3E5F5),
  ];

  final List<Color> _iconColors = const [
    Color(0xFF1E3A5F), Color(0xFF0F9D58), Color(0xFFE65100),
    Color(0xFFE91E63), Color(0xFF6A1B9A), Color(0xFF00838F),
    Color(0xFFF57C00), Color(0xFF7B1FA2),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchSemesterFromCourses();
  }

  Future<void> _loadUserName() async {
    final userData = await AuthStorage.getUserData();
    if (mounted) {
      setState(() => _userName = userData['name'] ?? '');
    }
  }

  Future<void> _fetchSemesterFromCourses() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.courses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> courses = data['data'] ?? [];

        Map<String, int> semesterCount = {};
        for (var course in courses) {
          String semester = course['semester'] ?? 'Semester 1';
          semesterCount[semester] = (semesterCount[semester] ?? 0) + 1;
        }

        final List<Map<String, dynamic>> semesterList = [];
        semesterCount.forEach((semester, count) {
          int semesterNum = int.tryParse(semester.replaceAll('Semester ', '')) ?? 1;
          semesterList.add({
            'name': semester,
            'count': count,
            'number': semesterNum,
          });
        });

        semesterList.sort((a, b) => a['number'].compareTo(b['number']));

        if (mounted) {
          setState(() {
            _semesterData = semesterList;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch semester error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotificationPopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Divider(),
            Expanded(child: Center(child: Text('Belum ada notifikasi'))),
          ],
        ),
      ),
    );
  }

  // ========== NAVIGASI KE HALAMAN LAIN ==========
  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const SearchPage();
      case 2:
        return const UploadPage();
      case 3:
        return const ProfilePage();
      case 4:
        return const CoursePage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _fetchSemesterFromCourses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Dashboard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName.isNotEmpty ? 'Halo, $_userName!' : 'Kelola mata kuliahmu',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Konten Semester
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Semester Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Kelola mata kuliah dan catatan per semester',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 20),

                  if (_isLoading && _semesterData.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_semesterData.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('Belum ada mata kuliah',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Text('Buat mata kuliah dulu di menu Mata Kuliah',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _semesterData.length,
                      itemBuilder: (context, index) {
                        final semester = _semesterData[index];
                        final colorIndex = (semester['number'] - 1) % _cardColors.length;
                        final cardColor = _cardColors[colorIndex];
                        final iconColor = _iconColors[colorIndex];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SemesterDetailPage(
                                      semesterName: semester['name'],
                                      semesterNumber: semester['number'],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_getSemesterIcon(semester['number']), color: iconColor, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(semester['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text('${semester['count']} Mata Kuliah',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSemesterIcon(int semester) {
    switch (semester) {
      case 1: return Icons.looks_one;
      case 2: return Icons.looks_two;
      case 3: return Icons.looks_3;
      case 4: return Icons.looks_4;
      case 5: return Icons.looks_5;
      case 6: return Icons.looks_6;
      case 7: return Icons.numbers;
      case 8: return Icons.numbers;
      default: return Icons.bookmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: null,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [NotificationBell(onTap: _showNotificationPopup)],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: AppDrawer(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: _getBody(),
      floatingActionButton: const FloatingChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}