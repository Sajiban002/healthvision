import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/health_data.dart';
import '../utils/constants.dart';

class HealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<HealthData?> getHealthDataForDate(String userId, DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final startOfDay = normalizedDate;
    final endOfDay = DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, 23, 59, 59);

    try {
      final snapshot = await _firestore
          .collection(AppConstants.healthDataCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return HealthData.fromMap(snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveHealthData(HealthData data) async {
    try {
      final normalizedDate = _normalizeDate(data.date);
      final dataToSave = data.copyWith(date: normalizedDate);
      
      final startOfDay = normalizedDate;
      final endOfDay = DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, 23, 59, 59);

      final docQuery = await _firestore
          .collection(AppConstants.healthDataCollection)
          .where('userId', isEqualTo: dataToSave.userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (docQuery.docs.isEmpty) {
        await _firestore.collection(AppConstants.healthDataCollection).add(dataToSave.toMap());
      } else {
        await docQuery.docs.first.reference.update(dataToSave.toMap());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSpecificData({
    required String userId,
    required DateTime date,
    int? waterIntake,
    double? sleepHours,
    int? steps,
    String? mood,
    int? caloriesBurned,
    double? weight,
    int? heartRate,
  }) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final existingData = await getHealthDataForDate(userId, normalizedDate);
      
      HealthData updatedData;
      if (existingData != null) {
        updatedData = existingData.copyWith(
          waterIntake: waterIntake,
          sleepHours: sleepHours,
          steps: steps,
          mood: mood,
          caloriesBurned: caloriesBurned,
          weight: weight,
          heartRate: heartRate,
        );
      } else {
        updatedData = HealthData(
          userId: userId,
          date: normalizedDate,
          waterIntake: waterIntake ?? 0,
          sleepHours: sleepHours ?? 0.0,
          steps: steps ?? 0,
          mood: mood ?? 'neutral',
          caloriesBurned: caloriesBurned ?? 0,
          weight: weight ?? 0.0,
          heartRate: heartRate ?? 0,
        );
      }

      return await saveHealthData(updatedData);
    } catch (e) {
      return false;
    }
  }

  Future<HealthGoals?> getUserGoals(String userId) async {
    try {
      final doc = await _firestore
          .collection('health_goals')
          .doc(userId)
          .get();

      if (!doc.exists) {
        final defaultGoals = HealthGoals(userId: userId);
        await _firestore
            .collection('health_goals')
            .doc(userId)
            .set(defaultGoals.toMap());
        return defaultGoals;
      }

      return HealthGoals.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserGoals(HealthGoals goals) async {
    try {
      await _firestore
          .collection('health_goals')
          .doc(goals.userId)
          .set(goals.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getWeeklyStats(String userId, DateTime date) async {
    try {
      final normalizedDate = _normalizeDate(date);
      final startOfWeek = normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final data = await getHealthDataForPeriod(userId, startOfWeek, endOfWeek);
      if (data.isEmpty) return {};

      return _calculateStats(data);
    } catch (e) {
      return {};
    }
  }

  Future<List<HealthData>> getHealthDataForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = _normalizeDate(startDate);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    try {
      final snapshot = await _firestore
          .collection(AppConstants.healthDataCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) => HealthData.fromMap(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _calculateStats(List<HealthData> data) {
    int totalSteps = data.map((d) => d.steps).fold(0, (a, b) => a + b);
    int totalWater = data.map((d) => d.waterIntake).fold(0, (a, b) => a + b);
    double totalSleep = data.map((d) => d.sleepHours).fold(0.0, (a, b) => a + b);
    
    return {
      'totalSteps': totalSteps,
      'averageSteps': data.isNotEmpty ? (totalSteps / data.length).round() : 0,
      'totalWater': totalWater,
      'averageWater': data.isNotEmpty ? (totalWater / data.length).round() : 0,
      'totalSleep': totalSleep,
      'averageSleep': data.isNotEmpty ? totalSleep / data.length : 0.0,
    };
  }

  Future<int> calculateHealthScore(String userId, DateTime date) async {
    try {
      final goals = await getUserGoals(userId);
      if (goals == null) return 0;
      
      final normalizedDate = _normalizeDate(date);
      final data = await getHealthDataForDate(userId, normalizedDate);
      if (data == null) return 0;

      int waterScore = ((data.waterIntake / goals.dailyWaterGoal) * 25).clamp(0, 25).round();
      int sleepScore = ((data.sleepHours / goals.dailySleepGoal) * 25).clamp(0, 25).round();
      int stepsScore = ((data.steps / goals.dailyStepsGoal) * 25).clamp(0, 25).round();
      
      int moodScore = 0;
      switch (data.mood) {
        case 'happy': moodScore = 25; break;
        case 'neutral': moodScore = 15; break;
        case 'sad': moodScore = 5; break;
      }

      return waterScore + sleepScore + stepsScore + moodScore;
    } catch (e) {
      return 0;
    }
  }
}