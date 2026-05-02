import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  
  String? _selectedSemester;
  bool _isLoading = true;

  final List<String> _semesters = [
    'Semua', 'Semester 1', 'Semester 2', 'Semester 3', 'Semester 4',
    'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await supabase
          .from('notes')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _allNotes = List<Map<String, dynamic>>.from(response);
        _filteredNotes = _allNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        final title = note['title']?.toLowerCase() ?? '';
        final matchesSearch = query.isEmpty || title.contains(query);
        bool matchesSemester = true;
        if (_selectedSemester != null && _selectedSemester != 'Semua') {
          matchesSemester = note['semester'] == _selectedSemester;
        }
        return matchesSearch && matchesSemester;
      }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Semester'),
        content: DropdownButton<String>(
          value: _selectedSemester ?? 'Semua',
          isExpanded: true,
          items: _semesters.map((semester) {
            return DropdownMenuItem(value: semester, child: Text(semester));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedSemester = value);
            Navigator.pop(context);
            _applyFilters();
          },
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} minggu lalu';
      if (diff.inDays >= 1) return '${diff.inDays} hari lalu';
      if (diff.inHours >= 1) return '${diff.inHours} jam lalu';
      if (diff.inMinutes >= 1) return '${diff.inMinutes} menit lalu';
      return 'baru saja';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header melengkung dengan search di dalamnya
            Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),  // ← lebih kecil
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
                  'Cari Catatan',
                  style: TextStyle(
                    fontSize: 24,  // ← perkecil
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Temukan catatan kuliahmu',
                  style: TextStyle(
                    fontSize: 12,  // ← perkecil
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                // search bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,  // ← tinggi search bar
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText: 'Cari catatan...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A5F)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.filter_list, color: Color(0xFF1E3A5F)),
                              onPressed: _showFilterDialog,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Hasil Pencarian
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedSemester != null && _selectedSemester != 'Semua')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Filter: $_selectedSemester', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedSemester = 'Semua');
                              _applyFilters();
                            },
                            child: const Icon(Icons.close, size: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Hasil Pencarian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text('${_filteredNotes.length} catatan', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredNotes.isEmpty
                            ? const Center(child: Text('Tidak ada catatan ditemukan'))
                            : ListView.builder(
                                itemCount: _filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = _filteredNotes[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note['title'] ?? 'Tanpa judul',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Terverifikasi',
                                                style: TextStyle(fontSize: 10, color: Colors.green),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              note['semester'] ?? 'Semester 1',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(note['created_at']),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
}