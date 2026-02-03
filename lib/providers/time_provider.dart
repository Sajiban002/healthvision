import 'package:flutter/foundation.dart';

class TimeProvider with ChangeNotifier {
  DateTime _currentDate = DateTime.now();
  final List<DateTime> _dateHistory = [];
  DateTime? _weekStart;

  DateTime get currentDate => _currentDate;
  bool get canGoBack => _dateHistory.isNotEmpty;
  DateTime? get weekStart => _weekStart;
  DateTime? get weekEnd => _weekStart != null ? _weekStart!.add(const Duration(days: 6)) : null;

  TimeProvider() {
    _initializeWeekStart();
  }

  void _initializeWeekStart() {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final weekday = normalizedNow.weekday;
    _weekStart = normalizedNow.subtract(Duration(days: weekday - 1));
    _weekStart = DateTime(_weekStart!.year, _weekStart!.month, _weekStart!.day);
  }

  void _updateWeekStart() {
    if (_weekStart == null) {
      _initializeWeekStart();
      return;
    }

    final normalizedCurrent = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final weekday = normalizedCurrent.weekday;
    final currentWeekStart = normalizedCurrent.subtract(Duration(days: weekday - 1));
    final currentWeekStartNormalized = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    
    if (!_isSameDay(currentWeekStartNormalized, _weekStart!)) {
      _weekStart = currentWeekStartNormalized;
    }
  }

  void nextDay() {
    _dateHistory.add(_currentDate);
    _currentDate = _currentDate.add(const Duration(days: 1));
    _updateWeekStart();
    notifyListeners();
  }

  void goBack() {
    if (_dateHistory.isNotEmpty) {
      final previousDate = _dateHistory.removeLast();
      _currentDate = previousDate;
      _updateWeekStart();
      notifyListeners();
    }
  }

  void resetToToday() {
    _currentDate = DateTime.now();
    _dateHistory.clear();
    _initializeWeekStart();
    notifyListeners();
  }

  int getDaysInCurrentWeek() {
    if (_weekStart == null) return 0;
    final normalizedCurrent = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final daysSinceWeekStart = normalizedCurrent.difference(_weekStart!).inDays;
    return (daysSinceWeekStart + 1).clamp(0, 7);
  }

  bool isNewWeek(DateTime previousDate) {
    if (_weekStart == null) return false;
    final normalizedPrev = DateTime(previousDate.year, previousDate.month, previousDate.day);
    final prevWeekday = normalizedPrev.weekday;
    final prevWeekStart = normalizedPrev.subtract(Duration(days: prevWeekday - 1));
    return !_isSameDay(prevWeekStart, _weekStart!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}