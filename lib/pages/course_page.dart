import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;

  double _fabX = -1;
  double _fabY = -1;
  bool _fabInitialized = false;

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedSemester;

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
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
        setState(() {
          _courses = List<Map<String, dynamic>>.from(courses);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch courses error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCourse() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    if (name.isEmpty) {
      _showSnackbar('Nama mata kuliah harus diisi');
      return;
    }
    if (code.isEmpty) {
      _showSnackbar('Kode mata kuliah harus diisi');
      return;
    }
    if (_selectedSemester == null) {
      _showSnackbar('Pilih semester');
      return;
    }

    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse(ApiConfig.courses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'code': code,
          'description': _descController.text.trim(),
          'semester': _selectedSemester,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _showSnackbar('Mata kuliah berhasil dibuat!');
        _nameController.clear();
        _codeController.clear();
        _descController.clear();
        setState(() => _selectedSemester = null);
        Navigator.pop(context);
        _fetchCourses();
      } else {
        _showSnackbar(data['message'] ?? 'Gagal membuat mata kuliah');
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    }
  }

  Future<void> _deleteCourse(int courseId, String courseName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mata Kuliah'),
        content: Text('Yakin ingin menghapus "$courseName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.courses}/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackbar('Mata kuliah berhasil dihapus');
        _fetchCourses();
      } else {
        _showSnackbar(data['message'] ?? 'Gagal menghapus mata kuliah');
      }
    } catch (e) {
      _showSnackbar('Error: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCreateSheet() {
    _nameController.clear();
    _codeController.clear();
    _descController.clear();
    setState(() => _selectedSemester = null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tambah Mata Kuliah',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Mata Kuliah *',
                  hintText: 'contoh: Pemrograman Web',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Kode Mata Kuliah *',
                  hintText: 'contoh: PWB101',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  hintText: 'Deskripsi singkat mata kuliah...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedSemester,
                hint: const Text('Pilih Semester *'),
                items: _semesters
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedSemester = v);
                  setSheetState(() => _selectedSemester = v);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createCourse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A5F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buat Mata Kuliah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (!_fabInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _fabInitialized = true;
                  if (_courses.isEmpty) {
                    _fabX = constraints.maxWidth / 2 - 28;
                    _fabY = constraints.maxHeight - 80;
                  } else {
                    _fabX = constraints.maxWidth - 72;
                    _fabY = constraints.maxHeight - 80;
                  }
                });
              }
            });
          }

          return Stack(
            children: [
              Column(
                children: [
                  // ========== HEADER MELENGKUNG (SAMA SEPERTI DASHBOARD) ==========
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
                          'Mata Kuliah',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _courses.isEmpty
                              ? 'Belum ada mata kuliah'
                              : '${_courses.length} mata kuliah',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daftar Mata Kuliah
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _fetchCourses,
                            child: _courses.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(
                                        height: constraints.maxHeight * 0.55,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.school_outlined,
                                              size: 80,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Belum ada mata kuliah',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tap tombol + untuk menambahkan',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _courses.length,
                                    itemBuilder: (context, index) {
                                      final course = _courses[index];
                                      final color = _getCourseColor(index);
                                      final initial =
                                          (course['name'] as String).isNotEmpty
                                          ? (course['name'] as String)[0]
                                                .toUpperCase()
                                          : '?';

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                          leading: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: color,
                                            child: Text(
                                              initial,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            course['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 2),
                                              Text(
                                                course['code'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFF3B82F6),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
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
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteCourse(
                                              course['id'],
                                              course['name'],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                  ),
                ],
              ),

              // Draggable FAB
              if (_fabInitialized)
                Positioned(
                  left: _fabX,
                  top: _fabY,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _fabX = (_fabX + details.delta.dx).clamp(
                          0,
                          constraints.maxWidth - 56,
                        );
                        _fabY = (_fabY + details.delta.dy).clamp(
                          0,
                          constraints.maxHeight - 56,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      final centerX = constraints.maxWidth / 2;
                      setState(() {
                        if (_fabX + 28 < centerX) {
                          _fabX = 16;
                        } else {
                          _fabX = constraints.maxWidth - 72;
                        }
                        _fabY = _fabY.clamp(60, constraints.maxHeight - 80);
                      });
                    },
                    onTap: _showCreateSheet,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A5F).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

