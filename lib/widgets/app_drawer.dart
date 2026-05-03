import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/dashboard_page.dart';
import '../pages/search_page.dart';
import '../pages/upload_page.dart';
import '../pages/profile_page.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'User';
    final userName = userEmail.split('@').first;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // ========== HEADER DRAWER (DIPERBAIKI: GRADIENT + MELENGKUNG) ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30), // ← padding disesuaikan
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),   // ← melengkung
                  bottomRight: Radius.circular(25),  // ← melengkung
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Menu Items
            _buildDrawerItem(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              index: 0,
              isSelected: currentIndex == 0,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.search,
              title: 'Cari Catatan',
              index: 1,
              isSelected: currentIndex == 1,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.upload_file,
              title: 'Upload Catatan',
              index: 2,
              isSelected: currentIndex == 2,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'Profil',
              index: 3,
              isSelected: currentIndex == 3,
            ),
            const Spacer(),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E3A5F) : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        onItemSelected(index);
        Navigator.pop(context);
      },
    );
  }
}