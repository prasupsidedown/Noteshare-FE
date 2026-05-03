import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';
import '../pages/auth_page.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _courses = [];
  bool _isCourseExpanded = true;
  bool _isLoadingCourses = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCourses();
  }

  Future<void> _loadUser() async {
    final userData = await AuthStorage.getUserData();
    if (mounted) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _userEmail = userData['email'] ?? '';
      });
    }
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConfig.courses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> courses = data['data'] ?? [];
        if (mounted) {
          setState(() {
            _courses = List<Map<String, dynamic>>.from(courses);
            _isLoadingCourses = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCourses = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _handleLogout() async {
    await AuthStorage.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  Color _getCourseColor(int index) {
    const colors = [
      Color(0xFF1E3A5F),
      Color(0xFF0F9D58),
      Color(0xFFE65100),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFC62828),
      Color(0xFF283593),
      Color(0xFF2E7D32),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
<<<<<<< HEAD
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
=======
            // ========== HEADER DRAWER (DIPERBAIKI: GRADIENT + MELENGKUNG) ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30), // ← padding disesuaikan
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
<<<<<<< HEAD
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
=======
                  bottomLeft: Radius.circular(25),   // ← melengkung
                  bottomRight: Radius.circular(25),  // ← melengkung
>>>>>>> d0746a68e75d046c09db049b23079685ca579a67
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 4),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.search,
                    title: 'Cari Catatan',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.upload_file,
                    title: 'Upload Catatan',
                    index: 2,
                  ),

                  // ── Mata Kuliah row + expand toggle ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Material(
                      color: widget.currentIndex == 4
                          ? Colors.blue.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                widget.onItemSelected(4);
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.school,
                                      color: widget.currentIndex == 4
                                          ? const Color(0xFF1E3A5F)
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Mata Kuliah',
                                      style: TextStyle(
                                        color: widget.currentIndex == 4
                                            ? const Color(0xFF1E3A5F)
                                            : Colors.grey[600],
                                        fontWeight: widget.currentIndex == 4
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_courses.isNotEmpty)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(
                                () => _isCourseExpanded = !_isCourseExpanded,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _isCourseExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Sub-list matkul
                  if (_courses.isNotEmpty && _isCourseExpanded)
                    ..._courses.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final course = entry.value;
                      final color = _getCourseColor(idx);
                      final initial = (course['name'] as String).isNotEmpty
                          ? (course['name'] as String)[0].toUpperCase()
                          : '?';

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 8,
                          bottom: 2,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            widget.onItemSelected(4);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: color,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF333333),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (course['semester'] != null)
                                        Text(
                                          course['semester'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  if (_isLoadingCourses)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 56,
                        top: 4,
                        bottom: 4,
                      ),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person,
                    title: 'Profil',
                    index: 3,
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onTap: _handleLogout,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = widget.currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? Colors.blue.shade50 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          widget.onItemSelected(index);
          Navigator.pop(context);
        },
      ),
    );
  }
}
