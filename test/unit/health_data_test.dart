// test/unit/health_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/health_data.dart';

void main() {
  final testDate = DateTime(2024, 6, 15);
  test('HealthData создаётся с корректными дефолтными значениями', () {
    final data = HealthData(userId: 'u1', date: testDate);
    expect(data.waterIntake, equals(0));
    expect(data.sleepHours, equals(0.0));
    expect(data.steps, equals(0));
    expect(data.mood, equals('neutral'));
    expect(data.caloriesBurned, equals(0));
  });
  test('HealthData toMap и fromMap сохраняют все поля корректно', () {
    final original = HealthData(
      userId: 'u1',
      date: testDate,
      waterIntake: 1500,
      sleepHours: 7.5,
      steps: 8000,
      mood: 'happy',
      caloriesBurned: 400,
      weight: 75.5,
      heartRate: 72,
    );
    final restored = HealthData.fromMap(original.toMap());
    expect(restored.userId, equals(original.userId));
    expect(restored.waterIntake, equals(original.waterIntake));
    expect(restored.sleepHours, equals(original.sleepHours));
    expect(restored.steps, equals(original.steps));
    expect(restored.mood, equals(original.mood));
    expect(restored.weight, equals(original.weight));
    expect(restored.heartRate, equals(original.heartRate));
  });
  test('copyWith меняет только указанные поля', () {
    final original = HealthData(
      userId: 'u1',
      date: testDate,
      waterIntake: 1000,
      steps: 5000,
      mood: 'neutral',
    );
    final updated = original.copyWith(waterIntake: 2000);
    expect(updated.waterIntake, equals(2000));
    expect(updated.steps, equals(5000));
    expect(updated.mood, equals('neutral'));
    expect(updated.userId, equals('u1'));
  });
  test('HealthGoals создаётся с правильными дефолтными целями', () {
    final goals = HealthGoals(userId: 'u1');
    expect(goals.dailyWaterGoal, equals(2000));
    expect(goals.dailySleepGoal, equals(8.0));
    expect(goals.dailyStepsGoal, equals(10000));
    expect(goals.dailyCaloriesGoal, equals(2000));
  });
}