import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'analysis_result_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String _selectedMethod = 'upload';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _writeController = TextEditingController();
  String? _selectedSemester;
  
  String? _selectedFileName;
  int? _selectedFileSize;
  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isAnalyzing = false;

  final List<String> _semesters = [
    'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4',
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8'
  ];

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _analyzeAndNavigate() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Judul catatan harus diisi');
      return;
    }
    if (_selectedSemester == null) {
      _showSnackbar('Pilih semester');
      return;
    }
    
    setState(() => _isAnalyzing = true);
    
    // Simulasi analisis AI (2 detik)
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isAnalyzing = false);
    
    // Navigasi ke halaman hasil analisis
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultPage(
          title: _titleController.text.trim(),
          semester: _selectedSemester!,
          fileName: _selectedFileName,
          fileSize: _selectedFileSize,
          imagePath: _selectedImage?.path,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = result.files.first;
      if (file.size > 50 * 1024 * 1024) {
        _showSnackbar('File maksimal 50MB');
        return;
      }
      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
        _selectedMethod = 'upload';
        // Auto-fill judul dari nama file
        _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]*$'), '');
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > 50 * 1024 * 1024) {
        _showSnackbar('File gambar maksimal 50MB');
        return;
      }
      setState(() {
        _selectedImage = image;
        _selectedFileName = image.name;
        _selectedFileSize = size;
        _selectedMethod = 'kamera';
        _titleController.text = image.name.replaceAll(RegExp(r'\.[^.]*$'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header melengkung
          Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),  // ← lebih kecil
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
                'Upload Catatan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Bagikan catatan kuliahmu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
          // Form Upload
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildMethodCard(Icons.camera_alt, 'Kamera', 'kamera'),
                      const SizedBox(width: 12),
                      _buildMethodCard(Icons.edit_note, 'Tulis', 'tulis'),
                      const SizedBox(width: 12),
                      _buildMethodCard(Icons.upload_file, 'Upload', 'upload'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  if (_selectedMethod == 'upload')
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(_selectedFileName ?? 'Tap untuk pilih file'),
                            const SizedBox(height: 4),
                            Text('PDF, JPG, PNG (max 50MB)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_selectedMethod == 'kamera')
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(_selectedFileName ?? 'Tap untuk ambil foto'),
                            const SizedBox(height: 4),
                            Text('JPG, PNG (max 50MB)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_selectedMethod == 'tulis')
                    TextField(
                      controller: _writeController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Tulis catatanmu di sini...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Catatan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    hint: const Text('Pilih Semester'),
                    items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedSemester = v),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Analisis & Validasi', style: TextStyle(color: Colors.white)),
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

  Widget _buildMethodCard(IconData icon, String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedMethod == value ? const Color(0xFF1E3A5F) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: _selectedMethod == value ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: _selectedMethod == value ? Colors.white : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}