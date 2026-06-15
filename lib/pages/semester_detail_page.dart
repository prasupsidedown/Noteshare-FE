import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api.config.dart';

class SemesterDetailPage extends StatefulWidget {
  final String semesterName;
  final int semesterNumber;

  const SemesterDetailPage({
    super.key,
    required this.semesterName,
    required this.semesterNumber,
  });

  @override
  State<SemesterDetailPage> createState() => _SemesterDetailPageState();
}

class _SemesterDetailPageState extends State<SemesterDetailPage> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCoursesBySemester();
  }

  Future<void> _fetchCoursesBySemester() async {
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
        final List<dynamic> allCourses = data['data'] ?? [];

        // Filter berdasarkan semester yang dipilih
        final filteredCourses = allCourses.where((course) {
          return course['semester'] == widget.semesterName;
        }).toList();

        // Fetch my notes
        final notesResponse = await http.get(
          Uri.parse(ApiConfig.myNotes),
          headers: {
            'Authorization': 'Bearer $token',
            'ngrok-skip-browser-warning': 'true',
          },
        );

        setState(() {
          _notes = List<Map<String, dynamic>>.from(filteredCourses);
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
      appBar: AppBar(
        title: Text(widget.semesterName),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCoursesBySemester,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 80,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.semesterName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Detail catatan akan ditampilkan di sini',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final color = _getCourseColor(index);
                  final initial = (note['name'] as String).isNotEmpty
                      ? (note['name'] as String)[0].toUpperCase()
                      : '?';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(Icons.circle, size: 10, color: color),
                      title: Text(
                        note['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            note['code'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          if (note['description'] != null &&
                              note['description'].isNotEmpty)
                            Text(
                              note['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(note['title'] ?? ''),
                          content: Text(
                            note['description'] ??
                                'Tidak ada isi catatan',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
