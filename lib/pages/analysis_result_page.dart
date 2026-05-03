import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';

class AnalysisResultPage extends StatefulWidget {
  final String title;
  final String description;
  final String semester;
  final String? fileName;
  final int? fileSize;
  final String? imagePath;
  final String? filePath;

  const AnalysisResultPage({
    super.key,
    required this.title,
    this.description = '',
    required this.semester,
    this.fileName,
    this.fileSize,
    this.imagePath,
    this.filePath,
  });

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _isSaving = false;
  bool _isSaved = false;

  List<Map<String, dynamic>> _courses = [];
  int? _selectedCourseId;
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
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
        setState(() {
          _courses = List<Map<String, dynamic>>.from(courses);
          _isLoadingCourses = false;
          if (_courses.length == 1) {
            _selectedCourseId = _courses[0]['id'];
          }
        });
      } else {
        setState(() => _isLoadingCourses = false);
      }
    } catch (e) {
      debugPrint('Fetch courses error: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _saveNote() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    final filePath = widget.filePath ?? widget.imagePath;
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada file untuk diupload')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = await AuthStorage.getToken();
      if (token == null) return;

      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.notes));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = widget.title;
      request.fields['description'] = widget.description;
      request.fields['semester'] = widget.semester;
      request.fields['course_id'] = _selectedCourseId.toString();
      request.fields['is_public'] = 'true';

      final file = File(filePath);
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan berhasil disimpan!')),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
          });
        }
      } else {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Gagal menyimpan catatan'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Save note error: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfirmasi Upload',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Periksa detail sebelum menyimpan',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Konten
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF1E3A5F)),
                            SizedBox(width: 8),
                            Text(
                              'Detail Catatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildInfoRow('Judul', widget.title),
                        if (widget.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Deskripsi', widget.description),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow('Semester', widget.semester),
                        if (widget.fileName != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('File', widget.fileName!),
                        ],
                        if (widget.fileSize != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Ukuran',
                            _formatFileSize(widget.fileSize!),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow('Visibilitas', 'Publik 🌐'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pilih Mata Kuliah
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Mata Kuliah *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingCourses
                            ? const Center(child: CircularProgressIndicator())
                            : _courses.isEmpty
                            ? const Text(
                                'Belum ada mata kuliah. Buat dulu di menu Courses.',
                                style: TextStyle(color: Colors.red),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedCourseId,
                                hint: const Text('Pilih mata kuliah'),
                                items: _courses.map((course) {
                                  return DropdownMenuItem<int>(
                                    value: course['id'],
                                    child: Text(
                                      '${course['name']} (${course['code']})',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCourseId = v),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaved || _isSaving || _courses.isEmpty
                          ? null
                          : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : _isSaved
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Tersimpan!',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Simpan Catatan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}