import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _writeController = TextEditingController();
  String? _selectedSemester;

  String? _selectedFileName;
  int? _selectedFileSize;
  String? _selectedFilePath;
  XFile? _selectedImage;
  bool _isProcessing = false;

  bool _showTitleError = false;
  bool _showSemesterError = false;
  bool _showFileError = false;

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

  final _titleKey = GlobalKey();
  final _fileKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _writeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _proceedToUpload() async {
    setState(() {
      _showTitleError = false;
      _showSemesterError = false;
      _showFileError = false;
    });

    bool hasError = false;

    if (_selectedMethod == 'tulis') {
      if (_writeController.text.trim().isEmpty) {
        setState(() => _showFileError = true);
        hasError = true;
      }
    } else {
      if (_selectedFilePath == null) {
        setState(() => _showFileError = true);
        hasError = true;
      }
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() => _showTitleError = true);
      hasError = true;
    }

    if (_selectedSemester == null) {
      setState(() => _showSemesterError = true);
      hasError = true;
    }

    if (hasError) {
      if (_showFileError) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        final msg = _selectedMethod == 'kamera'
            ? 'Pilih foto terlebih dahulu (tap area foto di atas)'
            : _selectedMethod == 'tulis'
            ? 'Tulis catatan terlebih dahulu'
            : 'Pilih file terlebih dahulu (tap area upload di atas)';
        _showSnackbar(msg, isError: true);
      } else if (_showTitleError) {
        _showSnackbar('Judul catatan harus diisi', isError: true);
      } else {
        _showSnackbar('Pilih semester terlebih dahulu', isError: true);
      }
      return;
    }

    setState(() => _isProcessing = true);

    String? finalFilePath = _selectedFilePath;
    String? finalFileName = _selectedFileName;
    int? finalFileSize = _selectedFileSize;

    if (_selectedMethod == 'tulis') {
      try {
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_note.txt',
        );
        await tempFile.writeAsString(_writeController.text.trim());
        finalFilePath = tempFile.path;
        finalFileName = '${_titleController.text.trim()}.txt';
        finalFileSize = await tempFile.length();
      } catch (e) {
        setState(() => _isProcessing = false);
        _showSnackbar('Gagal memproses teks: $e', isError: true);
        return;
      }
    }

    setState(() => _isProcessing = false);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultPage(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          semester: _selectedSemester!,
          fileName: finalFileName,
          fileSize: finalFileSize,
          imagePath: _selectedImage?.path,
          filePath: finalFilePath,
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      withReadStream: false,
    );
    if (result != null) {
      final file = result.files.first;
      if (file.path == null) {
        _showSnackbar('Gagal membaca file, coba lagi', isError: true);
        return;
      }
      if (file.size > 50 * 1024 * 1024) {
        _showSnackbar('File maksimal 50MB', isError: true);
        return;
      }
      setState(() {
        _selectedFileName = file.name;
        _selectedFileSize = file.size;
        _selectedFilePath = file.path;
        _selectedMethod = 'upload';
        _showFileError = false;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = file.name.replaceAll(RegExp(r'\.[^.]*$'), '');
          _showTitleError = false;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      final file = File(image.path);
      final size = await file.length();
      if (size > 50 * 1024 * 1024) {
        _showSnackbar('File gambar maksimal 50MB', isError: true);
        return;
      }
      setState(() {
        _selectedImage = image;
        _selectedFileName = image.name;
        _selectedFileSize = size;
        _selectedFilePath = image.path;
        _selectedMethod = 'kamera';
        _showFileError = false;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = image.name.replaceAll(
            RegExp(r'\.[^.]*$'),
            '',
          );
          _showTitleError = false;
        }
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String? fileName) {
    if (fileName == null) return Colors.grey;
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Catatan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bagikan catatan kuliahmu',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),

                  if (_selectedMethod == 'upload') ...[
                    if (_showFileError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih file terlebih dahulu',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      key: _fileKey,
                      onTap: _pickFile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _showFileError
                                ? Colors.red
                                : _selectedFilePath != null
                                ? const Color(0xFF1E3A5F)
                                : Colors.grey[300]!,
                            width: _showFileError || _selectedFilePath != null
                                ? 2
                                : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: _showFileError
                              ? Colors.red[50]
                              : _selectedFilePath != null
                              ? const Color(0xFF1E3A5F).withValues(alpha: 0.05)
                              : Colors.grey[50],
                        ),
                        child: _selectedFilePath != null
                            ? Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _getFileColor(
                                        _selectedFileName,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getFileIcon(_selectedFileName),
                                      color: _getFileColor(_selectedFileName),
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFileName ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1E3A5F),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedFileSize != null
                                              ? _formatFileSize(
                                                  _selectedFileSize!,
                                                )
                                              : '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF1E3A5F),
                                        size: 22,
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedFilePath = null;
                                          _selectedFileName = null;
                                          _selectedFileSize = null;
                                        }),
                                        child: Text(
                                          'Ganti',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 44,
                                    color: _showFileError
                                        ? Colors.red[300]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tap di sini untuk pilih file',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _showFileError
                                          ? Colors.red[700]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'PDF, DOC, PPT, JPG, PNG (maks 50MB)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  if (_selectedMethod == 'kamera') ...[
                    if (_showFileError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih foto terlebih dahulu',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _showFileError
                                ? Colors.red
                                : _selectedFilePath != null
                                ? const Color(0xFF1E3A5F)
                                : Colors.grey[300]!,
                            width: _showFileError || _selectedFilePath != null
                                ? 2
                                : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: _selectedFilePath != null
                              ? null
                              : _showFileError
                              ? Colors.red[50]
                              : Colors.grey[50],
                        ),
                        child: _selectedFilePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(_selectedFilePath!),
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedFilePath = null;
                                          _selectedFileName = null;
                                          _selectedFileSize = null;
                                          _selectedImage = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Text(
                                            'Ganti foto',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 44,
                                    color: _showFileError
                                        ? Colors.red[300]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap untuk ambil foto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _showFileError
                                          ? Colors.red[700]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'Kamera akan terbuka otomatis',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  if (_selectedMethod == 'tulis') ...[
                    if (_showFileError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Catatan tidak boleh kosong',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _writeController,
                      maxLines: 8,
                      onChanged: (_) {
                        if (_showFileError)
                          setState(() => _showFileError = false);
                      },
                      decoration: InputDecoration(
                        hintText: 'Tulis catatanmu di sini...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _showFileError
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: _showFileError
                                ? Colors.red
                                : Colors.grey[300]!,
                            width: _showFileError ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  TextField(
                    key: _titleKey,
                    controller: _titleController,
                    onChanged: (_) {
                      if (_showTitleError)
                        setState(() => _showTitleError = false);
                    },
                    decoration: InputDecoration(
                      labelText: 'Judul Catatan *',
                      labelStyle: TextStyle(
                        color: _showTitleError ? Colors.red : null,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _showTitleError
                              ? Colors.red
                              : Colors.grey[400]!,
                          width: _showTitleError ? 2 : 1,
                        ),
                      ),
                      errorText: _showTitleError ? 'Judul harus diisi' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                      hintText: 'Ringkasan singkat isi catatan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedSemester,
                    hint: Text(
                      'Pilih Semester *',
                      style: TextStyle(
                        color: _showSemesterError ? Colors.red : null,
                      ),
                    ),
                    items: _semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedSemester = v;
                      _showSemesterError = false;
                    }),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _showSemesterError
                              ? Colors.red
                              : Colors.grey[400]!,
                          width: _showSemesterError ? 2 : 1,
                        ),
                      ),
                      errorText: _showSemesterError
                          ? 'Semester harus dipilih'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _proceedToUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Analisis & Validasi',
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(IconData icon, String label, String value) {
    final isSelected = _selectedMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMethod = value;
          _selectedFilePath = null;
          _selectedFileName = null;
          _selectedFileSize = null;
          _selectedImage = null;
          _showFileError = false;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? null : Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
