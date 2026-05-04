import 'package:flutter/material.dart';

class CourseNotifier extends ChangeNotifier {
  static final CourseNotifier _instance = CourseNotifier._internal();
  factory CourseNotifier() => _instance;
  CourseNotifier._internal();

  void refreshDashboard() {
    notifyListeners();
  }
}