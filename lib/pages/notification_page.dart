import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "type": "upload",
        "title": "Catatan berhasil diupload",
        "message":
            "Workshop Administrasi Basis Data.pdf berhasil ditambahkan.",
        "time": "5 menit lalu",
      },
      {
        "type": "chatbot",
        "title": "AI telah menjawab pertanyaan",
        "message":
            "Ringkasan materi Kecerdasan Buatan berhasil dibuat.",
        "time": "20 menit lalu",
      },
      {
        "type": "noteplan",
        "title": "NotePlan berhasil dibuat",
        "message":
            "Study plan ujian Semester 4 telah dibuat otomatis.",
        "time": "1 jam lalu",
      },
      {
        "type": "noteplan",
        "title": "Jadwal belajar hari ini",
        "message":
            "Workshop Administrasi Basis Data - 90 menit.",
        "time": "Hari ini",
      },
    ];

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
      body: ListView.builder(
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

            case "chatbot":
              icon = Icons.smart_toy_rounded;
              color = Colors.purple;
              break;

            case "noteplan":
              icon = Icons.calendar_month_rounded;
              color = Colors.orange;
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
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        item["message"]!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        item["time"]!,
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
    );
  }
}