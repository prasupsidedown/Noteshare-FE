import 'package:flutter/material.dart';

class NotePlanPage extends StatefulWidget {
  const NotePlanPage({super.key});

  @override
  State<NotePlanPage> createState() => _NotePlanPageState();
}

class _NotePlanPageState extends State<NotePlanPage> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      "text":
          "Halo 👋 Saya NotePlan AI.\n\nSaya dapat membantu:\n\n• Membuat Study Plan\n• Menyusun Jadwal Belajar\n• Memberikan Tips Ujian\n• Mengatur Prioritas Tugas\n• Memberikan Saran Belajar Berdasarkan Catatan",
      "isUser": false,
    }
  ];

  void _sendMessage() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
      });

      _messages.add({
        "text": "⌛ Sedang menganalisis...",
        "isUser": false,
      });
    });

    _controller.clear();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      String reply;
      final msg = text.toLowerCase();

      if (msg.contains("halo") ||
          msg.contains("hai") ||
          msg.contains("hallo")) {
        reply =
            "Halo 👋 Saya NotePlan AI. Saya siap membantu membuat rencana belajar berdasarkan catatan yang kamu miliki.";
      } else if (msg.contains("study plan") ||
          msg.contains("rencana belajar")) {
        reply = """
📚 Study Plan 7 Hari

Hari 1 : Membaca materi utama
Hari 2 : Membuat rangkuman
Hari 3 : Latihan soal
Hari 4 : Review catatan
Hari 5 : Fokus materi sulit
Hari 6 : Simulasi ujian
Hari 7 : Evaluasi hasil belajar
""";
      } else if (msg.contains("ujian")) {
        reply =
            "📖 Menjelang ujian, saya menyarankan belajar minimal 2 jam per hari dan fokus pada materi yang paling sering muncul.";
      } else if (msg.contains("workshop")) {
        reply =
            "🛠 Workshop terdeteksi sebagai materi prioritas. Fokus pada praktik dan studi kasus.";
      } else if (msg.contains("basis data")) {
        reply =
            "🗄 Untuk Basis Data, fokus pada SQL, ERD, Normalisasi, Primary Key dan Foreign Key.";
      } else if (msg.contains("algoritma")) {
        reply =
            "💻 Untuk Algoritma, fokus pada Flowchart, Pseudocode, Sorting dan Searching.";
      } else if (msg.contains("pemrograman")) {
        reply =
            "👨‍💻 Untuk Pemrograman, saya sarankan latihan coding setiap hari.";
      } else if (msg.contains("nilai")) {
        reply =
            "📈 Untuk meningkatkan nilai, fokus pada latihan soal dan review catatan secara rutin.";
      } else if (msg.contains("ipk")) {
        reply =
            "🏆 Untuk meningkatkan IPK, prioritaskan mata kuliah inti dan buat jadwal belajar yang konsisten.";
      } else if (msg.contains("skripsi")) {
        reply =
            "📚 Saya sarankan membuat timeline skripsi mulai dari referensi hingga penulisan laporan.";
      } else if (msg.contains("tugas")) {
        reply =
            "✅ Prioritaskan tugas yang memiliki deadline terdekat dan pecah menjadi target harian.";
      } else {
        reply =
            "🤖 Saya memahami pertanyaanmu tentang \"$text\".\n\nSaya menyarankan membuat jadwal belajar yang teratur dan melakukan evaluasi belajar secara berkala.";
      }

      setState(() {
        _messages.removeLast();

        _messages.add({
          "text": reply,
          "isUser": false,
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 16,
              right: 16,
              bottom: 14,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6DAEFF),
                  Color(0xFFD07CFF),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                const Text(
                  "NotePlan AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                // QUICK ACTION
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text("Study Plan"),
                        onPressed: () {
                          _controller.text = "Buat study plan ujian";
                          _sendMessage();
                        },
                      ),
                      ActionChip(
                        label: const Text("Tips Ujian"),
                        onPressed: () {
                          _controller.text = "Tips menghadapi ujian";
                          _sendMessage();
                        },
                      ),
                      ActionChip(
                        label: const Text("Atur Tugas"),
                        onPressed: () {
                          _controller.text = "Cara mengatur tugas";
                          _sendMessage();
                        },
                      ),
                      ActionChip(
                        label: const Text("Tingkatkan IPK"),
                        onPressed: () {
                          _controller.text = "Cara meningkatkan IPK";
                          _sendMessage();
                        },
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      return Align(
                        alignment: msg["isUser"]
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg["isUser"]
                                ? const Color(0xFFD678FF)
                                : const Color(0xFFEEDBFF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg["text"],
                            style: TextStyle(
                              color: msg["isUser"]
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ketik pesan...",
                      filled: true,
                      fillColor: const Color(0xFFF4E8FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A5CFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}