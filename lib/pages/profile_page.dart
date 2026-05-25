import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("Profil"),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar + Nama + Email
            Column(
              children: const [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    "S",
                    style: TextStyle(fontSize: 32, color: Colors.purple),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Siti Romzatul Alimah",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "sasaromza636@gmail.com",
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  "Mahasiswa Aktif",
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ringkasan Aktivitas
            const Text(
              "Ringkasan Aktivitas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryBox("0 Catatan"),
                _buildSummaryBox("0 Semester"),
              ],
            ),
            const SizedBox(height: 20),

            // Menu Catatan Saya
            _buildMenuItem(Icons.note, "Catatan Saya", "0"),
            _buildMenuItem(Icons.favorite, "Catatan Favorit", "0"),
            _buildMenuItem(Icons.settings, "Pengaturan", ""),
            const SizedBox(height: 20),

            // Logout Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.chat),
      ),
    );
  }

  static Widget _buildSummaryBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  static Widget _buildMenuItem(IconData icon, String title, String count) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(count),
      ),
    );
  }
}
