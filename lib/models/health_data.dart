// lib/models/health_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthData {
  final String userId;
  final DateTime date;
  final int waterIntake; // в миллилитрах (мл)
  final double sleepHours; // в часах
  final int steps; // количество шагов
  final String mood; // 'happy', 'neutral', 'sad'
  final int caloriesBurned; // калории
  final double weight; // вес в кг (опционально)
  final int heartRate; // пульс (опционально)
  
  HealthData({
    required this.userId,
    required this.date,
    this.waterIntake = 0,
    this.sleepHours = 0.0,
    this.steps = 0,
    this.mood = 'neutral',
    this.caloriesBurned = 0,
    this.weight = 0.0,
    this.heartRate = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'waterIntake': waterIntake,
      'sleepHours': sleepHours,
      'steps': steps,
      'mood': mood,
      'caloriesBurned': caloriesBurned,
      'weight': weight,
      'heartRate': heartRate,
    };
  }

  factory HealthData.fromMap(Map<String, dynamic> map) {
    return HealthData(
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      waterIntake: map['waterIntake'] ?? 0,
      sleepHours: (map['sleepHours'] ?? 0.0).toDouble(),
      steps: map['steps'] ?? 0,
      mood: map['mood'] ?? 'neutral',
      caloriesBurned: map['caloriesBurned'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      heartRate: map['heartRate'] ?? 0,
    );
  }

  HealthData copyWith({
    String? userId,
    DateTime? date,
    int? waterIntake,
    double? sleepHours,
    int? steps,
    String? mood,
    int? caloriesBurned,
    double? weight,
    int? heartRate,
  }) {
    return HealthData(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepHours: sleepHours ?? this.sleepHours,
      steps: steps ?? this.steps,
      mood: mood ?? this.mood,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      weight: weight ?? this.weight,
      heartRate: heartRate ?? this.heartRate,
    );
  }
}

class HealthGoals {
  final String userId;
  final int dailyWaterGoal; // мл
  final double dailySleepGoal; // часы
  final int dailyStepsGoal; // шаги
  final int dailyCaloriesGoal; // калории

  HealthGoals({
    required this.userId,
    this.dailyWaterGoal = 2000, // по умолчанию 2 литра
    this.dailySleepGoal = 8.0, // по умолчанию 8 часов
    this.dailyStepsGoal = 10000, // по умолчанию 10к шагов
    this.dailyCaloriesGoal = 2000,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dailyWaterGoal': dailyWaterGoal,
      'dailySleepGoal': dailySleepGoal,
      'dailyStepsGoal': dailyStepsGoal,
      'dailyCaloriesGoal': dailyCaloriesGoal,
    };
  }

  factory HealthGoals.fromMap(Map<String, dynamic> map) {
    return HealthGoals(
      userId: map['userId'] ?? '',
      dailyWaterGoal: map['dailyWaterGoal'] ?? 2000,
      dailySleepGoal: (map['dailySleepGoal'] ?? 8.0).toDouble(),
      dailyStepsGoal: map['dailyStepsGoal'] ?? 10000,
      dailyCaloriesGoal: map['dailyCaloriesGoal'] ?? 2000,
    );
  }
}