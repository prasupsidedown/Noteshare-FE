import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api.config.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> notifList = [];

      // ================= NOTES =================
      final notesResponse = await http.get(
        Uri.parse(ApiConfig.myNotes),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (notesResponse.statusCode == 200) {
        final data = jsonDecode(notesResponse.body);
        final List notes = data['data'] ?? [];

        for (var note in notes) {
          notifList.add({
            "type": "upload",
            "title": "Catatan berhasil ditambahkan",
            "message":
                note['title'] ?? note['fileName'] ?? 'Catatan baru',
            "time": "Baru saja",
          });
        }
      }

      // ================= COURSES =================
      final coursesResponse = await http.get(
        Uri.parse(ApiConfig.courses),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (coursesResponse.statusCode == 200) {
        final data = jsonDecode(coursesResponse.body);
        final List courses = data['data'] ?? [];

        for (var course in courses) {
          notifList.add({
            "type": "course",
            "title": "Mata kuliah tersedia",
            "message": course['name'] ?? '',
            "time": "Hari ini",
          });
        }
      }

      setState(() {
        notifications = notifList.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Notification error: $e');

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          "Notifikasi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : notifications.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 220),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 70,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Belum ada notifikasi",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];

                      IconData icon;
                      Color color;

                      switch (item["type"]) {
                        case "upload":
                          icon = Icons.upload_file_rounded;
                          color = Colors.blue;
                          break;

                        case "course":
                          icon = Icons.school_rounded;
                          color = Colors.green;
                          break;

                        default:
                          icon = Icons.notifications;
                          color = Colors.grey;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  color.withOpacity(0.15),
                              child: Icon(
                                icon,
                                color: color,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["title"] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    item["message"] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    item["time"] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}