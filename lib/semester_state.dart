import 'package:flutter/material.dart';

// ─── Model: Note ──────────────────────────────────────────────────────────────

class NoteItem {
  final int id;
  final String title;
  final String? description;
  final String fileUrl;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;

  const NoteItem({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: json['id'],
    title: json['title'] ?? '',
    description: json['description'],
    fileUrl: json['file_url'] ?? '',
    fileName: json['file_name'] ?? '',
    fileType: json['file_type'] ?? '',
    uploadedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
  );
}

// ─── Model: Semester (= Course di DB) ────────────────────────────────────────

class SemesterItem {
  final int id; // course_id di DB
  final String name; // course name
  final String code; // course code
  final Color color;
  final List<NoteItem> notes;

  SemesterItem({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    List<NoteItem>? notes,
  }) : notes = notes ?? [];

  SemesterItem copyWith({List<NoteItem>? notes, Color? color}) {
    return SemesterItem(
      id: id,
      name: name,
      code: code,
      color: color ?? this.color,
      notes: notes ?? this.notes,
    );
  }
}

// ─── Global State (ChangeNotifier) ────────────────────────────────────────────

class SemesterState extends ChangeNotifier {
  static final SemesterState _instance = SemesterState._internal();
  factory SemesterState() => _instance;
  SemesterState._internal();

  final List<SemesterItem> _semesters = [];
  bool _loaded = false;

  List<SemesterItem> get semesters => List.unmodifiable(_semesters);
  bool get loaded => _loaded;

  void setAll(List<SemesterItem> items) {
    _semesters
      ..clear()
      ..addAll(items);
    _loaded = true;
    notifyListeners();
  }

  void add(SemesterItem item) {
    _semesters.add(item);
    notifyListeners();
  }

  void removeById(int id) {
    _semesters.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void addNote(int semesterId, NoteItem note) {
    final idx = _semesters.indexWhere((s) => s.id == semesterId);
    if (idx == -1) return;
    final updated = _semesters[idx].copyWith(
      notes: [..._semesters[idx].notes, note],
    );
    _semesters[idx] = updated;
    notifyListeners();
  }

  void removeNote(int semesterId, int noteId) {
    final idx = _semesters.indexWhere((s) => s.id == semesterId);
    if (idx == -1) return;
    final newNotes = _semesters[idx].notes
        .where((n) => n.id != noteId)
        .toList();
    _semesters[idx] = _semesters[idx].copyWith(notes: newNotes);
    notifyListeners();
  }

  void clear() {
    _semesters.clear();
    _loaded = false;
    notifyListeners();
  }
}
