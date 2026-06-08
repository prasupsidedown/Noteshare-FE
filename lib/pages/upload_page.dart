import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:noteshare_flutter/api.config.dart';
import 'package:noteshare_flutter/semester_state.dart';
import 'package:noteshare_flutter/widgets/app_drawer.dart';
import 'package:noteshare_flutter/pages/notification_page.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _selectedTab = 0; // 0=Kamera, 1=Tulis, 2=Upload

  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _tulisController = TextEditingController();

  SemesterItem? _selectedSemester;
  bool _semesterExpanded = false;
  bool _isLoading = false;

  File? _capturedImage;
  PlatformFile? _pickedFile;

  final _semesterState = SemesterState();

  @override
  void initState() {
    super.initState();
    _semesterState.addListener(_onSemesterChanged);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _tulisController.dispose();
    _semesterState.removeListener(_onSemesterChanged);
    super.dispose();
  }

  void _onSemesterChanged() {
    // Reset jika semester yang dipilih dihapus
    if (_selectedSemester != null) {
      final stillExists = _semesterState.semesters.any(
        (s) => s.id == _selectedSemester!.id,
      );
      if (!stillExists) setState(() => _selectedSemester = null);
    } else {
      setState(() {});
    }
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) setState(() => _capturedImage = File(photo.path));
  }

  Future<void> _openFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'jpg',
        'jpeg',
        'png',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _onTabChanged(int i) => setState(() => _selectedTab = i);

  /// Upload ke backend Go: POST /api/v1/notes (multipart/form-data)
  Future<void> _handleUpload() async {
    final judul = _judulController.text.trim();

    if (judul.isEmpty) {
      _showSnack('Isi Judul Catatan terlebih dahulu');
      return;
    }
    if (_selectedSemester == null) {
      _showSnack('Pilih Semester terlebih dahulu');
      return;
    }

    // Tentukan file yang akan diupload
    File? fileToUpload;
    String? fileName;

    if (_selectedTab == 0 && _capturedImage != null) {
      fileToUpload = _capturedImage;
      fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    } else if (_selectedTab == 1 && _tulisController.text.trim().isNotEmpty) {
      // Simpan teks sebagai file .txt sementara
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/note_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await tempFile.writeAsString(_tulisController.text.trim());
      fileToUpload = tempFile;
      fileName = 'catatan_${DateTime.now().millisecondsSinceEpoch}.txt';
    } else if (_selectedTab == 2 && _pickedFile != null) {
      fileToUpload = File(_pickedFile!.path!);
      fileName = _pickedFile!.name;
    }

    if (fileToUpload == null) {
      _showSnack('Tambahkan konten terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await AuthStorage.getToken();
      final mimeType =
          lookupMimeType(fileToUpload.path) ?? 'application/octet-stream';
      final mimeParts = mimeType.split('/');

      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.notes));
      request.headers['Authorization'] = 'Bearer $token';

      // Field sesuai CreateNoteRequest di backend
      request.fields['title'] = judul;
      request.fields['description'] = _deskripsiController.text.trim();
      request.fields['course_id'] = _selectedSemester!.id.toString();
      request.fields['semester'] = _selectedSemester!.name;
      request.fields['is_public'] = 'true';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          fileToUpload.path,
          filename: fileName,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 201) {
        // Tambah note ke SemesterState lokal supaya dashboard langsung update
        // (tanpa perlu refresh dari server)
        // ignore: avoid_dynamic_calls
        // final body = jsonDecode(res.body);
        // final noteData = body['data'];
        // _semesterState.addNote(_selectedSemester!.id, NoteItem.fromJson(noteData));

        _showSnack(
          'Catatan berhasil diupload ke ${_selectedSemester!.name}!',
          isSuccess: true,
        );
        _resetForm();
      } else {
        _showSnack('Upload gagal. Coba lagi.');
      }
    } on SocketException {
      _showSnack('Tidak ada koneksi internet.');
    } catch (e) {
      _showSnack('Terjadi error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _judulController.clear();
    _deskripsiController.clear();
    _tulisController.clear();
    setState(() {
      _capturedImage = null;
      _pickedFile = null;
      _selectedSemester = null;
      _selectedTab = 0;
      _semesterExpanded = false;
    });
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? const Color(0xFF4CAF50)
            : const Color(0xFF7B5FFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _UploadHeader(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semester Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Kelola mata kuliah dan catatan per semester',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7B5FFF)),
                  ),
                  const SizedBox(height: 20),

                  _TabBar(selected: _selectedTab, onChanged: _onTabChanged),
                  const SizedBox(height: 20),

                  _buildContentArea(),
                  const SizedBox(height: 16),

                  _InputField(
                    controller: _judulController,
                    hint: 'Judul Catatan *',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: _deskripsiController,
                    hint: 'Deskripsi (Opsional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Semester dropdown dari SemesterState (data real dari backend)
                  ListenableBuilder(
                    listenable: _semesterState,
                    builder: (context, _) {
                      final semesters = _semesterState.semesters;
                      if (semesters.isEmpty) return _EmptySemesterHint();
                      return _SemesterPicker(
                        selected: _selectedSemester,
                        items: semesters,
                        isExpanded: _semesterExpanded,
                        onToggle: () => setState(
                          () => _semesterExpanded = !_semesterExpanded,
                        ),
                        onSelect: (val) => setState(() {
                          _selectedSemester = val;
                          _semesterExpanded = false;
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomBar(onTap: _handleUpload, isLoading: _isLoading),
      floatingActionButton: _FloatingChat(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContentArea() {
    switch (_selectedTab) {
      case 0:
        return _buildKameraArea();
      case 1:
        return _buildTulisArea();
      case 2:
        return _buildUploadArea();
      default:
        return const SizedBox();
    }
  }

  Widget _buildKameraArea() {
    if (_capturedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _capturedImage!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _capturedImage = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _openCamera,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B5FFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ambil ulang',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _EmptyPreview(
      icon: Icons.add_photo_alternate_outlined,
      label: 'Tap untuk ambil foto',
      sublabel: 'Kamera akan terbuka otomatis',
      onTap: _openCamera,
    );
  }

  Widget _buildTulisArea() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7B5FFF), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: TextField(
        controller: _tulisController,
        maxLines: null,
        minLines: 6,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1A1A2E),
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: 'Tulis catatan kuliahmu di sini...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    if (_pickedFile != null) {
      final isImage = [
        'jpg',
        'jpeg',
        'png',
      ].contains(_pickedFile!.extension?.toLowerCase());
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF7B5FFF), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7B5FFF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isImage ? Icons.image_outlined : Icons.picture_as_pdf,
                color: const Color(0xFF7B5FFF),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFile!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _pickedFile!.size > 0
                        ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                        : 'File dipilih',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _pickedFile = null),
              child: const Icon(Icons.close, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return _EmptyPreview(
      icon: Icons.upload_file_outlined,
      label: 'Tap disini untuk pilih file',
      sublabel: 'PDF, DOC, PPT, JPG, PNG (Maks 50 Mb)',
      onTap: _openFilePicker,
    );
  }
}

// ─── Empty Semester Hint ──────────────────────────────────────────────────────

class _EmptySemesterHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF9800), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum ada semester. Buat semester dulu di Dashboard.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Semester Picker ──────────────────────────────────────────────────────────

class _SemesterPicker extends StatelessWidget {
  final SemesterItem? selected;
  final List<SemesterItem> items;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<SemesterItem> onSelect;

  const _SemesterPicker({
    required this.selected,
    required this.items,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7B5FFF), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected?.name ?? 'Pilih Semester *',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? const Color(0xFF1A1A2E)
                        : Colors.grey.shade400,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: const Color(0xFF1A1A2E),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7B5FFF), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    'Pilih Semester',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ...items.map((s) {
                  final isSel = s.id == selected?.id;
                  return InkWell(
                    onTap: () => onSelect(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFF7B5FFF).withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSel
                                  ? const Color(0xFF7B5FFF)
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Empty Preview ────────────────────────────────────────────────────────────

class _EmptyPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _EmptyPreview({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCCCCE8), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _UploadHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _UploadHeader({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B5FFF), Color.fromARGB(255, 98, 175, 252)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                  onTap: () => scaffoldKey.currentState?.openDrawer(),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'UPLOAD CATATAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bagikan catatan kuliahmu',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Color.fromARGB(255, 98, 98, 99),
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(double w) => Container(
    width: w,
    height: 2.5,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _TabBar({required this.selected, required this.onChanged});

  static const _tabs = [
    {'icon': Icons.camera_alt_outlined, 'label': 'Kamera'},
    {'icon': Icons.edit_outlined, 'label': 'Tulis'},
    {'icon': Icons.upload_outlined, 'label': 'Upload'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_tabs.length, (i) {
        final sel = i == selected;
        return Padding(
          padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 12 : 0),
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: sel ? 88 : 80,
              height: sel ? 88 : 80,
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7B5FFF),
                          Color.fromARGB(255, 98, 175, 252),
                        ],
                      )
                    : null,
                color: sel ? null : const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color: sel
                        ? const Color(0xFF7B5FFF).withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tabs[i]['icon'] as IconData,
                    color: sel ? Colors.white : const Color(0xFF9E9E9E),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tabs[i]['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _InputField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B5FFF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B5FFF), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _BottomBar({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: isLoading
                ? [const Color(0xFFAAAAAA), const Color(0xFFBBBBBB)]
                : [const Color(0xFF5B4FCF), const Color(0xFF7B5FFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B5FFF).withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Upload Catatan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Floating Chat ────────────────────────────────────────────────────────────

class _FloatingChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF7B5FFF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B5FFF).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
