import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteshare_flutter/api.config.dart';
import 'package:noteshare_flutter/semester_state.dart';
import 'package:noteshare_flutter/widgets/app_drawer.dart';
import 'package:noteshare_flutter/pages/notification_page.dart';
import 'package:noteshare_flutter/pages/semester_detail_page.dart';
import 'package:noteshare_flutter/pages/note_plan_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _userName = '';
  bool _loading = true;
  final _semesterState = SemesterState();

  static const _colorCycle = [
    Color(0xFF6EC6F5),
    Color(0xFFB06EF5),
    Color(0xFFF5826E),
    Color(0xFFF5C26E),
    Color(0xFF6EF5A0),
    Color(0xFFF56EC6),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _semesterState.addListener(_onChanged);
    if (!_semesterState.loaded) _fetchSemesters();
  }

  @override
  void dispose() {
    _semesterState.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _loadUser() async {
    final data = await AuthStorage.getUserData();
    if (mounted) setState(() => _userName = data['name'] ?? '');
  }

  Future<void> _fetchSemesters() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorage.getToken();

      final res = await http.get(
        Uri.parse(ApiConfig.courses),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) return;

      final List data = jsonDecode(res.body)['data'] ?? [];

      final items = await Future.wait(
        data.asMap().entries.map((entry) async {
          final i = entry.key;
          final c = entry.value;

          final notesRes = await http.get(
            Uri.parse('${ApiConfig.myNotes}?course_id=${c['id']}&limit=100'),
            headers: {'Authorization': 'Bearer $token'},
          );

          List<NoteItem> notes = [];
          if (notesRes.statusCode == 200) {
            final List notesData = jsonDecode(notesRes.body)['data'] ?? [];
            notes = notesData.map((n) => NoteItem.fromJson(n)).toList();
          }

          return SemesterItem(
            id: c['id'],
            name: c['name'],
            code: c['code'],
            color: _colorCycle[i % _colorCycle.length],
            notes: notes,
          );
        }),
      );

      _semesterState.setAll(items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addSemester() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final codeController = TextEditingController();
        String? selectedColorKey;
        bool saving = false;

        final colors = {
          'Biru': const Color(0xFF6EC6F5),
          'Ungu': const Color(0xFFB06EF5),
          'Merah': const Color(0xFFF5826E),
          'Kuning': const Color(0xFFF5C26E),
        };

        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Tambah Semester',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nama Semester (Semester 4)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Kode (SMT4)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pilih Warna',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colors.entries.map((e) {
                    final isSelected = selectedColorKey == e.key;
                    return GestureDetector(
                      onTap: () => setDialog(() => selectedColorKey = e.key),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: e.value,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5FFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final code = codeController.text.trim();
                        if (name.isEmpty || code.isEmpty) return;
                        setDialog(() => saving = true);

                        try {
                          final token = await AuthStorage.getToken();
                          final res = await http.post(
                            Uri.parse(ApiConfig.courses),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                            body: jsonEncode({
                              'name': name,
                              'code': code,
                              'semester': name,
                            }),
                          );
                          if (res.statusCode == 201) {
                            final body = jsonDecode(res.body);
                            final c = body['data'];
                            final color = selectedColorKey != null
                                ? colors[selectedColorKey]!
                                : _colorCycle[_semesterState.semesters.length %
                                      _colorCycle.length];
                            _semesterState.add(
                              SemesterItem(
                                id: c['id'],
                                name: c['name'],
                                code: c['code'],
                                color: color,
                              ),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } else {
                            setDialog(() => saving = false);
                          }
                        } catch (_) {
                          setDialog(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tambah'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteSemester(SemesterItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semester?'),
        content: Text(
          'Semester "${item.name}" dan semua catatannya akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final token = await AuthStorage.getToken();
      final res = await http.delete(
        Uri.parse(ApiConfig.courseById(item.id)),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _semesterState.removeById(item.id);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final semesters = _semesterState.semesters;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _DashboardHeader(scaffoldKey: _scaffoldKey, userName: _userName),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B5FFF)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF7B5FFF),
                    onRefresh: _fetchSemesters,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      children: [
                        const Text(
                          'Semester Saya',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kelola mata kuliah dan catatan per semester',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B5FFF),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (semesters.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 56,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada semester',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap tombol + untuk menambahkan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _AddButton(onTap: _addSemester),
                                ],
                              ),
                            ),
                          )
                        else
                          ...semesters.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _SemesterCard(
                                item: item,
                                onDelete: () => _deleteSemester(item),
                              ),
                            ),
                          ),

                        if (semesters.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AddButton(onTap: _addSemester),
                            ),
                          ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
          ),
          _BottomBanner(),
        ],
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF7B5FFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B5FFF).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ─── Dashboard Header ─────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String userName;
  const _DashboardHeader({required this.scaffoldKey, required this.userName});

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
                children: [
                  GestureDetector(
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          ('DASHBOARD'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          userName.isNotEmpty ? 'Halo, $userName!' : 'Halo!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
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

// ─── Semester Card ────────────────────────────────────────────────────────────

class _SemesterCard extends StatefulWidget {
  final SemesterItem item;
  final VoidCallback onDelete;

  const _SemesterCard({
    required this.item,
    required this.onDelete,
    
  });

  @override
  State<_SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends State<_SemesterCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final notes = widget.item.notes;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.item.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.item.color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.item.color,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.item.code,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notes.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${notes.length} catatan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded)
            notes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Text(
                      'Belum ada catatan.\nUpload catatan dan pilih semester ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: notes
                        .map(
                          (note) => _NoteRow(
                            note: note,
                            accentColor: widget.item.color,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SemesterDetailPage(
                                    semesterName: note.title,
                                    semesterNumber: 0,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
        ],
      ),
    );
  }
}

// ─── Note Row ─────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final NoteItem note;
  final Color accentColor;
  final VoidCallback onTap;
  const _NoteRow({
    required this.note,
    required this.accentColor,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (note.fileType.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFF0F0F5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: accentColor),

                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (note.description != null &&
                          note.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            note.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: accentColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Bottom Banner ────────────────────────────────────────────────────────────

class _BottomBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotePlanPage(),
        ),
      );
    },
  child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0C0FF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE5D8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF7B5FFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'NotePlan siap bantu rencana belajarmu',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A3F7A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF7B5FFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
  ),
    );
  }
}
