import 'package:flutter/foundation.dart';
import '../models/health_data.dart';
import '../services/health_service.dart';

class HealthProvider with ChangeNotifier {
  final HealthService _healthService = HealthService();
  
  HealthData? _currentData;
  HealthGoals? _currentGoals;
  int _healthScore = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _monthlyStats;

  HealthData? get currentData => _currentData;
  HealthGoals? get currentGoals => _currentGoals;
  int get healthScore => _healthScore;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get weeklyStats => _weeklyStats;
  Map<String, dynamic>? get monthlyStats => _monthlyStats;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> loadDataForDate(String userId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_currentGoals == null) {
        _currentGoals = await _healthService.getUserGoals(userId);
      }

      final existingData = await _healthService.getHealthDataForDate(userId, normalizedDate);
      
      if (existingData == null) {
        _currentData = HealthData(userId: userId, date: normalizedDate);
        await _healthService.saveHealthData(_currentData!);
      } else {
        _currentData = existingData;
      }

      _healthScore = await _healthService.calculateHealthScore(userId, normalizedDate);
      await loadWeeklyStats(userId, normalizedDate);

    } catch (e) {
      _errorMessage = 'Ошибка загрузки данных: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeUserData(String userId, DateTime date) async {
    await loadDataForDate(userId, date);
  }

  Future<void> saveAllData({
    required String userId,
    required DateTime date,
    required int waterIntake,
    required double sleepHours,
    required int steps,
  }) async {
    final normalizedDate = _normalizeDate(date);
    
    try {
      final dataToSave = HealthData(
        userId: userId,
        date: normalizedDate,
        waterIntake: waterIntake,
        sleepHours: sleepHours,
        steps: steps,
      );

      final success = await _healthService.saveHealthData(dataToSave);
      
      if (success) {
        if (_normalizeDate(_currentData?.date ?? DateTime(0)) == normalizedDate) {
          _currentData = dataToSave;
          await _updateHealthScore(userId, normalizedDate);
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Ошибка сохранения всех данных: $e';
      notifyListeners();
    }
  }

  Future<void> updateGoals(HealthGoals goals, DateTime date) async {
    try {
      final success = await _healthService.updateUserGoals(goals);
      if (success) {
        _currentGoals = goals;
        await _updateHealthScore(goals.userId, date);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Ошибка обновления целей: $e';
      notifyListeners();
    }
  }

  Future<void> loadWeeklyStats(String userId, DateTime date) async {
    try {
      _weeklyStats = await _healthService.getWeeklyStats(userId, date);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка загрузки статистики: $e';
      notifyListeners();
    }
  }

  Future<void> _updateHealthScore(String userId, DateTime date) async {
    try {
      final normalizedDate = _normalizeDate(date);
      _healthScore = await _healthService.calculateHealthScore(userId, normalizedDate);
    } catch (e) {
      print('Ошибка обновления балла: $e');
    }
  }

  Future<List<HealthData>> getWeekData(String userId, DateTime weekStart) async {
    try {
      final normalizedWeekStart = _normalizeDate(weekStart);
      final weekEnd = normalizedWeekStart.add(const Duration(days: 6));
      return await _healthService.getHealthDataForPeriod(userId, normalizedWeekStart, weekEnd);
    } catch (e) {
      return [];
    }
  }

  double get waterProgress {
    if (_currentData == null || _currentGoals == null || _currentGoals!.dailyWaterGoal == 0) return 0.0;
    final progress = _currentData!.waterIntake / _currentGoals!.dailyWaterGoal;
    return progress.clamp(0.0, 1.0);
  }

  double get sleepProgress {
    if (_currentData == null || _currentGoals == null || _currentGoals!.dailySleepGoal == 0) return 0.0;
    final progress = _currentData!.sleepHours / _currentGoals!.dailySleepGoal;
    return progress.clamp(0.0, 1.0);
  }

  double get stepsProgress {
    if (_currentData == null || _currentGoals == null || _currentGoals!.dailyStepsGoal == 0) return 0.0;
    final progress = _currentData!.steps / _currentGoals!.dailyStepsGoal;
    return progress.clamp(0.0, 1.0);
  }
}