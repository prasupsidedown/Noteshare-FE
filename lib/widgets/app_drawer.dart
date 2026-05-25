import 'package:flutter/material.dart';
import 'package:noteshare_flutter/api.config.dart';
import 'package:noteshare_flutter/pages/dashboard_screen.dart';
import 'package:noteshare_flutter/pages/explore_page.dart';
import 'package:noteshare_flutter/pages/upload_page.dart';
import 'package:noteshare_flutter/semester_state.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _semesterExpanded = false;
  String _userName = '';
  String _userEmail = '';
  final _semesterState = SemesterState();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _semesterState.addListener(_onSemesterChanged);
  }

  @override
  void dispose() {
    _semesterState.removeListener(_onSemesterChanged);
    super.dispose();
  }

  void _onSemesterChanged() => setState(() {});

  Future<void> _loadUser() async {
    final data = await AuthStorage.getUserData();
    if (mounted) {
      setState(() {
        _userName = data['name'] ?? '';
        _userEmail = data['email'] ?? '';
      });
    }
  }

  void _navigate(Widget page) {
    Navigator.pop(context); // tutup drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToDashboard() {
    Navigator.pop(context); // tutup drawer
    // Pop semua route sampai tidak bisa lagi (kembali ke root/dashboard)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final semesters = _semesterState.semesters;

    return Drawer(
      width: 300,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          _DrawerHeader(name: _userName, email: _userEmail),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),

                // Dashboard
                _DrawerMenuItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  onTap: _navigateToDashboard,
                ),

                // Jelajahi / Explore
                _DrawerMenuItem(
                  icon: Icons.explore_outlined,
                  label: 'Jelajahi Catatan',
                  onTap: () => _navigate(const ExplorePage()),
                ),

                // Upload
                _DrawerMenuItem(
                  icon: Icons.upload_outlined,
                  label: 'Upload Catatan',
                  onTap: () => _navigate(const UploadPage()),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 24, color: Color(0xFFEEEEEE)),
                ),

                // Semester (expandable)
                _SemesterHeader(
                  isExpanded: _semesterExpanded,
                  count: semesters.length,
                  onTap: () =>
                      setState(() => _semesterExpanded = !_semesterExpanded),
                ),

                if (_semesterExpanded)
                  semesters.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Text(
                            'Belum ada semester.\nTambahkan dari Dashboard.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          itemCount: semesters.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _SemesterChip(item: semesters[i]),
                        ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Drawer Header ────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String email;
  const _DrawerHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B5FFF), Color(0xFFCB6FFF), Color(0xFFFF8FBF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF7B5FFF),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name.isNotEmpty ? name : 'Pengguna',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              email,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _DrawerMenuItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF7B5FFF)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Semester Header ──────────────────────────────────────────────────────────

class _SemesterHeader extends StatelessWidget {
  final bool isExpanded;
  final int count;
  final VoidCallback onTap;
  const _SemesterHeader({
    required this.isExpanded,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.school_outlined,
              size: 20,
              color: Color(0xFF7B5FFF),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Semester Saya',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B5FFF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B5FFF),
                  ),
                ),
              ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Semester Chip (compact) ──────────────────────────────────────────────────

class _SemesterChip extends StatelessWidget {
  final SemesterItem item;
  const _SemesterChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: item.color.withValues(alpha: 0.9),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            item.code,
            style: TextStyle(
              fontSize: 11,
              color: item.color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
