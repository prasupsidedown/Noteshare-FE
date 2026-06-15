import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:noteshare_flutter/api.config.dart';
import 'package:noteshare_flutter/widgets/app_drawer.dart';
import 'package:noteshare_flutter/pages/notification_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  bool _loading = true;
  // Map dari course name → list notes
  Map<String, List<Map<String, dynamic>>> _grouped = {};
Map<String, List<Map<String, dynamic>>> _filteredGrouped = {};

Set<int> _bookmarked = {};

String _searchQuery = '';

  // Warna cycle untuk course
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
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorage.getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/notes?limit=100'),
        
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List data = body['data'] ?? [];

        // Group by course name
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final note in data) {
          final courseName =
              note['course']?['name'] ?? note['semester'] ?? 'Umum';
          grouped.putIfAbsent(courseName, () => []);
          grouped[courseName]!.add(note);
        }
        setState(() {
  _grouped = grouped;
  _filteredGrouped = grouped;
});
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleBookmark(int noteId) {
    setState(() {
      if (_bookmarked.contains(noteId)) {
        _bookmarked.remove(noteId);
      } else {
        _bookmarked.add(noteId);
      }
    });
  }

  void _filterNotes(String query) {
  _searchQuery = query;

  if (query.trim().isEmpty) {
    setState(() {
      _filteredGrouped = Map.from(_grouped);
    });
    return;
  }

  final Map<String, List<Map<String, dynamic>>> filtered = {};

  _grouped.forEach((course, notes) {
    final results = notes.where((note) {
      final title =
          (note['title'] ?? '').toString().toLowerCase();

      final description =
          (note['description'] ?? '').toString().toLowerCase();

      return title.contains(query.toLowerCase()) ||
          description.contains(query.toLowerCase());
    }).toList();

    if (results.isNotEmpty) {
      filtered[course] = results;
    }
  });

  setState(() {
    _filteredGrouped = filtered;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF6F5FF),
      body: Column(
        children: [
          _ExploreHeader(
  scaffoldKey: _scaffoldKey,
  onSearch: _filterNotes,
),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B5FFF)),
                  )
                : RefreshIndicator(
                    color: const Color(0xFF7B5FFF),
                    onRefresh: _fetchNotes,
                    child: _filteredGrouped.isEmpty
                        ? _EmptyState()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: _filteredGrouped.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                                  final colorIdx =
                                      entry.key % _colorCycle.length;
                                  final courseName = entry.value.key;
                                  final notes = entry.value.value;
                                  return _CourseSection(
                                    courseName: courseName,
                                    color: _colorCycle[colorIdx],
                                    notes: notes,
                                    bookmarked: _bookmarked,
                                    onBookmark: _toggleBookmark,
                                  );
                                })
                                .toList(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ExploreHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Function(String) onSearch;

  const _ExploreHeader({
    required this.scaffoldKey,
    required this.onSearch,
  });

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

                Expanded(
                  child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'JELAJAHI CATATAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cari catatan kuliah yang kamu butuhkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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

            const SizedBox(height: 18),

            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
  onChanged: onSearch,
  decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cari catatan...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
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

// ─── Course Section ───────────────────────────────────────────────────────────

class _CourseSection extends StatefulWidget {
  final String courseName;
  final Color color;
  final List<Map<String, dynamic>> notes;
  final Set<int> bookmarked;
  final ValueChanged<int> onBookmark;

  const _CourseSection({
    required this.courseName,
    required this.color,
    required this.notes,
    required this.bookmarked,
    required this.onBookmark,
  });

  @override
  State<_CourseSection> createState() => _CourseSectionState();
}

class _CourseSectionState extends State<_CourseSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.courseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                      '${widget.notes.length} catatan',
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
                ],
              ),
            ),
          ),

          // Notes list
          if (_expanded)
            Column(
              children: widget.notes
                  .map(
                    (note) => _NoteCard(
                      note: note,
                      accentColor: widget.color,
                      isBookmarked: widget.bookmarked.contains(note['id']),
                      onBookmark: () => widget.onBookmark(note['id'] as int),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final Color accentColor;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  const _NoteCard({
    required this.note,
    required this.accentColor,
    required this.isBookmarked,
    required this.onBookmark,
  });

  IconData get _typeIcon {
    switch ((note['file_type'] ?? '').toString().toLowerCase()) {
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

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uploaderName =
        note['user']?['name'] ?? note['user']?['email'] ?? 'Anonim';

    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFF0F0F5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'oleh $uploaderName',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      _formatDate(note['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onBookmark,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border_outlined,
                    key: ValueKey(isBookmarked),
                    color: isBookmarked ? accentColor : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada catatan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          
        ],
      ),
    );
  }
}
