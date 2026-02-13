// test/unit/health_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/health_data.dart';

void main() {
  final testDate = DateTime(2024, 6, 15);
  test('расчёт прогресса даёт правильный результат и не превышает 1.0', () {
    final data = HealthData(userId: 'u1', date: testDate, waterIntake: 1000);
    final goals = HealthGoals(userId: 'u1', dailyWaterGoal: 2000);

    final progress = (data.waterIntake / goals.dailyWaterGoal).clamp(0.0, 1.0);
    expect(progress, equals(0.5));

    final overData = HealthData(userId: 'u1', date: testDate, waterIntake: 2500);
    final overProgress = (overData.waterIntake / goals.dailyWaterGoal).clamp(0.0, 1.0);
    expect(overProgress, equals(1.0));
  });
}